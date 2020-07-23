import sys
from datetime import  datetime

"""
Utility functions to support working with Microsoft Speech Services
"""


def read_map_file_by_lines(filename):
    """
    Read a file with two columns separated by a single space into a list of tuples
    """
    with open(filename, "r") as f:
        lines = f.read().splitlines()
        lines = [l.split(" ") for l in lines]
        return lines


class Logger:
    """
    Class for logging script errors
    """
    def __init__(self, stream=sys.stderr):
        self.stream = stream
    
    def __call__(self, msg):
        print('[{}] {}'.format(datetime.now(), msg), file=self.stream)
