#!/usr/bin/env python3
"""
Arxiv News Scraper - v2

A modern, modular scraper for arxiv papers with support for multiple
output formats (text, JSON, SQLite) and improved error handling.

Usage:
    python3 getArxivNews_v2.py [--categories CS.CV,CS.AI] [--count 1000]
"""

import argparse
import logging
import os
import sys
from datetime import datetime
from typing import List

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from paper_model import Paper, PaperCollection, extract_authors
from export_formats import export_all_formats

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Default configuration
DEFAULT_CATEGORIES = ['cs.CV', 'cs.AI', 'cs.RO', 'cs.LG']
DEFAULT_SHOW_COUNT = 2000


def download_page(url: str, output_file: str) -> bool:
    """Download webpage using wget with timeout."""
    logger.info(f"Downloading {url}")
    result = os.system(f'wget -q --timeout=30 "{url}" -O {output_file} 2>/dev/null')
    return result == 0


def parse_arxiv_html(file_path: str) -> List[Paper]:
    """Parse arxiv HTML listing and extract papers."""
    from bs4 import BeautifulSoup

    papers = []

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            html_content = f.read()
    except IOError as e:
        logger.error(f"Error reading {file_path}: {e}")
        return papers

    soup = BeautifulSoup(html_content, 'html.parser')

    # Find all dt elements (each represents a paper entry)
    for dt in soup.find_all('dt'):
        title_link = dt.find('a', title='Abstract')
        if not title_link:
            continue

        arxiv_id = title_link.text.strip()
        url = 'https://arxiv.org' + title_link['href']

        # Extract title and authors from sibling dd
        title = ""
        authors = []
        dd = dt.find_next_sibling('dd')
        if dd:
            title_span = dd.find('div', class_='list-title')
            if title_span:
                title = title_span.text.replace('Title:', '').strip()

            # Extract authors from the list-authors div
            author_div = dd.find('div', class_='list-authors')
            if author_div:
                # Each author is an <a> link inside the div
                author_links = author_div.find_all('a')
                authors = [link.text.strip() for link in author_links if link.text.strip()]

        if title:
            paper = Paper(arxiv_id=arxiv_id, title=title, url=url, authors=authors)
            papers.append(paper)

    logger.info(f"Extracted {len(papers)} papers from {file_path}")
    return papers


def main():
    parser = argparse.ArgumentParser(description='Scrape recent papers from arxiv')
    parser.add_argument(
        '--categories', '-c',
        type=str,
        default=','.join(DEFAULT_CATEGORIES),
        help=f'Comma-separated categories (default: {",".join(DEFAULT_CATEGORIES)})'
    )
    parser.add_argument(
        '--count', '-n',
        type=int,
        default=DEFAULT_SHOW_COUNT,
        help=f'Papers per category (default: {DEFAULT_SHOW_COUNT})'
    )
    parser.add_argument(
        '--no-sqlite',
        action='store_true',
        help='Skip SQLite export'
    )
    parser.add_argument(
        '--quiet', '-q',
        action='store_true',
        help='Suppress output except errors'
    )

    args = parser.parse_args()

    if args.quiet:
        logging.getLogger().setLevel(logging.ERROR)

    # Parse categories
    categories = [c.strip() for c in args.categories.split(',')]
    categories = [c for c in categories if c]  # Filter empty

    logger.info(f"Fetching from categories: {categories}")

    # Collect papers
    collection = PaperCollection()
    temp_files = []

    for idx, category in enumerate(categories):
        url = f'https://arxiv.org/list/{category}/recent?skip=0&show={args.count}'
        output_file = f'arxiv_temp_{category.replace(".", "_")}_{idx}.html'
        temp_files.append(output_file)

        if not download_page(url, output_file):
            logger.warning(f"Failed to download {category}, skipping")
            continue

        papers = parse_arxiv_html(output_file)
        added = collection.add_many(papers)
        logger.info(f"{category}: {len(papers)} fetched, {added} new")

    logger.info(f"Total unique papers: {len(collection)}")

    if len(collection) == 0:
        logger.error("No papers collected!")
        sys.exit(1)

    # Export to all formats
    date_str = datetime.now().strftime('%Y-%m-%d')
    paths = export_all_formats(
        collection,
        date_str=date_str,
        use_sqlite=not args.no_sqlite
    )

    logger.info(f"Exported to: {list(paths.keys())}")

    # Generate word cloud
    desc_file = f"{date_str}.description"
    if os.path.exists(desc_file):
        logger.info(f"Generating word cloud...")
        os.system(f"python3 plotFreq.py {desc_file} 2>/dev/null")

    # Cleanup temp files
    for tf in temp_files:
        try:
            os.remove(tf)
        except OSError:
            pass

    logger.info("Done!")

    # Print summary
    print(f"\n{'='*50}")
    print(f"Processed {len(collection)} unique papers")
    print(f"\nOutput files:")
    for fmt, path in paths.items():
        print(f"  {fmt}: {path}")
    print(f"{'='*50}")


if __name__ == "__main__":
    main()
