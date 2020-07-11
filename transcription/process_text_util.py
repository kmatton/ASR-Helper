import re
import string

import inflect
p = inflect.engine()
from IPython import embed

"""
Utility functions to support text processing that occurs as part of transcript standardization.
"""


def remove_nv_exps(left_char, right_char, text):
    """
    Remove all substrings from text that of form left_char (some text) right_char
    e.g. left_char = <, right_char = > : remove <laughter>, <cough>, etc.
    Return text with these substrings (which generally non-verbal expressions) removed.
    """
    nv_exp = re.compile('\{}(.*?)\{}'.format(left_char, right_char))
    insts = re.findall(nv_exp, text)
    for inst in insts:
        text = str.replace(text, "{}{}{}".format(left_char, inst, right_char), '')
    return text


def remove_punctuation(text):
    """
    Remove the following puncutation marks: semi-colon, parantheses, question mark, brackets, exclaimation mark,
    backslash, quotes, hyphens, colons, plus signs, and percents. Dollar signs and some periods are processed separately,
    as the processing required in their removal is more complex and needs to be handled at the word-level. Apostrophes are not removed.
    """
    text = re.sub('[;\(\)\?\[\]\!\\\\"]', '', text)
    text = re.sub('[\/\-:]', ' ', text)
    text = str.replace(text, '+', " plus")
    text = str.replace(text, '%', " percent")
    text = str.replace(text, '.com', " dot com")
    text = str.replace(text, ".net", " dot net")
    text = str.replace(text, ".org", " dot org")
    return text


def process_numbers(text):
    """
    Process text by word to convert words that contain numbers (e.g. prices, decimals, etc.)
    to their corresponding written out format.
    """
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
        words[i] = word
        i += 1
    text = " ".join(words)
    return text


def map_words(text, word_map):
    """
    Map words to their replacements given in word_map dict.
    """
    words = text.split(" ")
    num_words = len(words)
    i = 0
    while i < num_words:
        if word in word_map.keys():
            word = word_map[word]
        sub_words = word.split(" ")
        if len(sub_words) > 1:
            num_words += process_subwords(i, word.split(" "), words)
            continue
        if not word:
            del words[i]
            num_words -= 1
            continue
        words[i] = word
        i += 1
    text = " ".join(words)
    return text


def process_non_ascii(text):
    """
    Check for non ASCII characters and replace with corresponding ASCII character or remove.
    """
    # first replace unicode apostrophes with ascii apostrophe symbol
    text = str.replace(text, u'\u2019', "'")
    if text.isascii():
        return text
    print("Not an ascii-encoded string")
    embed()


def has_numbers(input_string):
    return any(char.isdigit() for char in input_string)


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
