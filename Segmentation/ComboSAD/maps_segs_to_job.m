
addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');
filelist = dir('/nfs/turbo/McInnisLab/Katie/assessment_audio_copy');
numfiles = size(filelist, 1);
outfileid = fopen('/nfs/turbo/McInnisLab/Katie/assessment_audio_metadata/matlab_seg_check.txt', 'w+');
for i = 3:5
    formatSpec = '%s\t0\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 6:38
    formatSpec = '%s\t1\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 39:133
    formatSpec = '%s\t1b\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 134:261
    formatSpec = '%s\t2\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 262:389
    formatSpec = '%s\t3\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 390:422
    formatSpec = '%s\t4\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 423:517
    formatSpec = '%s\t4b\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 518:550
    formatSpec = '%s\t5\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 551:645
    formatSpec = '%s\t5b\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 646:678
    formatSpec = '%s\t6\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 679:773
    formatSpec = '%s\t6b\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 774:806
    formatSpec = '%s\t7\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 807:901
    formatSpec = '%s\t7b\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 902:934
    formatSpec = '%s\t8\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 935:1029
    formatSpec = '%s\t8b\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 1030:1157
    formatSpec = '%s\t9\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 1158:1190
    formatSpec = '%s\t10\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 1191:1285
    formatSpec = '%s\t10b\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
for i = 1286:1280
    formatSpec = '%s\t11\n';
    fprintf(outfileid, formatSpec, filelist(i).name);
end
fclose(outfileid);
