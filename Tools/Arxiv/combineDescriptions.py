import os
import sys
from datetime import datetime, date, timedelta

def get_dates_since(start_date):
    """Yield all dates from start_date up to and including today."""
    current = start_date
    today = date.today()
    while current <= today:
        yield current
        current += timedelta(days=1)

def combine_descriptions(start_date_str, output_file):
    try:
        start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
    except ValueError:
        print(f"Error: date must be in YYYY-MM-DD format, got '{start_date_str}'")
        sys.exit(1)

    found = []
    missing = []

    for d in get_dates_since(start_date):
        filename = f"{d.strftime('%Y-%m-%d')}.description"
        if os.path.isfile(filename):
            found.append(filename)
        else:
            missing.append(filename)

    if not found:
        print("No .description files found for the given date range.")
        sys.exit(1)

    seen = set()
    total = 0

    with open(output_file, 'w', encoding='utf-8') as out:
        for filename in found:
            with open(filename, 'r', encoding='utf-8') as f:
                for line in f:
                    title = line.rstrip('\n')
                    if title and title not in seen:
                        seen.add(title)
                        out.write(title + '\n')
                        total += 1

    print(f"Combined {len(found)} file(s) into '{output_file}' ({total} unique titles).")
    if missing:
        print(f"Skipped {len(missing)} missing date(s): {', '.join(missing)}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: python3 {sys.argv[0]} <start-date> [output-file]")
        print(f"  start-date:  YYYY-MM-DD")
        print(f"  output-file: default 'combined.description'")
        sys.exit(1)

    start_date_str = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else "combined.description"

    combine_descriptions(start_date_str, output_file)
