import os
import string
import math
import re
import inflect
p = inflect.engine()

FISHER_VOCAB_FILE = "/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/exp/tri5a/graph/words.txt"
CMU_VOCAB_FILE = "/nfs/turbo/McInnisLab/Katie/kaldi-5.2/egs/fisher_english/s5/data_original/local/dict/lexicon1_raw_nosil.txt"


FISHER_MAPPINGS = {
    'at&t': 'a._t._t.',
    'ocd': 'o._c._d.',
    'tv': 't._v.',
    't v': 't._v.',
    'facebook': 'face book',
    'paypal': 'pay pal',
    'sorta': 'sort of',
    'hyperventilating': 'hyper ventilating',
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


def has_numbers(input_string):
    return any(char.isdigit() for char in input_string)


def remove_nv_exps(left_char, right_char, text):
    """
    Remove all substrings from text that of form left_char (some text) right_char
    e.g. left_char = <, right_char = > : remove <laughter>, <cough>, etc.
    Return text with these substrings (generally non-verbal expressions) removed.
    """
    nv_exp = re.compile('\{}(.*?)\{}'.format(left_char, right_char))
    insts = re.findall(nv_exp, text)
    for inst in insts:
        text = str.replace(text, "{}{}{}".format(left_char, inst, right_char), '')
    return text


def process_subwords(index, sub_words, words):
    """
    Insert subwords into words list starting at index.
    Return number of new words added (number of subwords - 1) to word list.
    """
    words[index] = sub_words[0]
    j = index + 1
    for sub_word in sub_words[1:]:
        words.insert(j, sub_word)
        j += 1
    return len(sub_words) - 1


class TextProcessor:
    def __init__(self):
        self.load_fisher_vocab()
        self.load_cmu_vocab()
    
    def load_fisher_vocab(self):
        self.fisher_vocab = set()
        with open(FISHER_VOCAB_FILE, 'r') as f:
            for line in f:
                line = line.split(" ")[0]
                self.fisher_vocab.add(line)

    def load_cmu_vocab(self):
        self.cmu_vocab = set()
        with open(CMU_VOCAB_FILE, 'r') as f:
            for line in f:
                line = line.split(" ")[0]
                self.cmu_vocab.add(line)

    def analyze_oov(self, texts):
        ''' texts is a list of strings, each of which is a transcription of a single segment '''
        oov_fisher_dict = {}
        oov_cmu_dict = {}
        tag_clean = re.compile('<(.*?)>')
        for text in texts:
            if not isinstance(text, str):
                continue
            
            text = self.process_transcribed_text(text, False, False)
            words = text.split(" ")
            for word in words:
                if word not in self.fisher_vocab:
                    if word not in oov_fisher_dict:
                        oov_fisher_dict[word] = 0
                    oov_fisher_dict[word] += 1
                if word not in self.cmu_vocab:
                    if word not in oov_cmu_dict:
                        oov_cmu_dict[word] = 0
                    oov_cmu_dict[word] += 1

        # report CMU OOV
        print("OOV for CMU lexicon")
        sorted_cmu = sorted(oov_cmu_dict.items(), key=lambda kv: kv[1], reverse=True)
        print("total OOV CMU {}".format(len(sorted_cmu)))
        for word, count in sorted_cmu:
            if count >= 10:
                print("{} {}".format(word, count))
        print("OOV for Fisher lexicon")
        sorted_fisher = sorted(oov_fisher_dict.items(), key=lambda kv: kv[1], reverse=True)
        print("total OOV fisher {}".format(len(sorted_fisher)))
        for word, count in sorted_fisher:
            if count >= 10:
                print("{} {}".format(word, count))

    def process_transcribed_text(self, text):
        """
        Process speech segment transcription (text) to convert it to a standard format for WER computation.
        :param text: transcription of speech segment
        :return: processed_text: segment transcription that has been standardized
        """
        if not isinstance(text, str):
            print("not string: {}".format(text))
            return text

        # make lower case
        text = text.lower()
        # no more processing needed if only contains alphabet characteris
        if text.isalpha():
            return text

        # remove all tags indicating non-verbal expressions
        text = remove_nv_exps('<', '>', text)
        text = remove_nv_exps('[', ']', text)

        # remove punctuation
        text = re.sub('[;\(\)\?\[\]\!\\\\"]', '', text)
        text = re.sub('[\/\-:]', ' ', text)
        text = str.replace(text, '+', " plus")
        text = str.replace(text, '%', " percent")
        text = str.replace(text, '.com', " dot com")
        text = str.replace(text, ".net", " dot net")
        text = str.replace(text, ".org", " dot org")
        text = str.replace(text, u'\u2019', "'")

        # word-level processing
        words = text.split(" ")
        num_words = len(words)
        i = 0
        while i < num_words:
            word = words[i]
            if not word:
                del words[i]
                num_words -= 1
                continue
            if word[0] == "$":
                words[i] = word[1:]
                words.insert(i+1, "dollars")
                num_words += 1
                continue
            if has_numbers(word):
                if word[-1] == '.':
                    word = word[:-1]
                word = p.number_to_words(word)
                word = str.replace(word, '-', " ")
                word = str.replace(word, ',', "")
                sub_words = word.split(" ")
                if len(sub_words) > 1:
                    num_words += process_subwords(i, word.split(" "), words)
                    continue
            word = str.replace(word, '.', " ")
            if word in FISHER_MAPPINGS.keys():
                word = FISHER_MAPPINGS[word]
            sub_words = word.split(" ")
            if len(sub_words) > 1:
                num_words += process_subwords(i, word.split(" "), words)
                continue
            if word == "'" or not word:
                del words[i]
                num_words -= 1
                continue
            words[i] = word
            i += 1

        # further processing of text
        text = " ".join(words)
        # remove commas
        text = text.replace(',', '')
        # remove double spaces
        text = re.sub(' +', ' ', text)

        # now check for words not in Fisher Vocab and try to see if it's due to spelling error/discrepancy
        words = text.split(" ")
        num_words = len(words)
        i = 0
        while i < num_words:
            if words[i] not in self.fisher_vocab and len(words[i]) >= 2:
                if words[i][-2:] == "'s":
                    # may be transcription error, attempt to fix
                    try_word = words[i][:-2] + "s"
                    if try_word in self.fisher_vocab or try_word in self.cmu_vocab:
                        words[i] = try_word
                elif words[i][-2:] == "n'":
                    try_word = words[i][:-1] + "g"
                    if try_word in self.fisher_vocab or try_word in self.cmu_vocab:
                        words[i] = try_word
            if words[i] not in self.fisher_vocab and "'" in words[i]:
                try_word = str.replace(words[i], "'", "")
                if try_word in self.fisher_vocab or try_word in self.cmu_vocab:
                    words[i] = try_word
            if words[i] == " " or not words[i]:
                del words[i]
                num_words -= 1
                continue
            i += 1
        return text

    def process_kaldi_asr_text(self, text):
        text = str.replace(text, "[laughter]", '')
        text = str.replace(text, "[noise]", '')
        text = re.sub(' +', ' ', text)
        return text
