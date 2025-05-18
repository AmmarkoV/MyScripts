#!/bin/bash


# 
#crontab -l > mycron
#echo "30 22 * * * /home/ammar/public_html/news/cronTask.sh" >> mycron
#crontab mycron
#rm mycron

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

rm arxiv_*.html

source venv/bin/activate

python3 getArxivNews.py
exit 0
