"""In-memory index over every content/parsed/*.json file, with keyword retrieval.

Schemas seen: lists of {id, problem|question, subCategory, topic, difficulty,
code?, activityType?, isStubOnly?}. Every file is loaded; entries are normalised
into Entry objects. Interview questions carry no answer text, so they are
indexed with kind='interview_question' and never used as factual grounding.
"""
import json
import logging
import re
from dataclasses import dataclass, field
from typing import Any, Dict, Iterable, List, Optional, Tuple

from app.core.paths import CONTENT_DIR

logger = logging.getLogger(__name__)

STOPWORDS = {
    "a", "an", "the", "and", "or", "of", "in", "on", "to", "for", "with", "is",
    "are", "how", "what", "why", "does", "do", "java", "basics", "basic", "concept",
    "concepts", "introduction", "using", "use", "vs", "between", "about",
}

# Small domain synonym map (token -> related tokens) to catch curated wording.
SYNONYMS = {
    "race": {"race", "conditions", "condition", "hazard", "data"},
    "deadlock": {"deadlock", "deadlocks", "circular"},
    "synchronization": {"synchronized", "synchronization", "mutex", "mutexes", "lock", "locks"},
    "synchronisation": {"synchronized", "synchronization", "mutex", "mutexes", "lock", "locks"},
    "mutex": {"mutex", "mutexes", "lock", "locks"},
    "thread": {"thread", "threads", "runnable", "concurrency", "concurrent"},
    "threads": {"thread", "threads", "runnable", "concurrency", "concurrent"},
    "multithreading": {"thread", "threads", "concurrency", "concurrent", "multithreading"},
    "concurrency": {"thread", "threads", "concurrency", "concurrent"},
    "executor": {"executor", "executors", "pool", "pools", "threadpool"},
    "semaphore": {"semaphore", "semaphores", "permits"},
    "volatile": {"volatile", "visibility", "memory"},
    "atomic": {"atomic", "atomicinteger", "atomicreference", "cas"},
}

_TOKEN_RE = re.compile(r"[a-z0-9]+")


def stem(tok: str) -> str:
    for suf in ("ings", "ing", "es", "s", "ed"):
        if tok.endswith(suf) and len(tok) - len(suf) >= 4:
            return tok[: -len(suf)]
    return tok


def tokenize(text: str) -> List[str]:
    return [stem(t) for t in _TOKEN_RE.findall((text or "").lower()) if t not in STOPWORDS and len(t) > 1]


@dataclass
class Entry:
    uid: str
    source: str  # file stem
    kind: str  # practice | debugging | interview_question | concept_exercise | reference
    id: str
    title: str
    topic: str
    difficulty: str
    text: str
    code: str = ""
    raw: Dict[str, Any] = field(default_factory=dict)
    _title_tokens: set = field(default_factory=set, repr=False)
    _text_tokens: Dict[str, int] = field(default_factory=dict, repr=False)
    _code_tokens: set = field(default_factory=set, repr=False)

    def public(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "source": self.source,
            "kind": self.kind,
            "subCategory": self.title,
            "topic": self.topic,
            "difficulty": self.difficulty,
            "problem": self.text,
            "code": self.code,
        }


def _kind_for(source: str, item: Dict[str, Any]) -> str:
    if "question" in item and "problem" not in item:
        return "interview_question"
    if item.get("activityType") == "debugging" or "debugging" in source:
        return "debugging"
    if "practice" in source or "concurrent" in source:
        return "practice"
    return "concept_exercise"


class KnowledgeIndex:
    def __init__(self, entries: List[Entry], files: List[str]) -> None:
        self.entries = entries
        self.files = files

    @classmethod
    def load(cls, directory=CONTENT_DIR) -> "KnowledgeIndex":
        entries: List[Entry] = []
        files: List[str] = []
        if not directory.is_dir():
            logger.warning("content directory not found: %s", directory)
            return cls([], [])
        for path in sorted(directory.glob("*.json")):
            try:
                with open(path, "r", encoding="utf-8") as fh:
                    data = json.load(fh)
            except (OSError, ValueError) as exc:
                logger.warning("could not load content file %s: %s", path.name, type(exc).__name__)
                continue
            if not isinstance(data, list):
                continue
            files.append(path.name)
            source = path.stem
            for i, item in enumerate(data):
                if not isinstance(item, dict):
                    continue
                text = str(item.get("problem") or item.get("question") or "")
                e = Entry(
                    uid=f"{source}:{item.get('id', i)}",
                    source=source,
                    kind=_kind_for(source, item),
                    id=str(item.get("id", i)),
                    title=str(item.get("subCategory") or ""),
                    topic=str(item.get("topic") or ""),
                    difficulty=str(item.get("difficulty") or ""),
                    text=text,
                    code=str(item.get("code") or ""),
                    raw=item,
                )
                e._title_tokens = set(tokenize(e.title))
                tf: Dict[str, int] = {}
                for t in tokenize(text):
                    tf[t] = tf.get(t, 0) + 1
                e._text_tokens = tf
                e._code_tokens = set(tokenize(e.code[:4000])) if e.code else set()
                entries.append(e)
        return cls(entries, files)

    def count(self) -> int:
        return len(self.entries)

    @staticmethod
    def _keywords(query: str) -> Dict[str, float]:
        weights: Dict[str, float] = {}
        for tok in tokenize(query):
            weights[tok] = max(weights.get(tok, 0), 1.0)
            for syn in SYNONYMS.get(tok, ()):
                s = stem(syn)
                weights[s] = max(weights.get(s, 0), 0.4)
        return weights

    def search(
        self,
        query: str,
        kinds: Optional[Iterable[str]] = None,
        limit: int = 5,
        min_score: float = 3.0,
    ) -> List[Tuple[float, Entry]]:
        kw = self._keywords(query)
        if not kw:
            return []
        allowed = set(kinds) if kinds else None
        scored: List[Tuple[float, Entry]] = []
        for e in self.entries:
            if allowed is not None and e.kind not in allowed:
                continue
            score = 0.0
            for tok, w in kw.items():
                if tok in e._title_tokens:
                    score += 3.0 * w
                n = e._text_tokens.get(tok, 0)
                if n:
                    score += min(n, 3) * w
                if tok in e._code_tokens:
                    score += 0.5 * w
            if score >= min_score:
                scored.append((score, e))
        scored.sort(key=lambda p: (-p[0], p[1].uid))
        return scored[:limit]


_index: Optional[KnowledgeIndex] = None


def get_index() -> KnowledgeIndex:
    global _index
    if _index is None:
        _index = KnowledgeIndex.load()
    return _index


def reload_index() -> KnowledgeIndex:
    global _index
    _index = KnowledgeIndex.load()
    return _index
