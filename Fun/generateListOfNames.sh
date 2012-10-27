#!/bin/bash

echo " " > ListOfNames
END=10000
for i in `seq 1 $END`;
do 
./generateName.sh >> ListOfNames
done
exit 0
