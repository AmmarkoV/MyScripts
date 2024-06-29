#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

rm arxiv_*.html

python3 getArxivNews.py
exit 0
