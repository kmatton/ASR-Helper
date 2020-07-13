"""
Script to break up single PRIORI emotion transcript file in to files for each subject, data type (i.e. personal or assessment) pair.
"""

with open('trans.txt', 'r') as in_f:
    for line in in_f:
        file_path = line.split(' ')[0]
        exp_type_name, subject = file_path.split('/')[-4:-2]
        exp_type = exp_type_name.split("_")[1]
        # open file for this subject and experiment type
        with open(f'trans_files_by_sub_exp/{subject}_{exp_type}.txt', 'a+') as out_f:
            out_f.write(line)
