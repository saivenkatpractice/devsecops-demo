# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM python:3.11-slim-trixie AS builder

WORKDIR /app

COPY requirements.txt .

RUN pip install --upgrade pip setuptools==82.0.1 wheel && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt


# ── Stage 2: Final image ──────────────────────────────────────────────────────
FROM python:3.11-slim-trixie

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN addgroup --system appuser && adduser --system --ingroup appuser appuser

WORKDIR /app

COPY --from=builder /install /usr/local

RUN pip install --upgrade pip setuptools==82.0.1 wheel --no-cache-dir

COPY app/ ./app/

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]