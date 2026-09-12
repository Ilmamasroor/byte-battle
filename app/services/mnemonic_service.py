from app.models.mnemonic_models import MnemonicRequest
from app.services.ai_service import generate_json


def generate_mnemonic(data: MnemonicRequest) -> dict:
    prompt = f"""
You are Byte Battle's AI Mnemonic Generator.

Your job is to create a short, memorable, and technically
accurate mnemonic to help the learner remember the given concept.

CONCEPT:
{data.concept}

CANONICAL TECHNICAL KNOWLEDGE:
{data.canonicalKnowledge}

LEARNER BYTE DNA:
{data.byteDNA}

RULES:

1. Use the canonical technical knowledge as the source of truth.
2. Do not invent or change technical facts.
3. Focus on the most important idea of the concept.
4. Keep the mnemonic short, clear, and easy to remember.
5. The mnemonic must be exactly ONE line.
6. Keep the mnemonic between 8 and 15 words.
7. Match the mnemonic to the learner's technical experience.
8. Use learner interests when they naturally help memorization.
9. Do not force the learner's interest if it does not fit.
10. Avoid unnecessary technical terminology for beginners.
11. The mnemonic must remain technically correct.
12. Do not use performance, learning history, or diagnosis data.
13. Return only valid JSON.

RETURN EXACTLY THIS STRUCTURE:

{{
    "mnemonic": "...",
    "memoryTip": "..."
}}
"""

    return generate_json(prompt)
