#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cat $1 | grep -o alt=\".*.\" | cut -d ' ' -f 1,2 > $DIR/youtube

cd "$DIR"


cat youtube | sort | uniq > youtubeS
cat youtubeS | grep -v alt=\"\" > youtube


cat facebook instagram youtube > winners.txt

sed -i 's/alt=\"//g' winners.txt
sed -i 's/\"//g' winners.txt


sed -i 's/Elina Paflioti//g' winners.txt
sed -i 's/Acute Biologist//g' winners.txt
sed '/^$/d' winners.txt > winnersFinal.txt.

WINNER=`sort --random-sort winnersFinal.txt | head -n 1`



aplay drum.wav
echo "And the winner is $WINNER"
aplay win.wav&
 echo "And the winner is $WINNER" | festival --tts
 sleep 2
 echo "And the winner is $WINNER" | festival --tts
 sleep 2
 echo "And the winner is $WINNER" | festival --tts
 
echo "And the winner is $WINNER"


exit 0
