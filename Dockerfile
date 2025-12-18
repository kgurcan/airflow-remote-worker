# Minimal worker-only image built on the official Airflow image.
# Override AIRFLOW_IMAGE at build time to match prod exactly.
ARG AIRFLOW_IMAGE=apache/airflow:2.10.2-python3.11
FROM ${AIRFLOW_IMAGE}

# Install Celery provider and Redis backend
USER airflow
RUN pip install --no-cache-dir \
    apache-airflow-providers-celery \
    redis

# Switch to root to copy and set permissions
USER root
COPY start_worker.sh /entrypoint-start-worker.sh
RUN chmod +x /entrypoint-start-worker.sh

# Switch back to airflow user
USER airflow
ENTRYPOINT ["/entrypoint-start-worker.sh"]
