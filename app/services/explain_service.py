from app.services.ai_service import generate_text


def generate_explanation(concept: str) -> str:
    prompt = f"""
    Explain the following technical concept in very simple language.

    Concept: {concept}

    Rules:
    - Keep the explanation beginner-friendly.
    - Keep the technical information correct.
    - Use a simple example if useful.
    """

    return generate_text(prompt)
