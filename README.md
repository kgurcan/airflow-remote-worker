# Airflow Remote Worker (KG5090)

Stateless worker-only image for consuming Celery tasks from the prod Airflow control plane. Designed to offload CPU-heavy tasks (e.g., `fetch_and_upsert_trades_batch`) to KG5090 while staying generic enough to run other tasks on the same queues.

## What it does
- Runs only the Airflow Celery worker process (no scheduler/webserver/db).
- Connects to the prod metadata DB and Celery broker/result backend.
- Pulls DAGs from a mounted read-only volume or synced repo.
- Listens on configurable queues; defaults to `massive_trades`.
- Concurrency is configurable so KG5090 can handle 128 parallel tasks while prod keeps its 64.

## Required environment
- `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` – prod metadata DB URI.
- `AIRFLOW__CELERY__BROKER_URL` – prod Celery broker URL.
- `AIRFLOW__CELERY__RESULT_BACKEND` – prod Celery result backend.
- `AIRFLOW__CORE__FERNET_KEY` – same as prod.
- Any DAG-specific secrets used at runtime (e.g., `MASSIVE_API_KEY`).

## Worker settings (tunable)
- `WORKER_QUEUES` (default: `massive_trades`)
- `WORKER_CONCURRENCY` (default: `128`)
- `WORKER_HOSTNAME` (default: `kg5090@%h`)
- `WORKER_AUTOSCALE` (optional, format `max,min`; overrides concurrency when set)
- `AIRFLOW_IMAGE` (default: `apache/airflow:2.8.0`; override to match prod)

## Quick start (docker run)
```bash
# Build (override AIRFLOW_IMAGE build-arg if needed)
docker build -t airflow-remote-worker --build-arg AIRFLOW_IMAGE=apache/airflow:2.8.0 .

# Run
docker run --rm \
  --name airflow-worker-kg5090 \
  --env-file .env \
  -v /path/to/dags:/opt/airflow/dags:ro \
  airflow-remote-worker
```

## Quick start (docker-compose)
```bash
docker-compose up -d airflow-worker
```

## Adjusting load split
- KG5090: set `WORKER_CONCURRENCY=128` (offload capacity).
- Prod: keep its worker(s) at `--concurrency 64` on `default,massive_trades`.
- Both consume the same `massive_trades` queue, so tasks run concurrently on both; if KG5090 is down, prod still drains the queue.

## Notes
- Keep Airflow version in sync with prod (`AIRFLOW_IMAGE`).
- DAGs must be identical to prod (mount the same repo/branch).
- No state is stored locally; stopping the container leaves no residue.
