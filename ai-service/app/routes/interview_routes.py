from fastapi import APIRouter
from app.models.interview_models import InterviewQuestionRequest, InterviewQuestionResponse
from app.services.interview_service import select_question

router = APIRouter()

@router.post("/interview/question", response_model=InterviewQuestionResponse)
def get_interview_question(request: InterviewQuestionRequest):
    question = select_question(request.topic, request.difficulty, request.excludedIds)

    if question is None:
        return InterviewQuestionResponse(
            userId=request.userId,
            message="No more questions available for this topic and difficulty."
        )

    return InterviewQuestionResponse(
        userId=request.userId,
        questionId=question["id"],
        question=question["question"],
        difficulty=question["difficulty"],
        subCategory=question["subCategory"]
    )