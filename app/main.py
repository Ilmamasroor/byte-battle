from fastapi import FastAPI
from app.routes import explain_routes
from app.routes import byte_dna_routes
from app.routes import diagnosis_routes
from app.routes import recommendation_routes
from app.routes import byte_dna_evolution_routes
from app.routes import interview_routes


app = FastAPI()

app.include_router(explain_routes.router)
app.include_router(byte_dna_routes.router)
app.include_router(diagnosis_routes.router)
app.include_router(recommendation_routes.router)
app.include_router(byte_dna_evolution_routes.router)
app.include_router(interview_routes.router)

@app.get("/")
def read_root():
    return {"status": "Byte Battle AI Service is running"}

@app.get("/health")
def health_check():
    return {"status": "ok"}