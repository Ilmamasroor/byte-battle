from typing import Optional

from fastapi import APIRouter, Query

from app.services.knowledge_index import get_index

router = APIRouter()

CONCURRENCY_MARKERS = ("multithreading", "concurren")


@router.get("/content/problems")
def content_problems(
    concept: Optional[str] = Query(default=None, description="Concept name to match, e.g. 'race condition'"),
    kind: str = Query(default="all", pattern="^(all|practice|debugging)$"),
    limit: int = Query(default=50, ge=1, le=200),
):
    """Practice/debugging problems parsed from the multithreading content files,
    so the backend can seed them. Without `concept`, returns all of them."""
    kinds = ("practice", "debugging") if kind == "all" else (kind,)
    index = get_index()
    pool = [
        e
        for e in index.entries
        if e.kind in kinds and any(m in e.topic.lower() for m in CONCURRENCY_MARKERS)
    ]
    if concept and concept.strip():
        pool_ids = {e.uid for e in pool}
        hits = [e for _, e in index.search(concept, kinds=kinds, limit=len(index.entries), min_score=4.0) if e.uid in pool_ids]
        pool = hits
    problems = [e.public() for e in pool[:limit]]
    return {"concept": concept, "kind": kind, "count": len(problems), "problems": problems}
