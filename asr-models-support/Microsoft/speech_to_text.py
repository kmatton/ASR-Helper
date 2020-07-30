import argparse
import datetime
import json
import os
import sys
import time

import azure.cognitiveservices.speech as speechsdk
import pandas as pd
from IPython import embed

from util import read_map_file_by_lines, Logger


"""
Script for using Microsoft ASR model (either default model or your own custom model) to obtain transcripts from audio files.

Notes:
To get a an ASR subscription key, you first need to create a speech resource within the Microsoft Azure portal.
Then, select "Go to resource" and in the left navigation pane, select "Keys and Endpoint". You can use either of the two keys listed.

In the functions below, 'cb' stands for 'callback function'.
"""


def run_recognizer(audio_file_path, speech_subscription_key, service_region, log, custom_model_endpoint=None):
    """
    :param audio_file_path: path to audio file to run Microsoft speech recognizer on
    :param speech_subscription_key: your subscription key associated with a Microsoft Azure speech resource
    :param service_region: service region associated with the speech resource you provided the subscription key for
    :param log: function to use to log errors.
    :param custom_model_endpoint: (optional arg) if you want to use a custom model rather than the Microsoft's default model,
                                   provide the endpoint associated with your model here
    :return recognition_result_list: list of speech recognition results for the audio file
    """
    # set up configs
    speech_config = speechsdk.SpeechConfig(subscription=speech_subscription_key, region=service_region)
    if custom_model_endpoint is not None:
        speech_config.endpoint_id = custom_model_endpoint
    # see here for explanation of the 'format' and 'profanity' config settings
    # https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/rest-speech-to-text#query-parameters
    # format=detailed produces responses which contain multiple hypotheses + the confidence values of each
    # profanity=raw ensures that transcripts contain profanities, rather than having them masked out
    # see here for profanity option values https://docs.microsoft.com/en-us/dotnet/api/microsoft.cognitiveservices.speech.profanityoption?view=azure-dotnet#fields
    speech_config.set_service_property(name='format', value='detailed', channel=speechsdk.ServicePropertyChannel.UriQueryParameter)
    speech_config.request_word_level_timestamps()
    speech_config.set_profanity(profanity_option=speechsdk.ProfanityOption.Raw)
    audio_config = speechsdk.audio.AudioConfig(filename=audio_file_path)
    
    # intialize speech recognizer and set starting state to not done
    speech_recognizer = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)
    done = False

    # list to hold recognition results
    recognition_result_list = []

    def stop_cb(evt):
        log('CLOSING on {}'.format(evt))
        speech_recognizer.stop_continuous_recognition()
        nonlocal done
        done = True

    def recognized_cb(evt):
        if evt.result.reason == speechsdk.ResultReason.RecognizedSpeech:
            # get recognition details
            # provided properties are (will be stored in property_dict): 
            # --- DisplayText: transcript text with punctuation and capitalization (should be the same as evt.result.text)
            # --- Duration: The duration (in 100-nanosecond units) of the recognized speech in the audio stream.
            # --- Id: Id associated with recognition result
            # --- NBest: List of dicts storing information for the N best ASR hypotheses 
            #     (the first hypothesis is the same as evt.result.text). Each dict stores the following information:
            #      --- Confidence: model confidence associated with this hypothesis, ranges from 0 to 1
            #      --- Display: transcript text with punctuation and capitalization
            #      --- ITN: The inverse-text-normalized ("canonical") form of the recognized text, with phone numbers, numbers, 
            #               abbreviations ("doctor smith" to "dr smith"), and other transformations applied
            #      --- Lexical: The lexical form of the recognized text: the actual words recognized.
            #      --- MaskedITN: The ITN form with profanity masking applied, if requested.
            #      --- Words: List of words, where each word is givenas a dict with 'Duration', 'Offset', and 'Word' entries
            # -- Offset: The time (in 100-nanosecond units) at which the recognized speech begins in the audio stream.
            # -- RecognitionStatus: status of attempted recognition e.g. 'Success'
            property_dict = json.loads(list(evt.result.properties.values())[0])
            recognition_result_list.append(property_dict)
        elif evt.result.reason == speechsdk.ResultReason.NoMatch:
            log('NOMATCH for file {}: {}'.format(audio_file_path, evt))

    def canceled_cb(evt):
        if evt.result.reason == speechsdk.ResultReason.Canceled:
            cancellation_details = evt.result.cancellation_details
            log('Speech Recognition canceled for file {}. Reason: {}'.format(audio_file_path, cancellation_details.reason))
            if cancellation_details.reason == speechsdk.CancellationReason.Error:
                log('ERROR: cancellation error details: {}'.format(cancellation_details.error_details))

    # initialize event handlers for the speech recognizer
    # connnect callback functions to event signals
    speech_recognizer.recognizing.connect(lambda evt: log('RECOGNIZING: {}'.format(evt)))
    speech_recognizer.recognized.connect(lambda evt: log('RECOGNIZED: {}'.format(evt)))
    speech_recognizer.session_started.connect(lambda evt: log('SESSION STARTED: {}'.format(evt)))
    speech_recognizer.session_stopped.connect(lambda evt: log('SESSION STOPPED {}'.format(evt)))
    speech_recognizer.canceled.connect(lambda evt: log('CANCELED {}'.format(evt)))
    speech_recognizer.recognized.connect(recognized_cb)
    speech_recognizer.canceled.connect(canceled_cb)
    speech_recognizer.session_stopped.connect(stop_cb)
    speech_recognizer.canceled.connect(stop_cb)

    # start the recognition
    speech_recognizer.start_continuous_recognition()
    while not done:
        time.sleep(5)

    speech_recognizer.session_stopped.disconnect_all()
    speech_recognizer.canceled.disconnect_all()

    return recognition_result_list


def process_audio_files(audio_files, speech_subscription_key, log, args):
    # get results for each audio file
    raw_results = {}
    processed_results = []
    for file_id, file_path in audio_files:
        log("Starting recognizer for file {}".format(file_id))
        recognition_results = run_recognizer(file_path, speech_subscription_key, args.service_region, log, args.custom_model_endpoint)
        raw_results[file_id] = recognition_results
        # store each section of recognized audio (which somewhat correspond to segments) separately
        # for each text segment, store duration, offset, best display text, confidence, and word timing
        for idx, result in enumerate(recognition_results):
            # don't include if result is empty text
            if not result["DisplayText"]:
                continue
            result_dict = {}
            result_dict["audio_file_id"] = file_id
            result_dict["segment_number"] = idx
            result_dict["text"] = result["DisplayText"]
            result_dict["duration"] = result["Duration"]
            result_dict["offset"] = result["Offset"]
            best_hyp = result['NBest'][0]
            result_dict["confidence"] = best_hyp["Confidence"]
            result_dict["word_timing"] = best_hyp["Words"]
            result_dict["text_basic"] = best_hyp["Lexical"]  # text without capitalization or punctuation
            processed_results.append(result_dict)
    # write raw results to json file
    with open(os.path.join(args.output_dir, 'recognition_results.json'), 'w+') as f:
        json.dump(raw_results, f)
    # store processed results as csv file
    result_df = pd.DataFrame(processed_results)
    result_df.set_index(['audio_file_id', 'segment_number'], inplace=True)
    result_df.to_csv(os.path.join(args.output_dir, 'recognition_results.csv'))


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--audio_files', type=str, help="Path to text file containing ids and filepaths for each audio file you want to transcribe. "
                                                             "Each line should be of the form <id> <file_path> (where they are separated by a single space).")
    parser.add_argument('--output_dir', type=str, help="Path to directory to output speech recognition results to.")
    parser.add_argument('--service_region', type=str, default="northcentralus", help="Service region associated with the speech resource you are using.")
    parser.add_argument('--custom_model_endpoint', type=str, help="Endpoint associated with the speech recognition model you want to use. If not provided, "
                                                                  "will use Microsoft's default speech-to-text model.")
    parser.add_argument('--to_log', action='store_true', help="Set this option to write progress and errors to log file rather than stdout.")
    return parser.parse_args()


def main():
    args = parse_args()
    audio_files= read_map_file_by_lines(args.audio_files)
    
    # Retrieve ASR subscription key, which should be stored in an environment variable on the machine you're using.
    speech_subscription_key = os.getenv('SPEECH_SUBSCRIPTION_KEY')

    # if output_dir doesn't exist, create it
    if not os.path.exists(args.output_dir):
        os.makedirs(args.output_dir)
    
    # init logger
    stream = sys.stdout
    if args.to_log:
        stream = open(os.path.join(args.output_dir, "speech_recognition.log"), "w+")
    logger = Logger(stream)

    # run recognizer on files
    process_audio_files(audio_files, speech_subscription_key, logger, args)

    stream.close()
    

if __name__ == "__main__":
    main()
