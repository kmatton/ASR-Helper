import sys

"""
Script to create standard Kaldi text file / transcript from word ctm (time-marked conversation) file
"""

if len(sys.argv) !=3:
	print("<ctm file name> <output text file name>")
	exit()

ctm_file = sys.argv[1]
output_file = sys.argv[2]
utt_id_set = set()

with open(output_file, 'w+') as w:
	with open(ctm_file, 'r') as r:
		utt = []
		for line in r:
			line_arr = line.split()
			# Get last item (word)
			word = line_arr[-1]
			utt_id = line_arr[0]
			if utt_id not in utt_id_set:
				utt_id_set.add(utt_id)
				if utt:
					# This means finished collecting all words from single utterance
					# Write line to text
					utt_str = ' '.join(utt)
					w.write(utt_str+'\n')
					# reset utt
					utt = []
				# add new utt id to list
				utt.append(utt_id)
			utt.append(word)

		# write out last utterance
		utt_str = ' '.join(utt)
		w.write(utt_str+'\n')
