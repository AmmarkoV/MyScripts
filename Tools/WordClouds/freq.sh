tr '[:upper:]' '[:lower:]' < CVPR24titles.txt | tr -c '[:alnum:]' '[\n*]' | grep -v "^$" | sort | uniq -c | sort -nr > cvpr_word_frequencies.txt
