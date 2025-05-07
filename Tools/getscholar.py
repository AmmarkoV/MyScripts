#! env/bin/activate

from scholarly import scholarly
import datetime
import argparse
import csv

parser = argparse.ArgumentParser(description="This is a script that returns the top (t) publications of a google scholar author (a) in the last (y) years.")
parser.add_argument('--author', '-a', required=True, type=str, help="the author name as it appears in Google Scholar.")
parser.add_argument('--top', '-t', required=True, type=int, help="the (t) most cited publications to return.")
parser.add_argument('--years', '-y' , required=True, type=int, help="the last (y) years to search in.")
args = parser.parse_args()

author_name = args.author
top_cited_no = args.top
recent_years = args.years

current_year = datetime.datetime.now().year
year_threshold = current_year - recent_years

search_query = scholarly.search_author(author_name)
author = next(search_query, None)

if not author:
    print("Author not found.")
    exit(1)

author = scholarly.fill(author)

recent = []
for i, pub in enumerate(author['publications']):
    pub_year = int(pub['bib'].get('pub_year', 0))
    if pub_year >= year_threshold:
        recent.append({
            'id': i,
            'citations': pub['num_citations']
        })

# Sort by citation count, descending, keep the top cited ones.
filtered = sorted(recent, key=lambda x: x['citations'], reverse=True)[:top_cited_no]

selected = []
for entry in filtered:
    pub = author['publications'][entry['id']]
    pub = scholarly.fill(pub) # query google scholar for more metadata.
    selected.append({
        'title': pub['bib']['title'],
        'year': int(pub['bib'].get('pub_year', 0)),
        'citations': pub['num_citations'],
        'url': pub['pub_url']
    })

# Write results to CSV
out_path=f"{author_name.replace(' ','_')}_{year_threshold}-{current_year}_top_{top_cited_no}.csv"
with open(out_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['Title', 'Year', 'Citations', 'URL'])
    for paper in selected:
        writer.writerow([paper['title'], paper['year'], paper['citations'], paper['url']])

print(f"Results written to {out_path}")

