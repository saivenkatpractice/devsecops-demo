# ── Stage 1: Builder ──────────────────────────────────────────────────────────
# We use a "builder" stage to install deps separately from the final image.
# This keeps the final image small and avoids shipping build tools.
FROM python:3.11-slim AS builder

# Set working directory inside the container
WORKDIR /app

# Copy ONLY the requirements file first.
# Docker caches layers — if requirements.txt doesn't change,
# this expensive pip install step is skipped on future builds.
COPY requirements.txt .

# Install dependencies into a separate directory (/install)
# so we can copy just them into the final stage
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt


# ── Stage 2: Final image ──────────────────────────────────────────────────────
# Start fresh from the same slim base — no build artifacts, no cache
FROM python:3.11-slim

# Security best practice: never run as root inside a container
# Create a non-root user named "appuser"
RUN addgroup --system appuser && adduser --system --ingroup appuser appuser

WORKDIR /app

# Copy installed packages from builder stage
COPY --from=builder /install /usr/local

# Copy application source code
COPY app/ ./app/

# Give ownership to appuser
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Document which port the app listens on (informational — doesn't actually open it)
EXPOSE 8000

# Health check: Docker will ping /health every 30s
# If it fails 3 times, the container is marked "unhealthy"
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Start the FastAPI app with uvicorn
# --host 0.0.0.0 means "accept connections from outside the container"
# --port 8000 matches the EXPOSE above
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]