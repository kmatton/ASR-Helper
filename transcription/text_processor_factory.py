from process_text import MicrosoftTextProcessor

"""
Get text processor by processor name.
"""

def get_text_processor(processor_name):
    if processor_name == "Microsoft":
        return MicrosoftTextProcessor()
    else:
        print("Invalid text processor of type {} specified. Exiting....".format(processor_name))
        exit(1)
    