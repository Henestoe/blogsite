FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY . .

RUN python -m pip install --no-cache-dir . gunicorn \
    && useradd --create-home --uid 10001 appuser \
    && mkdir -p /app/instance \
    && chown appuser:appuser /app/instance

USER appuser

EXPOSE 8000

CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--access-logfile", "-", "flaskr:create_app()"]
