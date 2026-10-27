# Judge0 for Byte Battle

Judge0 CE 1.13.1 runs learner code in an isolated sandbox. The Spring backend talks to it over HTTP
(`bytebattle.judge0.*`, see `../docs/running-locally.md`).

## Start

```bash
cd judge0
cp .env.example .env          # then fill in the four values (strong random strings)
openssl rand -hex 24          # e.g. one per value
docker compose config -q      # validates the file and that every secret is set (legacy: docker-compose config -q)
docker compose up -d
curl -H "X-Auth-Token: $JUDGE0_AUTHN_TOKEN" http://127.0.0.1:2358/system_info
```

The backend then needs `JUDGE0_BASE_URL=http://localhost:2358` and `JUDGE0_AUTH_TOKEN=<same value as JUDGE0_AUTHN_TOKEN>`.

## Capacity

Judge0 compiles each test case as its own submission and runs them in parallel (`COUNT` workers), so a 5-case Java
challenge means 5 simultaneous `javac` runs. The workers get `JUDGE0_WORKER_CPUS` (default 4.0) and
`JUDGE0_WORKER_MEMORY` (default 4g) from `.env`; keep the CPU value at or below the host's core count. Too little CPU
shows up as "Compilation time limit exceeded". With legacy `docker-compose` v1, recreate a changed service with
`docker-compose rm -sf workers && docker-compose up -d workers` (a plain `up -d` can crash with `KeyError: 'ContainerConfig'`).

## Secrets

* `docker-compose.yml` reads `JUDGE0_DB_PASSWORD`, `JUDGE0_REDIS_PASSWORD`, `JUDGE0_AUTHN_TOKEN` and
  `JUDGE0_SECRET_KEY_BASE` from `.env` (git-ignored) and passes them to the containers as environment variables
  (`POSTGRES_PASSWORD`, `REDIS_PASSWORD`, `AUTHN_TOKEN`, `SECRET_KEY_BASE`).
* `judge0.conf` contains **no secrets**: those keys are commented out in it. Compose cannot substitute variables
  inside `judge0.conf`, so never paste real secrets into it; keep them in `.env`.
* `judge0.conf.example` is a copy of the committed defaults for reference.
* If an older checkout of this directory ever had real passwords in `docker-compose.yml` or `judge0.conf`
  (`POSTGRES_PASSWORD`, `REDIS_PASSWORD`), treat them as leaked and rotate them. Wipe the old database volume
  (`docker compose down -v`) when changing the Postgres password.

## Hardening applied

* Server published on `127.0.0.1:2358` only; the database has no host port mapping.
* Healthchecks for Postgres and Redis, and `depends_on: condition: service_healthy`.
* Memory and CPU limits on every service.
* Judge0 limits (`judge0.conf`): CPU 5 s (max 15 s), wall 10 s (max 20 s), memory 256 MB (max 512 MB),
  60 processes/threads (enough for multithreaded Java), network disabled and not allowable, one run per submission,
  batch submissions enabled (the backend submits one batch per challenge), queue capped at 200.
* The `privileged: true` setting is required by Judge0's `isolate` sandbox; do not expose the port publicly.
