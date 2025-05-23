FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY openwebui2loki.py .

CMD ["python", "openwebui2loki.py", "--db", "${DB_PATH}", "--audit-log", "${AUDIT_LOG_PATH}", "--loki-url", "${LOKI_URL}", "--interval", "${INTERVAL}", "--batch-size", "${BATCH_SIZE}"]