#!/usr/bin/env bash
set -euo pipefail

# Generic, stateless Airflow Celery worker starter.
# Reads queue and concurrency from env, defaults sized for KG5090 offload.

: "${WORKER_QUEUES:=massive_trades}"
: "${WORKER_CONCURRENCY:=128}"
: "${WORKER_HOSTNAME:=kg5090@%h}"
: "${WORKER_AUTOSCALE:=}"

# Allow overriding executor in case base image differs, but default to CeleryExecutor.
: "${AIRFLOW__CORE__EXECUTOR:=CeleryExecutor}"
export AIRFLOW__CORE__EXECUTOR

cmd=(airflow celery worker --queues "${WORKER_QUEUES}" --hostname "${WORKER_HOSTNAME}" --concurrency "${WORKER_CONCURRENCY}")

if [[ -n "${WORKER_AUTOSCALE}" ]]; then
  cmd+=(--autoscale "${WORKER_AUTOSCALE}")
fi

exec "${cmd[@]}"
