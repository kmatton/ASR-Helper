
function getAudioSegs(job_num)

addpath('/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Support', '/nfs/turbo/McInnisLab/Katie/data_processing_scripts/segment_extraction/Packages/Segments', '/nfs/turbo/McInnisLab/Libraries/voicebox');

disp(job_num);

filelist = dir('/nfs/turbo/McInnisLab/Katie/assessment_audio_copy');

disp(filelist(10).name);

disp(filelist(20).name);

exit;
