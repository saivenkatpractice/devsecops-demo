from fastapi import FastAPI
from app.routes.health import router as health_router

app = FastAPI(
    title="DevSecOps Demo API",
    description="A demo app for learning DevSecOps with GitHub Actions",
    version="1.0.0",
)

app.include_router(health_router)


@app.get("/")
def root():
    return {"message": "DevSecOps Demo API is running", "version": "1.0.0"}

def badly_formatted(x,y,z):
    a=1+2
    return x+y+z+a