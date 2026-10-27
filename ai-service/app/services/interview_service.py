import json
import random
from typing import List, Optional

from app.core.paths import CONTENT_DIR

_questions: Optional[List[dict]] = None


def get_all_questions() -> List[dict]:
    global _questions
    if _questions is None:
        path = CONTENT_DIR / "interview_questions.json"
        try:
            with open(path, "r", encoding="utf-8") as f:
                _questions = json.load(f)
        except (OSError, ValueError):
            _questions = []
    return _questions


def select_question(topic: str, difficulty: str, excluded_ids: list):
    excluded = {str(i) for i in (excluded_ids or [])}
    candidates = [
        q for q in get_all_questions()
        if q["topic"] == topic
        and q["difficulty"] == difficulty
        and str(q["id"]) not in excluded
    ]

    if not candidates:
        return None

    return random.choice(candidates)
