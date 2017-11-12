#!/bin/bash
say() 
{ local IFS=+;/usr/bin/mplayer -ao alsa -really-quiet -noconsolecontrols "http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=$1&tl=$2"; }
say $1 $2

