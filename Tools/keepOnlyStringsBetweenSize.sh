#!/bin/bash
   
if [ $# -ne 3 ]
then 
 echo "Usage: `basename $0` StringMinLength StringMaxLength outFile < inputFile"
 echo "i.e  `basename $0` 4 7 outFile.txt < inputFile"
 exit 1
fi

while read line  # For as many lines as the input file has ...
do
  #echo "$line"   # Output the line itself.

  len="${#line}"
  if (( len > $1 && len < $2 )) 
    then  
      echo "$line" >> "$3"
  fi      
done


exit 0
