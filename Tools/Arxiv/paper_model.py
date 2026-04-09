"""
Paper data models and utilities for arxiv scraper.

Provides structured data classes and validation for paper metadata.
"""

from datetime import datetime
from typing import List, Optional
import re


class Paper:
    """Represents a paper from arxiv with full metadata."""

    # Regex to extract arxiv ID from various formats
    ARXIV_ID_PATTERN = re.compile(r'^(\d{4}\.|\d{2}\.)?(\d{4,5}\.\d{4,5})')

    def __init__(
        self,
        arxiv_id: str,
        title: str,
        url: Optional[str] = None,
        authors: Optional[List[str]] = None,
        abstract: Optional[str] = None,
        categories: Optional[List[str]] = None,
        published: Optional[str] = None
    ):
        self.arxiv_id = self._normalize_arxiv_id(arxiv_id)
        self.title = title.strip() if title else ""
        self.url = url or self._generate_url()
        self.authors = authors or []
        self.abstract = abstract or ""
        self.categories = categories or []
        self.published = published or datetime.now().isoformat()

    def _normalize_arxiv_id(self, arxiv_id: str) -> str:
        """Normalize arxiv ID to standard format (e.g., '2401.12345')."""
        arxiv_id = arxiv_id.strip()
        match = self.ARXIV_ID_PATTERN.match(arxiv_id)
        if match:
            return match.group(2)  # Return just the ID part
        return arxiv_id

    def _generate_url(self) -> str:
        """Generate arxiv URL from ID."""
        return f"https://arxiv.org/abs/{self.arxiv_id}"

    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization."""
        return {
            'arxiv_id': self.arxiv_id,
            'title': self.title,
            'url': self.url,
            'authors': self.authors,
            'abstract': self.abstract,
            'categories': self.categories,
            'published': self.published
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'Paper':
        """Create Paper from dictionary."""
        return cls(
            arxiv_id=data.get('arxiv_id', ''),
            title=data.get('title', ''),
            url=data.get('url'),
            authors=data.get('authors', []),
            abstract=data.get('abstract'),
            categories=data.get('categories', []),
            published=data.get('published')
        )

    def __str__(self) -> str:
        return f"Paper('{self.arxiv_id}': '{self.title[:50]}...')"

    def __eq__(self, other):
        if isinstance(other, Paper):
            return self.arxiv_id == other.arxiv_id
        return False

    def __hash__(self):
        return hash(self.arxiv_id)


class PaperCollection:
    """A collection of papers with deduplication and filtering."""

    def __init__(self):
        self._papers: List[Paper] = []
        self._id_set: set = set()

    def add(self, paper: Paper) -> bool:
        """Add paper if not already present.

        Returns:
            True if added, False if duplicate
        """
        if paper.arxiv_id in self._id_set:
            return False
        self._papers.append(paper)
        self._id_set.add(paper.arxiv_id)
        return True

    def add_many(self, papers: List[Paper]) -> int:
        """Add multiple papers.

        Returns:
            Number of papers actually added (excluding duplicates)
        """
        count = 0
        for paper in papers:
            if self.add(paper):
                count += 1
        return count

    def get_by_id(self, arxiv_id: str) -> Optional[Paper]:
        """Get paper by arxiv ID."""
        for paper in self._papers:
            if paper.arxiv_id == arxiv_id:
                return paper
        return None

    def filter_by_category(self, category: str) -> List[Paper]:
        """Filter papers by category."""
        return [p for p in self._papers if category in p.categories]

    def filter_by_date(self, date_str: str) -> List[Paper]:
        """Filter papers by publication date."""
        return [p for p in self._papers if p.published.startswith(date_str)]

    def to_list(self) -> List[Paper]:
        """Get list of all papers."""
        return self._papers.copy()

    def to_dicts(self) -> List[dict]:
        """Get list of paper dictionaries."""
        return [p.to_dict() for p in self._papers]

    def __len__(self) -> int:
        return len(self._papers)

    def __iter__(self):
        return iter(self._papers)


class MixedCollection:
    """A collection that can hold papers, blog posts, models, and HN stories.

    This class provides a unified interface for managing content from
    multiple sources (arxiv, HuggingFace blog, HuggingFace models, Hacker News).
    """

    def __init__(self):
        self._papers: List[Paper] = []
        self._paper_id_set: set = set()
        self._blog_posts: List[dict] = []
        self._blog_slug_set: set = set()
        self._models: List[dict] = []
        self._model_id_set: set = set()
        self._hn_stories: List[dict] = []
        self._hn_story_id_set: set = set()

    # Paper methods
    def add_paper(self, paper: Paper) -> bool:
        """Add paper if not already present."""
        if paper.arxiv_id in self._paper_id_set:
            return False
        self._papers.append(paper)
        self._paper_id_set.add(paper.arxiv_id)
        return True

    def add_papers(self, papers: List[Paper]) -> int:
        """Add multiple papers."""
        count = 0
        for paper in papers:
            if self.add_paper(paper):
                count += 1
        return count

    # Blog post methods
    def add_blog_post(self, blog_post: dict) -> bool:
        """Add blog post if not already present.

        Args:
            blog_post: Dictionary with 'url_slug' key

        Returns:
            True if added, False if duplicate
        """
        url_slug = blog_post.get('url_slug', '')
        if url_slug in self._blog_slug_set:
            return False
        self._blog_posts.append(blog_post)
        self._blog_slug_set.add(url_slug)
        return True

    def add_blog_posts(self, blog_posts: List[dict]) -> int:
        """Add multiple blog posts."""
        count = 0
        for post in blog_posts:
            if self.add_blog_post(post):
                count += 1
        return count

    # Model methods
    def add_model(self, model: dict) -> bool:
        """Add model if not already present.

        Args:
            model: Dictionary with 'model_id' key

        Returns:
            True if added, False if duplicate
        """
        model_id = model.get('model_id', '')
        if model_id in self._model_id_set:
            return False
        self._models.append(model)
        self._model_id_set.add(model_id)
        return True

    def add_models(self, models: List[dict]) -> int:
        """Add multiple models."""
        count = 0
        for model in models:
            if self.add_model(model):
                count += 1
        return count

    # HN story methods
    def add_hn_story(self, story: dict) -> bool:
        """Add HN story if not already present.

        Args:
            story: Dictionary with 'story_id' key

        Returns:
            True if added, False if duplicate
        """
        story_id = story.get('story_id', '')
        if story_id in self._hn_story_id_set:
            return False
        self._hn_stories.append(story)
        self._hn_story_id_set.add(story_id)
        return True

    def add_hn_stories(self, stories: List[dict]) -> int:
        """Add multiple HN stories."""
        count = 0
        for story in stories:
            if self.add_hn_story(story):
                count += 1
        return count

    # Unified methods
    def get_all_titles(self) -> List[str]:
        """Get all titles from all sources."""
        titles = []
        titles.extend([p.title for p in self._papers if p.title])
        titles.extend([b.get('title', '') for b in self._blog_posts if b.get('title')])
        titles.extend([m.get('title', m.get('model_id', '')) for m in self._models])
        titles.extend([h.get('title', '') for h in self._hn_stories if h.get('title')])
        return titles

    def get_all_items(self) -> List[dict]:
        """Get all items as dictionaries with source tag."""
        items = []
        items.extend([p.to_dict() for p in self._papers])
        items.extend(self._blog_posts)
        items.extend(self._models)
        items.extend(self._hn_stories)
        return items

    def to_export_format(self) -> dict:
        """Convert to format suitable for export."""
        return {
            'papers': [p.to_dict() for p in self._papers],
            'blog_posts': self._blog_posts,
            'models': self._models,
            'hn_stories': self._hn_stories,
            'counts': {
                'papers': len(self._papers),
                'blog_posts': len(self._blog_posts),
                'models': len(self._models),
                'hn_stories': len(self._hn_stories),
                'total': len(self._papers) + len(self._blog_posts) + len(self._models) + len(self._hn_stories)
            }
        }

    def __len__(self) -> int:
        return len(self._papers) + len(self._blog_posts) + len(self._models) + len(self._hn_stories)

    def __repr__(self) -> str:
        return f"MixedCollection(papers={len(self._papers)}, blog_posts={len(self._blog_posts)}, models={len(self._models)}, hn_stories={len(self._hn_stories)})"


def extract_authors(author_text: str) -> List[str]:
    """Extract author names from arxiv author list text.

    Example input: "Author 1, Author 2, and Author 3"
    """
    if not author_text:
        return []

    # Split by comma and "and"
    authors = re.split(r'[,\s]+and\s+', author_text)
    authors = [a.strip() for a in authors if a.strip()]
    return authors


if __name__ == "__main__":
    # Test the model
    paper = Paper(
        arxiv_id="2401.12345",
        title="Test Paper Title",
        authors=["John Doe", "Jane Smith"],
        abstract="This is a test abstract.",
        categories=["cs.CV", "cs.AI"]
    )

    print(f"Paper: {paper}")
    print(f"Dict: {paper.to_dict()}")

    # Test collection
    collection = PaperCollection()
    collection.add(paper)
    collection.add(paper)  # Duplicate
    print(f"Collection size: {len(collection)}")
