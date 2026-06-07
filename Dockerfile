# ── Stage 1: Builder ──────────────────────────────────────────────────────────
# Alpine uses musl libc instead of glibc.
# It ships NO perl, NO ncurses by default — eliminating those CVE families entirely.
FROM python:3.11-alpine AS builder

WORKDIR /app

# Alpine needs gcc + musl-dev to compile some Python C extensions (like uvloop)
RUN apk add --no-cache gcc musl-dev libffi-dev

COPY requirements.txt .

RUN pip install --upgrade pip setuptools==82.0.1 wheel && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt


# ── Stage 2: Final image ──────────────────────────────────────────────────────
FROM python:3.11-alpine

# Update all Alpine packages to their latest patched versions
RUN apk update && apk upgrade && rm -rf /var/cache/apk/*

# Create non-root user (Alpine uses addgroup/adduser differently from Debian)
RUN addgroup -S appuser && adduser -S -G appuser appuser

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