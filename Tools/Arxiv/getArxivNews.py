import os
import json
import logging
from bs4 import BeautifulSoup
from datetime import datetime
from typing import List, Dict, Optional, Set

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Default arxiv categories to scrape
DEFAULT_CATEGORIES = [
    'cs.CV',   # Computer Vision
    'cs.AI',   # Artificial Intelligence
    'cs.RO',   # Robotics
    'cs.LG',   # Machine Learning
]

# Maximum papers per category
DEFAULT_SHOW_COUNT = 2000


def download_page(url: str, output_file: str) -> bool:
    """Download webpage using wget.

    Args:
        url: The URL to download
        output_file: Local file path to save to

    Returns:
        True if download successful, False otherwise
    """
    logger.info(f"Downloading {url}")
    result = os.system(f'wget -q --timeout=30 "{url}" -O {output_file}')
    if result == 0:
        logger.info(f"Saved to {output_file}")
        return True
    else:
        logger.error(f"Failed to download {url}")
        return False


def parse_arxiv_html(file_path: str) -> List[Dict]:
    """Parse arxiv HTML listing page and extract paper metadata.

    Args:
        file_path: Path to downloaded HTML file

    Returns:
        List of paper dictionaries with arxiv_id, url, and title
    """
    papers = []

    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            html_content = file.read()
    except IOError as e:
        logger.error(f"Error reading {file_path}: {e}")
        return papers

    soup = BeautifulSoup(html_content, 'html.parser')
    dt_tags = soup.find_all('dt')

    for dt in dt_tags:
        title_link = dt.find('a', title='Abstract')
        if title_link:
            paper_info = {
                'arxiv_id': title_link.text.strip(),
                'url': 'https://arxiv.org' + title_link['href'],
                'title': ''
            }

            dd = dt.find_next_sibling('dd')
            if dd:
                title_span = dd.find('div', class_='list-title')
                if title_span:
                    paper_info['title'] = title_span.text.replace('Title:', '').strip()

            if paper_info['title']:  # Only add if we got a title
                papers.append(paper_info)
            else:
                logger.warning(f"Paper {paper_info['arxiv_id']} has no title")

    logger.info(f"Extracted {len(papers)} papers from {file_path}")
    return papers


def deduplicate_papers(papers: List[Dict], seen_ids: Set[str]) -> List[Dict]:
    """Filter out papers we've already seen.

    Args:
        papers: List of paper dictionaries
        seen_ids: Set of arxiv IDs already processed

    Returns:
        Filtered list of new papers only
    """
    new_papers = []
    for paper in papers:
        if paper['arxiv_id'] not in seen_ids:
            new_papers.append(paper)
            seen_ids.add(paper['arxiv_id'])
    return new_papers


def get_safe_filename() -> str:
    """Get current date as filesystem-safe filename."""
    return datetime.now().strftime('%Y-%m-%d')


def write_titles_to_file(papers: List[Dict], file_path: str) -> int:
    """Write paper titles to text file (one per line).

    Args:
        papers: List of paper dictionaries
        file_path: Output file path

    Returns:
        Number of titles written
    """
    count = 0
    with open(file_path, 'w', encoding='utf-8') as file:
        for paper in papers:
            if paper.get('title'):
                file.write(paper['title'] + '\n')
                count += 1
    logger.info(f"Wrote {count} titles to {file_path}")
    return count


def write_papers_to_json(papers: List[Dict], file_path: str) -> int:
    """Write papers with full metadata to JSON file.

    Args:
        papers: List of paper dictionaries
        file_path: Output file path

    Returns:
        Number of papers written
    """
    output = {
        'date': get_safe_filename(),
        'total_count': len(papers),
        'papers': papers
    }

    with open(file_path, 'w', encoding='utf-8') as file:
        json.dump(output, file, indent=2, ensure_ascii=False)

    logger.info(f"Wrote {len(papers)} papers to JSON: {file_path}")
    return len(papers)


def generate_category_url(category: str, show_count: int = DEFAULT_SHOW_COUNT) -> str:
    """Generate arxiv URL for a category.

    Args:
        category: Arxiv category (e.g., 'cs.CV')
        show_count: Number of papers to fetch

    Returns:
        Arxiv listing URL
    """
    return f'https://arxiv.org/list/{category}/recent?skip=0&show={show_count}'


def main():
    """Main entry point for arxiv scraper."""
    logger.info("Starting arxiv scraper...")

    categories = DEFAULT_CATEGORIES
    all_papers = []
    seen_ids: Set[str] = set()
    temp_files = []

    # Download and parse each category
    for idx, category in enumerate(categories):
        url = generate_category_url(category)
        output_file = f'arxiv_recent_{category.replace(".", "_")}_{idx}.html'
        temp_files.append(output_file)

        if not download_page(url, output_file):
            logger.warning(f"Skipping {category} due to download failure")
            continue

        papers = parse_arxiv_html(output_file)
        new_papers = deduplicate_papers(papers, seen_ids)
        all_papers.extend(new_papers)

        logger.info(f"Category {category}: {len(papers)} total, {len(new_papers)} new")

    logger.info(f"Total unique papers: {len(all_papers)}")

    # Generate output filenames
    date_str = get_safe_filename()
    text_file = f"{date_str}.description"
    json_file = f"{date_str}.papers.json"

    # Write outputs
    write_titles_to_file(all_papers, text_file)
    write_papers_to_json(all_papers, json_file)

    # Generate word cloud
    logger.info(f"Generating word cloud for {text_file}")
    os.system(f"python3 plotFreq.py {text_file}")

    # Cleanup temp files
    for temp_file in temp_files:
        try:
            os.remove(temp_file)
        except OSError:
            pass

    logger.info("Done!")

    # Print summary
    print(f"\nProcessed {len(all_papers)} unique papers")
    print(f"Text output: {text_file}")
    print(f"JSON output: {json_file}")


if __name__ == "__main__":
    main()

