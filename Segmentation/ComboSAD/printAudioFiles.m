
addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');

outfilename = '/nfs/turbo/McInnisLab/Katie/assess_audio_segments/filelist.txt';
outfileid = fopen(outfilename, 'w+');
disp(outfileid);
filelist = dir('/nfs/turbo/McInnisLab/Katie/assessment_audio_copy');
numfiles = size(filelist, 1);
sec_size = ceil(numfiles/10);
for job_num = 0:9
    start_idx = sec_size * job_num + 1;
    end_idx = start_idx + sec_size - 1;
    if start_idx < 4
        start_idx = 4
    end
    if end_idx > numfiles
        end_idx = numfiles
    end
    for i = start_idx:end_idx
        call_num = filelist(i).name(1:end-4);
        fspec = '%s\t%d\n';
        fprintf(outfileid, fspec, call_num, job_num);
    end
end
