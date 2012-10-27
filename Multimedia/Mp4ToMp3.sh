#!/bin/bash
#
# EDWARDS RESEARCH
# www.edwards-research.com
#
# This converts the audio from .mp4 files that include video (e.g. youtube.com streams) to
# .mp3 files.
#
 
# If file exists, set $FILE
#   I know this is a sloppy way to handle command line arguments -- I'm ok with that.  (I
#   was going to provide for options, blah blah...)
if [[ -e ${1} ]] ; then
    FILE=${1}
fi
 
# Ensure input file exits
if [[ -z $FILE ]] ; then
    echo "File not found -- exiting."
    exit
fi
 
# Extract Filename
base=$(basename "${FILE}" .mp4)
 
# Dump audio from .mp4 to .wav with mplayer
#   So, it looks as if it doesn't make a difference in terms of the output (at least from
#   my small test group) whether you pick pcm:waveheader or pcm:fast. pcm:waveheader takes
#   more than twice as long to convert but pcm:fast complains.  I'm going to leave it at
#   waveheader because I'm not in a rush and I'd rather not have the warnings.  Feel free
#   to change this to pcm:fast and experiment.
#       -ao pcm:waveheader -> 59 seconds, 4625553 byte .mp3
#       -ao pcm:fast       -> 22 seconds, 4625553 byte .mp3
#
#   mplayer  -vc null -vo null -nocorrect-pts -ao pcm:fast "${FILE}"
#
mplayer -vc null -vo null -nocorrect-pts -ao pcm:waveheader "${FILE}"
RV=$?
if [[ $RV != 0 ]] ; then
    echo "mplayer completed unsuccessfully -- exiting."
    exit
fi
 
# Convert .wav to .mp3
lame -h -b 192 audiodump.wav "${base}.mp3" ${VERB}
RV=$?
if [[ $RV != 0 ]] ; then
    echo "lame completed unsuccessfully -- exiting."
    exit
fi
 
# Cleanup Temporary File
rm audiodump.wav
 
echo "Conversion complete."