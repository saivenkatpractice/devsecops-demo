# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM python:3.11-slim-bookworm AS builder

WORKDIR /app

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt


# ── Stage 2: Final image ──────────────────────────────────────────────────────
FROM python:3.11-slim-bookworm

# Apply all OS security patches — this is the key fix
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN addgroup --system appuser && adduser --system --ingroup appuser appuser

WORKDIR /app

COPY --from=builder /install /usr/local
COPY app/ ./app/

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]