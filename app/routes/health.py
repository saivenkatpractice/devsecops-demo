from fastapi import APIRouter

router = APIRouter(prefix="/health", tags=["health"])


@router.get("")
def health_check():
    return {"status": "healthy", "service": "devsecops-demo"}


@router.get("/ready")
def readiness_check():
    return {"status": "ready"}
