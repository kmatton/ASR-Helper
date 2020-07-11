import os
import string
import math
import re

from process_text_util import remove_nv_exps, process_non_ascii, process_numbers, map_words


"""
Classes for processing transcriptions so that notation is in standard/expected format.
TODO: check if times are handled properly with this + check MS examples to make sure you've converted them properly
TODO: implement text processor for aligning transcriptions with that produced by Kaldi ASR model trained on Fisher English corpus
"""


class MicrosoftTextProcessor:

    WORD_MAPPINGS = {
        'at&t': 'a t and t',
        'ocd': 'o c d',
        'tv': 't v',
        't v': 't v',
        'dr.': 'doctor',
        'facebook': 'face book',
        'paypal': 'pay pal',
        'abcde': '',
        'abcd': '',
        'doin': 'doing',
        'somethin': 'something',
        'fuckin': 'fucking',
        'mmm': 'mm',
        'mg': 'micrograms',
        'uhm': 'um',
        'cuz': "'cause"
    }

    def process_transcribed_text(self, text):
        """
        Process audio file transcription (text) to convert it to format expected by Microsoft Speech Services.
        See here for details on expected format: 
        https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/how-to-custom-speech-human-labeled-transcriptions
        :param text: transcription of audio file or segment of audio file
        :return: processed_text: segment transcription that has been standardized
        """

        # make lower case
        text = text.lower()
        # no more processing needed if only contains alphabet characteris
        if text.isalpha():
            return text

        # remove all tags indicating non-verbal expressions
        # here it's expected that non-verbal expressions were listed as [expression] or <expression>
        # e.g. <laughter>, [cough]
        text = remove_nv_exps('<', '>', text)
        text = remove_nv_exps('[', ']', text)

        text = process_non_ascii(text)
        text = process_numbers(text)
        text = map_words(text, self.WORD_MAPPINGS)

        # remove double spaces
        text = re.sub(' +', ' ', text)
        # remove apostrophes that are not attached to words (i.e. are on their own)
        text = re.sub(" ' ", ' ', text)
        return text
