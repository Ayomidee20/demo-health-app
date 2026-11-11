FROM python:3.12-slim

WORKDIR /app

# Pick up Debian security fixes released since the base image was published
# (Trivy fails the build on fixed HIGH/CRITICAL CVEs, e.g. zlib1g).
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Install only the runtime dependencies (no pytest/flake8/scanners in prod).
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

# Baked in by the pipeline (--build-arg COMMIT_SHA=...) and returned by
# /healthcheck, so the deploy can prove the new version is the one running.
ARG COMMIT_SHA=unknown
ENV COMMIT_SHA=${COMMIT_SHA}

# Don't run as root inside the container.
RUN useradd --create-home --uid 10001 appuser
USER appuser

EXPOSE 3000

CMD ["gunicorn", "--bind", "0.0.0.0:3000", "--workers", "2", "app.app:app"]
