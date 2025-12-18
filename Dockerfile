# Minimal worker-only image built on the official Airflow image.
# Override AIRFLOW_IMAGE at build time to match prod exactly.
ARG AIRFLOW_IMAGE=apache/airflow:2.8.0
FROM ${AIRFLOW_IMAGE}

# Copy the worker startup script
COPY start_worker.sh /entrypoint-start-worker.sh
RUN chmod +x /entrypoint-start-worker.sh

# Run as airflow user to match the base image expectations
USER airflow
ENTRYPOINT ["/entrypoint-start-worker.sh"]
