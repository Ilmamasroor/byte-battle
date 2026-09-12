from fastapi import APIRouter

from app.models.interview_models import InterviewQuestionRequest, InterviewEvaluateRequest
from app.services.interview_service import generate_interview_question, evaluate_interview_answer

router = APIRouter()


@router.post("/interview/question")
def interview_question(data: InterviewQuestionRequest):
    try:
        return generate_interview_question(data)

    except Exception as e:
        print("INTERVIEW QUESTION ERROR:", repr(e))
        return {
            "error": "AI service temporarily unavailable",
            "details": str(e)
        }


@router.post("/interview/evaluate")
def interview_evaluate(data: InterviewEvaluateRequest):
    try:
        return evaluate_interview_answer(data)

    except Exception as e:
        print("INTERVIEW EVALUATION ERROR:", repr(e))
        return {
            "error": "AI service temporarily unavailable",
            "details": str(e)
        }
