# ASR-Helper
Helper scripts for using common ASR systems (e.g. Kaldi, Microsoft) on your own speech data.

The directories included are:
* **asr-models-support**: scripts for helping with training and running different ASR models (Microsoft + Kaldi).
* **transcript_normalization**: scripts for normalizing the notation of transcripts (human generated or ASR) to use for training ASR models
  or computing ASR performance. This involves things like handling punctuation, abbreviations, the inclusion of non-verbal expressions, etc so that
  notation of human-generated transcript is consistent with that produced by different ASR models.
* **evaluation**: scripts for computing the word error rate (WER) of transcripts produced by an ASR model.
  
## TO-DOS
* Kaldi: extracting word + phone timing, getting confidence scores
* Transcription model specific to Kaldi model trained on Fisher English
* Documentation of WERs on PRIORI emotion
