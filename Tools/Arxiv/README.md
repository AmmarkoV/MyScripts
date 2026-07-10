# Arxiv News

Scrapes recent arXiv listings (and, in v2, other sources), writes a daily
titles file + JSON, and renders a word-cloud PNG. A small PHP page lists the
generated files as a browsable "news" feed. It runs unattended via cron.

## How it fits together

This directory (`~/Documents/Programming/MyScripts/Tools/Arxiv`) holds the
**source code**. The code is *served and run* from a separate directory,
`~/public_html/news/`, which contains:

- **symlinks** back to the scripts here (`cronTask.sh`, `getArxivNews.py`,
  `plotFreq.py`, `index.php`, ...),
- the **Python virtualenv** (`venv/`), and
- the **generated output** (`YYYY-MM-DD.description`,
  `YYYY-MM-DD.papers.json`, `YYYY-MM-DD.description.png`).

`cronTask.sh` uses `cd "$(dirname "${BASH_SOURCE[0]}")"` — because it is invoked
through the symlink at `~/public_html/news/cronTask.sh`, it changes into
`~/public_html/news/` and finds `venv/` and writes output there. **This is why
the venv lives in the serving dir, not in this repo.**

Data flow (daily): `cronTask.sh` → `getArxivNews.py` (downloads arXiv listings
with `wget`, parses with BeautifulSoup, dedupes, writes `.description` +
`.papers.json`) → `plotFreq.py` (renders the `.description.png` word cloud).
`index.php` then lists the results at `http://<host>/~ammar/news/`.

## Fresh install

Assumes Python 3.12+, `wget`, and a web server that serves `~/public_html`.

```bash
# 1. System dependency (used by getArxivNews.py to fetch listings)
sudo apt install wget

# 2. Create the serving directory
mkdir -p ~/public_html/news
cd ~/public_html/news

# 3. Symlink the code from this repo into the serving dir
SRC=~/Documents/Programming/MyScripts/Tools/Arxiv
ln -s "$SRC/cronTask.sh"     .
ln -s "$SRC/getArxivNews.py" .
ln -s "$SRC/plotFreq.py"     .
ln -s "$SRC/index.php"       .
# For the v2 pipeline also symlink: getArxivNews_v2.py paper_model.py
#   export_formats.py combineDescriptions.py  (see "v2" note below)

# 4. Create the virtualenv IN the serving dir and install deps
python3 -m venv venv
source venv/bin/activate
pip install beautifulsoup4 matplotlib pandas wordcloud

# 5. Smoke-test
./cronTask.sh
ls -t ~/public_html/news/*.description* | head
```

### Restore the cron job

The daily job was documented in the header of `cronTask.sh`. Install it with:

```bash
( crontab -l 2>/dev/null; \
  echo "30 22 * * * /home/ammar/public_html/news/cronTask.sh" ) | crontab -
crontab -l   # verify
```

Runs every day at **22:30**. Note the cron entry points at the **symlink**
(`~/public_html/news/cronTask.sh`), which is what makes the script resolve its
working directory to the serving dir — do not point it at this repo copy.

## Files

| File | Role |
|------|------|
| `cronTask.sh` | Entry point run by cron: clears `arxiv_*.html`, activates `venv`, runs `getArxivNews.py`. |
| `getArxivNews.py` | **Active pipeline.** Scrapes arXiv categories (`cs.CV/AI/RO/LG`), writes `.description` + `.papers.json`, invokes `plotFreq.py`. |
| `plotFreq.py` | Renders a word-cloud PNG from a `.description` file. |
| `index.php` | Web page listing generated `.description` / `.png` files. |
| `getArxivNews_v2.py` | Newer, richer pipeline (SQLite, extra sources). **Not used by cron** — see note. |
| `paper_model.py`, `export_formats.py`, `combineDescriptions.py` | Support modules for v2. |

## Notes

- **Which pipeline runs:** cron uses **v1** (`getArxivNews.py`), whose only
  third-party dep is BeautifulSoup (plus pandas/matplotlib/wordcloud via
  `plotFreq.py`). That is what the `pip install` line above covers.
- **v2 is not fully wired up here:** `getArxivNews_v2.py` imports
  `hackernews_scraper` and `huggingface_scraper`, which are **not present in
  this directory**. To use v2 you must add those scraper modules first; then
  switch `cronTask.sh` to call `getArxivNews_v2.py` and re-install its
  additional deps as needed.
- There is intentionally **no logging** in the cron entry. If the job silently
  stops, run `./cronTask.sh` by hand from `~/public_html/news/` to see errors.
