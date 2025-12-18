# Airflow Remote Worker (KG5090)

Stateless Celery worker that connects to the Airflow control plane on kg-pc via Tailscale. Consumes tasks from the shared Railway Redis broker.

## Architecture

```
┌─────────────────────┐         ┌──────────────────┐         ┌─────────────────────┐
│      kg-pc          │         │  Railway Redis   │         │      kg5090         │
│  (control plane)    │         │    (broker)      │         │  (remote worker)    │
│                     │         │                  │         │                     │
│  Scheduler ─────────┼────────▶│  Task Queue  ────┼────────▶│  Celery Worker      │
│  Webserver          │  push   │                  │  pull   │                     │
│  Local Worker       │         └──────────────────┘         │                     │
│  Postgres ──────────┼─────────────────────────────────────▶│  (reads metadata)   │
│                     │              Tailscale               │                     │
└─────────────────────┘                                      └─────────────────────┘
```

## Prerequisites

1. **Tailscale** - Both kg-pc and kg5090 must be on the same Tailscale network
2. **Docker** - Docker Desktop on kg5090
3. **DAGs synced** - Clone `airflow-python-jobs` repo on kg5090

## Quick Start

```bash
# 1. Clone repos on kg5090
cd /c/Users/konur/Documents/fidget_repo
git clone https://github.com/kgurcan/airflow-python-jobs.git  # if not already cloned

# 2. Build and start the worker
cd airflow-remote-worker
docker-compose up -d --build

# 3. Check logs
docker logs -f airflow-worker-kg5090
```

## Configuration

### Environment Variables (.env)

| Variable | Description |
|----------|-------------|
| `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` | Postgres on kg-pc via Tailscale |
| `AIRFLOW__CELERY__BROKER_URL` | Railway Redis (DB index /1) |
| `AIRFLOW__CELERY__RESULT_BACKEND` | Same Postgres for results |
| `AIRFLOW__CORE__FERNET_KEY` | Must match kg-pc |
| `WORKER_QUEUES` | Queues to consume (default: `default`) |
| `WORKER_CONCURRENCY` | Parallel tasks (default: 8) |
| `WORKER_HOSTNAME` | Worker identifier |

### Volume Mounts

The worker needs read-only access to DAGs and jobs:
```yaml
volumes:
  - /c/Users/konur/Documents/fidget_repo/airflow-python-jobs/dags:/opt/airflow/dags:ro
  - /c/Users/konur/Documents/fidget_repo/airflow-python-jobs/jobs:/opt/airflow/jobs:ro
```

## Operations

### Start worker
```bash
docker-compose up -d
```

### Stop worker
```bash
docker-compose down
```

### View logs
```bash
docker logs -f airflow-worker-kg5090
```

### Rebuild after code changes
```bash
# Pull latest DAGs first
cd ../airflow-python-jobs && git pull
cd ../airflow-remote-worker
docker-compose up -d --build
```

## Monitoring

- **Flower UI** (on kg-pc): http://kg-pc.tail5c5268.ts.net:5555
- **Airflow UI** (on kg-pc): http://kg-pc.tail5c5268.ts.net:8080

## Troubleshooting

### Worker not receiving tasks
1. Check Redis connectivity: `docker exec airflow-worker-kg5090 python -c "import redis; r=redis.from_url('$AIRFLOW__CELERY__BROKER_URL'); print(r.ping())"`
2. Verify queues match: Worker must listen on same queue as scheduler sends to

### Database connection errors
1. Check Tailscale is connected: `tailscale status`
2. Verify Postgres is accessible: `pg_isready -h kg-pc.tail5c5268.ts.net -p 5432`

### DAG import errors
1. Ensure DAGs are synced: `cd ../airflow-python-jobs && git pull`
2. Check volume mounts in docker-compose.yml

## Notes

- Keep DAGs identical to kg-pc (same git branch)
- Airflow version must match (currently 2.10.2)
- No state stored locally - safe to stop/start anytime
