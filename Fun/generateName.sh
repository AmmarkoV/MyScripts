#!/bin/bash

WORDS="`cat cliche`"
FIRST="`pick $WORDS`" 
SECOND="`pick $WORDS`"
if [ $FIRST=$SECOND ];
        then
           while [ "$FIRST" = "$SECOND" ];  
           do 
           SECOND="`pick $WORDS`"
           done 
        fi 
echo "$FIRST $SECOND"

exit 0
