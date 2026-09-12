from app.models.ai_interview_models import (
    AIInterviewEvaluateRequest,
    AIInterviewEvaluateResponse,
    AIInterviewQuestionRequest,
    AIInterviewQuestionResponse,
)
from app.services.ai_service import generate_json, generate_text


def generate_interview_question(
    request: AIInterviewQuestionRequest,
) -> AIInterviewQuestionResponse:

    prompt = f"""
Generate one interview question for the learner.

Concept:
{request.concept}

Canonical knowledge:
{request.canonicalKnowledge}

Conversation history:
{request.conversationHistory}

The question should:
- test understanding of the concept
- require reasoning rather than simple memorization
- be appropriate for the supplied concept
- not include the answer

Return JSON with exactly this field:
{{
  "question": "..."
}}
"""

    result = generate_json(prompt)

    return AIInterviewQuestionResponse(
        question=result["question"]
    )


def evaluate_interview_answer(
    request: AIInterviewEvaluateRequest,
) -> AIInterviewEvaluateResponse:

    prompt = f"""
Evaluate a learner's interview answer.

Concept:
{request.concept}

Canonical knowledge:
{request.canonicalKnowledge}

Question:
{request.question}

Learner answer:
{request.learnerAnswer}

Score each dimension from 0.0 to 1.0:

- conceptualCorrectness
- completeness
- technicalClarity
- reasoning
- explanation

Also provide concise, actionable feedback.

Return JSON exactly in this structure:
{{
  "conceptualCorrectness": 0.0,
  "completeness": 0.0,
  "technicalClarity": 0.0,
  "reasoning": 0.0,
  "explanation": 0.0,
  "feedback": "..."
}}
"""

    result = generate_json(prompt)

    return AIInterviewEvaluateResponse(
        conceptualCorrectness=float(result["conceptualCorrectness"]),
        completeness=float(result["completeness"]),
        technicalClarity=float(result["technicalClarity"]),
        reasoning=float(result["reasoning"]),
        explanation=float(result["explanation"]),
        feedback=result["feedback"],
    )
