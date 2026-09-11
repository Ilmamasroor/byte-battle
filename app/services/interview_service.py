import json
import random

with open("content/parsed/interview_questions.json", "r") as f:
    ALL_QUESTIONS = json.load(f)

def select_question(topic: str, difficulty: str, excluded_ids: list):
    candidates = [
        q for q in ALL_QUESTIONS
        if q["topic"] == topic
        and q["difficulty"] == difficulty
        and q["id"] not in excluded_ids
    ]

    if not candidates:
        return None

    return random.choice(candidates)