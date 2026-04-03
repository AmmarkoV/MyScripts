"""
Export formats for paper collections.

Supports multiple output formats:
- Plain text (.description files for backward compatibility)
- JSON (rich metadata)
- SQLite (efficient querying)
"""

import json
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict, Any
from paper_model import Paper, PaperCollection


# ============================================================================
# Text Export (Backward Compatibility)
# ============================================================================

def export_to_text(
    papers: List[Paper],
    output_path: str,
    format_type: str = 'title'
) -> int:
    """Export papers to plain text file.

    Args:
        papers: List of Paper objects
        output_path: Output file path
        format_type: 'title' (just title), 'id_title' (id + title)

    Returns:
        Number of lines written
    """
    count = 0
    with open(output_path, 'w', encoding='utf-8') as f:
        for paper in papers:
            if format_type == 'title':
                line = paper.title
            elif format_type == 'id_title':
                line = f"{paper.arxiv_id}: {paper.title}"
            else:
                line = paper.title

            if line.strip():
                f.write(line + '\n')
                count += 1

    return count


def export_description_file(
    collection: PaperCollection,
    date_str: Optional[str] = None
) -> str:
    """Export .description file for index.php compatibility.

    Args:
        collection: PaperCollection to export
        date_str: Date string (defaults to today)

    Returns:
        Path to created file
    """
    if date_str is None:
        date_str = datetime.now().strftime('%Y-%m-%d')

    output_path = f"{date_str}.description"
    papers = collection.to_list()
    export_to_text(papers, output_path, 'title')

    return output_path


# ============================================================================
# JSON Export
# ============================================================================

def export_to_json(
    collection: PaperCollection,
    output_path: str,
    include_abstract: bool = True
) -> str:
    """Export papers to JSON file with full metadata.

    Args:
        collection: PaperCollection to export
        output_path: Output file path
        include_abstract: Whether to include abstracts (can be large)

    Returns:
        Path to created file
    """
    papers_data = []
    for paper in collection:
        paper_dict = paper.to_dict()
        if not include_abstract:
            paper_dict.pop('abstract', None)
        papers_data.append(paper_dict)

    output = {
        'export_date': datetime.now().isoformat(),
        'total_count': len(papers_data),
        'papers': papers_data
    }

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    return output_path


def export_papers_json(
    collection: PaperCollection,
    date_str: Optional[str] = None
) -> str:
    """Export .papers.json file for programmatic access.

    Args:
        collection: PaperCollection to export
        date_str: Date string (defaults to today)

    Returns:
        Path to created file
    """
    if date_str is None:
        date_str = datetime.now().strftime('%Y-%m-%d')

    output_path = f"{date_str}.papers.json"
    export_to_json(collection, output_path)

    return output_path


# ============================================================================
# SQLite Export
# ============================================================================

def init_sqlite_db(db_path: str) -> sqlite3.Connection:
    """Initialize SQLite database for papers.

    Args:
        db_path: Database file path

    Returns:
        Database connection
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS papers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            arxiv_id TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            url TEXT,
            authors TEXT,
            abstract TEXT,
            categories TEXT,
            published TEXT,
            import_date TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # Create index for faster category queries
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_categories ON papers(categories)
    ''')

    # Create index for faster date queries
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_published ON papers(published)
    ''')

    conn.commit()
    return conn


def export_to_sqlite(
    collection: PaperCollection,
    db_path: str,
    import_date: Optional[str] = None
) -> int:
    """Export papers to SQLite database.

    Args:
        collection: PaperCollection to export
        db_path: Database file path
        import_date: Date of import (defaults to today)

    Returns:
        Number of papers inserted
    """
    if import_date is None:
        import_date = datetime.now().strftime('%Y-%m-%d')

    conn = init_sqlite_db(db_path)
    cursor = conn.cursor()

    inserted = 0
    for paper in collection:
        try:
            cursor.execute('''
                INSERT OR IGNORE INTO papers
                (arxiv_id, title, url, authors, abstract, categories, published, import_date)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                paper.arxiv_id,
                paper.title,
                paper.url,
                json.dumps(paper.authors),
                paper.abstract,
                json.dumps(paper.categories),
                paper.published,
                import_date
            ))
            if cursor.rowcount > 0:
                inserted += 1
        except sqlite3.Error as e:
            print(f"Error inserting paper {paper.arxiv_id}: {e}")

    conn.commit()
    conn.close()

    return inserted


def query_papers_by_category(
    db_path: str,
    category: str,
    limit: int = 100
) -> List[Dict[str, Any]]:
    """Query papers by category from SQLite database.

    Args:
        db_path: Database file path
        category: Category to search for
        limit: Maximum results to return

    Returns:
        List of paper dictionaries
    """
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    cursor.execute('''
        SELECT * FROM papers
        WHERE categories LIKE ?
        LIMIT ?
    ''', (f'%{category}%', limit))

    results = [dict(row) for row in cursor.fetchall()]
    conn.close()

    return results


def get_papers_by_date_range(
    db_path: str,
    start_date: str,
    end_date: str
) -> List[Dict[str, Any]]:
    """Get all papers imported within a date range.

    Args:
        db_path: Database file path
        start_date: Start date (YYYY-MM-DD)
        end_date: End date (YYYY-MM-DD)

    Returns:
        List of paper dictionaries
    """
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    cursor.execute('''
        SELECT * FROM papers
        WHERE import_date BETWEEN ? AND ?
        ORDER BY import_date DESC, published DESC
    ''', (start_date, end_date))

    results = [dict(row) for row in cursor.fetchall()]
    conn.close()

    return results


# ============================================================================
# Combined Export
# ============================================================================

def export_all_formats(
    collection: PaperCollection,
    base_path: Optional[str] = None,
    date_str: Optional[str] = None,
    use_sqlite: bool = True
) -> Dict[str, str]:
    """Export to all formats at once.

    Args:
        collection: PaperCollection to export
        base_path: Base path for output files
        date_str: Date string (defaults to today)
        use_sqlite: Whether to create SQLite database

    Returns:
        Dictionary of format -> file path
    """
    if date_str is None:
        date_str = datetime.now().strftime('%Y-%m-%d')

    if base_path is None:
        base_path = '.'

    paths = {}

    # Text export (backward compatibility)
    text_path = f"{base_path}/{date_str}.description"
    export_to_text(collection.to_list(), text_path, 'title')
    paths['text'] = text_path

    # JSON export
    json_path = f"{base_path}/{date_str}.papers.json"
    export_to_json(collection, json_path)
    paths['json'] = json_path

    # SQLite export
    if use_sqlite:
        db_path = f"{base_path}/papers.db"
        export_to_sqlite(collection, db_path, date_str)
        paths['sqlite'] = db_path

    return paths


if __name__ == "__main__":
    # Test exports
    from paper_model import Paper

    collection = PaperCollection()
    collection.add(Paper(
        arxiv_id="2401.12345",
        title="Test Paper 1",
        authors=["Author One"],
        categories=["cs.CV"]
    ))
    collection.add(Paper(
        arxiv_id="2401.12346",
        title="Test Paper 2",
        authors=["Author Two"],
        categories=["cs.AI"]
    ))

    # Export to all formats
    paths = export_all_formats(collection, date_str="2024-01-15")
    print("Exported to:")
    for fmt, path in paths.items():
        print(f"  {fmt}: {path}")
