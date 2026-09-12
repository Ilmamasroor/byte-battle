from app.models.byte_dna_models import ByteDNARequest
from app.services.ai_service import generate_json


def create_byte_dna(data: ByteDNARequest) -> dict:
    prompt = f"""
    You are Byte Battle's learner profiling assistant.

    Create an initial Byte DNA from the learner information below.

    Technical Level: {data.technicalLevel}
    Experience: {data.experience}
    Goals: {data.goals}
    Subjects: {data.subjects}
    Interests: {data.interests}
    Learning Preference: {data.learningPreference}

    Rules:
    - Use only the information provided.
    - Do not invent strengths.
    - Do not invent weaknesses.
    - Do not assume skills that were not provided.
    - Return only valid JSON.

    JSON format:
    {{
        "technicalLevel": "...",
        "goals": [],
        "interests": [],
        "learningPreference": "...",
        "strongAreas": [],
        "weakAreas": []
    }}
    """

    return generate_json(prompt)
