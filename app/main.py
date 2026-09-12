from fastapi import FastAPI

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


app = FastAPI(title="Byte Battle AI Service")


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
