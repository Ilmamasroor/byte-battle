from fastapi import APIRouter

from app.models.ai_interview_models import (
    AIInterviewEvaluateRequest,
    AIInterviewEvaluateResponse,
    AIInterviewQuestionRequest,
    AIInterviewQuestionResponse,
)
from app.services.ai_interview_service import (
    evaluate_interview_answer,
    generate_interview_question,
)


router = APIRouter()


@router.post(
    "/interview/ai/question",
    response_model=AIInterviewQuestionResponse,
)
def ai_interview_question(
    request: AIInterviewQuestionRequest,
):
    return generate_interview_question(request)


@router.post(
    "/interview/evaluate",
    response_model=AIInterviewEvaluateResponse,
)
def interview_evaluate(
    request: AIInterviewEvaluateRequest,
):
    return evaluate_interview_answer(request)
