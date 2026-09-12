from app.models.interview_models import InterviewQuestionRequest, InterviewEvaluateRequest
from app.services.ai_service import generate_json


def generate_interview_question(data: InterviewQuestionRequest) -> dict:
    prompt = f"""
You are Byte Battle's Technical Interviewer.

Your job is to ask a technical interview question
based on the given concept.

CONCEPT:
{data.concept}

CANONICAL TECHNICAL KNOWLEDGE:
{data.canonicalKnowledge}

CONVERSATION HISTORY:
{data.conversationHistory}

RULES:

1. Ask one technical interview question.
2. Keep the question relevant to the concept.
3. Use canonical knowledge as the technical source of truth.
4. Do not invent technical facts.
5. If conversation history is available, use it to create
   a relevant follow-up question.
6. Keep the question clear and interview-like.
7. Do not provide the answer.
8. Return only valid JSON.

RETURN EXACTLY:

{{
    "question": "..."
}}
"""

    return generate_json(prompt)


def evaluate_interview_answer(data: InterviewEvaluateRequest) -> dict:
    prompt = f"""
You are Byte Battle's Technical Interview Evaluator.

Evaluate the learner's answer to the given technical interview question.

CONCEPT:
{data.concept}

CANONICAL TECHNICAL KNOWLEDGE:
{data.canonicalKnowledge}

INTERVIEW QUESTION:
{data.question}

LEARNER ANSWER:
{data.learnerAnswer}

Evaluate the answer on exactly these 5 dimensions:

1. conceptualCorrectness
2. completeness
3. technicalClarity
4. reasoning
5. explanation

RULES:

1. Use canonical technical knowledge as the technical source of truth.
2. Do not invent technical facts.
3. Evaluate only the learner's given answer.
4. Do not judge based on grammar alone.
5. A short answer can still be correct.
6. Identify what the learner understood correctly.
7. Identify important missing information.
8. Keep feedback specific and actionable.
9. Do not change the technical meaning of the canonical knowledge.
10. Return only valid JSON.

SCORING:

Give each dimension a score from 0.00 to 1.00.

0.00 = completely incorrect / missing
0.50 = partially correct
1.00 = excellent

RETURN EXACTLY:

{{
    "conceptualCorrectness": 0.00,
    "completeness": 0.00,
    "technicalClarity": 0.00,
    "reasoning": 0.00,
    "explanation": 0.00,
    "feedback": "..."
}}
"""

    return generate_json(prompt)
