import os
from bs4 import BeautifulSoup
from datetime import datetime

def download_page(url, output_file):
    os.system(f'wget "{url}" -O {output_file}')

def parse_arxiv_html(file_path):
    papers = []

    with open(file_path, 'r', encoding='utf-8') as file:
        html_content = file.read()

    # Parse the HTML content using BeautifulSoup
    soup = BeautifulSoup(html_content, 'html.parser')

    # Find all <dt> tags
    dt_tags = soup.find_all('dt')
    
    for dt in dt_tags:
        paper_info = {}
        title_link = dt.find('a', title='Abstract')
        if title_link:
            paper_info['arxiv_id'] = title_link.text
            paper_info['url'] = 'https://arxiv.org' + title_link['href']
            # Find the corresponding <dd> tag
            dd = dt.find_next_sibling('dd')
            if dd:
                title_span = dd.find('div', class_='list-title')
                if title_span:
                    paper_info['title'] = title_span.text.replace('Title:', '').strip()
            papers.append(paper_info)

    return papers


def get_safe_filename():
    # Get the current date
    now = datetime.now()
    # Format the date in a filesystem-safe format
    safe_filename = now.strftime('%Y-%m-%d')
    return safe_filename

def write_titles_to_file(papers, file_path):
    with open(file_path, 'w', encoding='utf-8') as file:
        for paper in papers:
            file.write(paper['title'] + '\n')

if __name__ == "__main__":
    url = 'https://arxiv.org/list/cs.AI/recent?skip=0&show=2000'
    output_file = 'arxiv_recent.html'
    
    # Download the webpage using wget
    #download_page(url, output_file)
    
    # Parse the downloaded HTML file
    papers = parse_arxiv_html(output_file)


    # Print the retrieved papers
    for count,paper in enumerate(papers):
        print(f"#{count} arXiv ID: {paper['arxiv_id']}\nTitle: {paper['title']}\nURL: {paper['url']}\n")

    write_titles_to_file(papers,"%s.description" % get_safe_filename() )

