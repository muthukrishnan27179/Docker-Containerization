# ==============================================================================
# Multi-Stage Production Dockerfile for Web Application
# Stage 1: Build & Dependencies Compilation (Wheels)
# Stage 2: Lean Production Runtime Image (Non-Root User)
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Builder Stage
# ------------------------------------------------------------------------------
FROM python:3.11-slim AS builder

WORKDIR /build

# Install build-time dependencies (gcc, libpq-dev, build-essential)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        libpq-dev \
        build-essential && \
    rm -rf /var/lib/apt/lists/*

# Optimization: Copy requirements first to leverage Docker layer caching
COPY app/requirements.txt ./requirements.txt

# Pre-compile wheels for all dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip wheel --no-cache-dir --no-deps --wheel-dir /build/wheels -r requirements.txt

# ------------------------------------------------------------------------------
# Stage 2: Final Lean Production Runtime
# ------------------------------------------------------------------------------
FROM python:3.11-slim AS runtime

# Security & performance environment flags
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000 \
    APP_ENV=production \
    PYTHONPATH=/app/src

# Principle of Least Privilege: Create dedicated non-root user and group
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -s /bin/sh -d /app appuser

WORKDIR /app

# Install minimal runtime libraries (libpq5 for postgres, curl for healthcheck)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq5 \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Copy pre-compiled wheels from builder stage and install cleanly
COPY --from=builder /build/wheels /wheels
COPY --from=builder /build/requirements.txt .
RUN pip install --no-cache-dir /wheels/* && \
    rm -rf /wheels

# Copy application source code and templates with proper file ownership
COPY --chown=appuser:appgroup app/src/ /app/src/
COPY --chown=appuser:appgroup app/templates/ /app/templates/
COPY --chown=appuser:appgroup app/static/ /app/static/

# Prepare data directory for SQLite local fallback storage
RUN mkdir -p /app/data && chown -R appuser:appgroup /app/data

# Switch to the non-privileged user
USER appuser

# Document exposed application port
EXPOSE 5000

# Docker Healthcheck instruction
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/api/health || exit 1

# Production WSGI Server Entrypoint
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "4", "--access-logfile", "-", "--error-logfile", "-", "app:app"]
