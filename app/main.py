from fastapi import FastAPI

from app.routes import (
    explain_routes,
    byte_dna_routes,
    analogy_routes,
    mnemonic_routes,
    battle_hint_routes,
    coding_feedback_routes,
    debugging_routes,
    interview_routes,
    canonical_knowledge_routes,
    boss_battle_routes,
)

app = FastAPI(title="Byte Battle AI Service")


@app.get("/")
def home():
    return {
        "message": "Byte Battle AI Service is running"
    }


app.include_router(explain_routes.router)
app.include_router(byte_dna_routes.router)
app.include_router(analogy_routes.router)
app.include_router(mnemonic_routes.router)
app.include_router(battle_hint_routes.router)
app.include_router(coding_feedback_routes.router)
app.include_router(debugging_routes.router)
app.include_router(interview_routes.router)
app.include_router(canonical_knowledge_routes.router)
app.include_router(boss_battle_routes.router)

print("\n===== REGISTERED ROUTES =====")
for route in app.routes:
    path = getattr(route, "path", None)
    if path:
        print(path, getattr(route, "methods", ""))
print("=============================\n")