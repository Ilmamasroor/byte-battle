import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.routes import explain_routes
from app.routes import byte_dna_routes
from app.routes import diagnosis_routes
from app.routes import recommendation_routes
from app.routes import byte_dna_evolution_routes
from app.routes import interview_routes
from app.routes import analogy_routes
from app.routes import battle_hint_routes
from app.routes import boss_battle_routes
from app.routes import canonical_knowledge_routes
from app.routes import coding_feedback_routes
from app.routes import debugging_routes
from app.routes import mnemonic_routes
from app.routes import ai_interview_routes
from fastapi.responses import JSONResponse
from app.core.exceptions import AI_INTERNAL_ERROR, AIServiceError


logger = logging.getLogger(__name__)


app = FastAPI(title="Byte Battle AI Service")

@app.exception_handler(AIServiceError)
async def ai_service_error_handler(request: Request, exc: AIServiceError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"code": exc.code, "message": exc.message},
    )


@app.exception_handler(RequestValidationError)
async def validation_error_handler(
    request: Request,
    exc: RequestValidationError,
):
    errors = exc.errors()

    message = "; ".join(
        f"{'.'.join(str(loc) for loc in err.get('loc', []))}: "
        f"{err.get('msg', 'validation error')}"
        for err in errors
    ) or "Invalid request payload"

    return JSONResponse(
        status_code=422,
        content={
            "code": "VALIDATION_ERROR",
            "message": message,
        },
    )


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(
    request: Request,
    exc: StarletteHTTPException,
):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "code": "HTTP_ERROR",
            "message": str(exc.detail),
        },
    )


@app.exception_handler(Exception)
async def unexpected_error_handler(
    request: Request,
    exc: Exception,
):
    logger.exception(
        "Unexpected error on %s",
        request.url.path,
    )

    return JSONResponse(
        status_code=500,
        content={
            "code": AI_INTERNAL_ERROR,
            "message": "AI service could not process the request",
        },
    )

app.include_router(explain_routes.router)
app.include_router(byte_dna_routes.router)
app.include_router(diagnosis_routes.router)
app.include_router(recommendation_routes.router)
app.include_router(byte_dna_evolution_routes.router)
app.include_router(interview_routes.router)
app.include_router(ai_interview_routes.router)

app.include_router(analogy_routes.router)
app.include_router(battle_hint_routes.router)
app.include_router(boss_battle_routes.router)
app.include_router(canonical_knowledge_routes.router)
app.include_router(coding_feedback_routes.router)
app.include_router(debugging_routes.router)
app.include_router(mnemonic_routes.router)


@app.get("/")
def read_root():
    return {"status": "Byte Battle AI Service is running"}


@app.get("/health")
def health_check():
    return {"status": "ok"}
