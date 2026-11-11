FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN python -m pytest tests/ -v --tb=short

# ---------- production stage ----------
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir flask==3.1.0 gunicorn==23.0.0

COPY app/ ./app/

ARG COMMIT_SHA=unknown
ENV COMMIT_SHA=${COMMIT_SHA}

EXPOSE 3000

CMD ["gunicorn", "--bind", "0.0.0.0:3000", "--workers", "2", "app.app:app"]
