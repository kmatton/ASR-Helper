import azure.cognitiveservices.speech as speechsdk


def get_transcript(local_file_path, service_region='northcentralus'):
    speech_config = speechsdk.SpeechConfig(subscription=ASR_subscription_key, region=service_region)
    speech_config.set_service_property(name='format', value='detailed', channel=speechsdk.ServicePropertyChannel.UriQueryParameter)

    audio_config = speechsdk.audio.AudioConfig(filename=local_file_path)
    speech_recognizer = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)
    result = speech_recognizer.recognize_once()

    if result.reason == speechsdk.ResultReason.RecognizedSpeech:
        transcript = result.text
        confidence = json.loads(list(result.properties.values())[0])['NBest'][0]['Confidence']
        # print('Recognized: ', transcript, confidence, type(transcript), type(confidence))

    elif result.reason == speechsdk.ResultReason.NoMatch:
        print('No speech could be recognized: {}'.format(result.no_match_details))
        transcript, confidence = '', 0

    elif result.reason == speechsdk.ResultReason.Canceled:
        cancellation_details = result.cancellation_details
        print('Speech Recognition canceled: {}'.format(cancellation_details.reason))
        if cancellation_details.reason == speechsdk.CancellationReason.Error:
            print('Error details: {}'.format(cancellation_details.error_details))
        assert False
    return transcript, confidence