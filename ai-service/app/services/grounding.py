"""Retrieve curated reference material for a concept so LLM services only
rephrase real content instead of inventing canonical facts."""
import re
from typing import Any, Dict, List, Optional

from app.services.knowledge_index import Entry, get_index

FACT_KINDS = ("practice", "debugging", "concept_exercise")
SNIPPET_CHARS = 900


def concept_query(concept: Any) -> str:
    """Build a search string from a concept (dict or str). Concept name weighs
    most, so it comes first; topic is only a weak hint and added last."""
    if isinstance(concept, str):
        return concept
    if not isinstance(concept, dict):
        return ""
    parts = [str(concept.get(k) or "") for k in ("conceptName", "name", "title")]
    parts.append(str(concept.get("topic") or "") if not any(parts) else "")
    return " ".join(p for p in parts if p)


def _clean(text: str) -> str:
    text = re.sub(r"&nbsp;", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def snippet(entry: Entry) -> str:
    return _clean(entry.text)[:SNIPPET_CHARS]


def retrieve(concept: Any, limit: int = 3) -> List[Entry]:
    query = concept_query(concept)
    return [e for _, e in get_index().search(query, kinds=FACT_KINDS, limit=limit)]


def grounded_reference(concept: Any, limit: int = 3) -> Optional[Dict[str, Any]]:
    """Return {'text': ..., 'sources': [...]} or None when nothing relevant."""
    entries = retrieve(concept, limit)
    if not entries:
        return None
    blocks = []
    for i, e in enumerate(entries, 1):
        blocks.append(f"[{i}] ({e.source}#{e.id}) {e.title}\n{snippet(e)}")
    return {
        "text": "\n\n".join(blocks),
        "sources": [f"{e.source}#{e.id}" for e in entries],
    }


def reference_for_request(concept: Any, canonical: Any) -> Optional[str]:
    """Reference text to use when the request did not supply canonicalKnowledge."""
    if canonical:
        return None
    ref = grounded_reference(concept)
    return ref["text"] if ref else None
