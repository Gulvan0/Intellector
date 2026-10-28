# Server infrastructure: plan

How the v3 server runs on the VPS and how releases get there: process management, TLS, schema
migrations, deploys, backups, log retention, monitoring, and what of it exists on the developer's PC.
Code-level versioning logic is in `[[versioning_plan]]`; the one-time v1 → v3 switchover is in
`[[initial_release_plan]]`.

Deferred until v3 coding is done.

## Current state (v1)

From the old scripts in `C:/Users/mitmi/Documents/GitHub/scripts`:

- **VPS** (Hostland): SSH as `root` with a password (PuTTY `pscp`). The server binary and its config are
  copied to `/root`, then stopped via the admin panel and restarted by whatever runs it there. Data lives
  in `/root/{player,game,study,logs,other}`. The TLS certificate comes from
  `/etc/letsencrypt/live/play-intellector.ru/`.
- **Static hosting** (Hostland shared hosting, `intellector.info`): plain FTP via WinSCP scripting, into
  `htdocs/www/game`, with the previous build rotated to `exgame` and older ones to `deprecated_<ts>`.
- **Backups**: manual, `backup.bat` / `backup_light.py` pull the data folders over SSH into Yandex Disk.
- Credentials are written inside the scripts.

## Decisions

- **One Linux VPS, plain systemd, no Docker.** Releases deploy by draining: the old server finishes
  ongoing games, exits, and systemd starts the new release from a `current` symlink. Docker restarts a
  container with its old image, so draining would need a waiter outside Docker anyway.
- **The VPS serves the API only**, at `https://play-intellector.ru` (standard port 443; some networks
  block non-standard ports). The static frontend stays on its hosting.
- **Caddy** terminates TLS and renews certificates itself; certbot is retired.
- **Uvicorn** replaces Hypercorn. Caddy talks HTTP/2-3 to browsers, so the app server only needs HTTP/1.1
  and WebSockets on loopback. The server is single-process by necessity (`mutable_state` lives in memory),
  so throughput-oriented alternatives (Granian, Gunicorn workers) buy nothing.
- **Alembic** owns the schema; `SQLModel.metadata.create_all` is removed from startup.
- **Nothing offsite is deleted automatically.** DB dumps and log archives accumulate; old objects are
  deleted by hand, if ever. Since automation never deletes, the VPS's storage key gets no delete right
  where the provider allows it (least privilege: a compromised VPS can't wipe the backups).
- **Log tables keep 7 days** in MySQL; older days are archived offsite as compressed CSV, kept forever,
  and purged. Log tables are not backed up.
- **Infra lives in the server repo**, under `infra/`.

## Components

| Unit | Notes |
|---|---|
| `caddy` | official apt repo; only proxies the API |
| `mysql` | 8.4 LTS from MySQL's apt repo, pinned to 8.4; `bind-address = 127.0.0.1` |
| `intellector-server` | Uvicorn on `127.0.0.1:8000`, run from `/srv/intellector/server/current`, `Restart=always` |
| `intellector-bot` | later; same pattern as the server |
| `intellector-backup` (timer, nightly) | DB dump uploaded offsite |
| `intellector-restore-test` (timer, weekly) | restores the latest dump into a scratch DB and sanity-checks it |
| `intellector-log-archive` (timer, daily) | exports, uploads and purges log days older than 7 |
| `intellector-watchdog` (timer, every minute) | `/health`; restarts the server after 3 consecutive failures |
| `intellector-alert@` | template; every unit above has `OnFailure=intellector-alert@%n`, which messages the Telegram admin chat from `secret.yaml` |

Firewall: 22, 80, 443 only (80 for ACME challenges and the HTTPS redirect).

## Access and credentials

- SSH by key only; a non-root `intellector` user owns `/srv/intellector` and may run the few `systemctl`
  commands deploys need via sudoers. Password login and root login are disabled once the key works.
  The root password that sat in the old scripts is changed.
- FTP to the static hosting over FTPS if Hostland offers it.
- No credentials in scripts or in git: the deploy script reads an untracked env file on the PC; the VPS
  has its own `.env`. Both are also kept in the password manager.

## `infra/` layout

```
infra/
  systemd/        intellector.target and every unit/timer above
  caddy/Caddyfile
  mysql/intellector.cnf     bind-address, binlog_expire_logs_seconds, buffer pool sized to the VPS RAM
  scripts/        backup.sh restore.sh healthcheck.sh alert.sh
  bootstrap.sh    once per fresh VPS: apt packages and repos, firewall, users, folders, SSH hardening
  apply.sh        idempotent: copies configs into place, daemon-reload, enables units, reloads Caddy;
                  --check prints drift without changing anything
  ictl            operator CLI (below)
  deploy.py       run from the PC (below)
  .env.example
```

Files on the VPS are never edited by hand; `apply.sh` overwrites them from the repo.

Every own unit carries `PartOf=intellector.target` and `WantedBy=intellector.target`, so the whole set
starts and stops as one. The server unit also has `Requires=mysql.service`, `After=mysql.service`.

`ictl`: `status` (units, timers' next/last runs, `/health`), `logs [unit] [-f]` (journald, all units
merged by default), `start` / `stop` (the target), `restart <unit>`, `backup`, `restore <dump> [db]`,
`releases`, `rollback`, `apply`.

journald caps log size (`SystemMaxUse=`); nothing else rotates logs.

## Deploy (`deploy.py`, one command from the PC)

Python rather than bash or `.bat`: it runs the same on Windows, uses `ftplib` for the static hosting and
the built-in Windows OpenSSH (`ssh`/`scp`) for the VPS.

1. Build client and server; read `{build, api}` from `bin/version.json`; run the `api.lock` check,
   `alembic check`, `alembic heads` (exactly one) and `caddy validate`.
2. Upload the client to `htdocs/www/game/v/<api>.tmp/`, then rename into `game/v/<api>/` (replacing a
   same-API folder); prune all but the newest few `game/v/*` folders. Upload the shell files
   (`index.html`, `sw.js`, `manifest.json`, `.htaccess`) into `game/` when they changed.
3. If `infra/` changed: copy it and run `apply.sh`.
4. If the server code changed since the last deploy: upload it into a new release folder, build its venv,
   repoint `current`, then trigger the drain (`/shutdown` with the admin token).
5. Return. The rest is unattended: the drained server exits, systemd starts `current`, `ExecStartPre`
   backs up and migrates, clients converge (`[[versioning_plan]]` §9). Repeated deploys during a drain
   just move `current` again.

`ictl rollback` repoints `current` to the previous release and drains.

## Caddy

```
play-intellector.ru {
    reverse_proxy 127.0.0.1:8000
}
```

WebSockets need no extra config. A Caddy config reload closes open WebSockets; clients reconnect.
Caddy reloads happen only on Caddyfile changes.

## App server (Uvicorn)

- **Prod:** one `uvicorn.Server` on `127.0.0.1:8000`, `proxy_headers=True`,
  `forwarded_allow_ips="127.0.0.1"` (so `client_host` in logs is the real client, not Caddy).
- **Test:** two servers in one loop via `asyncio.gather`: TLS on 8443 (mkcert files from
  `SecretConfig.ssl`) and plain HTTP on 8080 with `lifespan="off"` (replaces the `_plain_http_app`
  wrapper). Verify one Ctrl+C stops both.
- `SecretConfig.ssl` becomes optional; set only for `test`.
- The Python 3.14 `StreamWriter.wait_closed` monkey patch is removed (it targets a Hypercorn race).
- Drain completion sets `should_exit` on the running server(s).
- `create_async_engine(..., pool_pre_ping=True)` so a MySQL restart doesn't leave dead pooled connections.
- `GET /health`: runs `SELECT 1`; stays healthy while draining.
- requirements: `uvicorn[standard]` (uvloop is Linux-only; if pip fails on Windows, use a
  `sys_platform != "win32"` marker), `alembic`; drop `hypercorn`.

## Alembic

- `alembic init` in the server repo. `env.py`: `target_metadata = SQLModel.metadata` with every model
  module imported; URL from `SecretConfig` with the sync `pymysql` driver; `compare_type=True`.
  `script.py.mako` imports `sqlmodel` (autogenerated scripts reference `sqlmodel.sql.sqltypes.AutoString`).
- Baseline: one initial revision generated from the current models. The local test DB is checked with
  `alembic check` and then `alembic stamp head`. The prod DB is born from `alembic upgrade head`.
- Migrations run in the server unit, before the app starts, so they happen when the new release first
  starts after a drain:
  ```
  ExecStartPre=/srv/intellector/infra/scripts/backup.sh --if-pending-migrations
  ExecStartPre=/srv/intellector/server/current/venv/bin/alembic upgrade head
  ```
  A failing migration trips `StartLimitBurst` and the alert.
- Rules: review every autogenerated script (renames come out as drop + add); one change per revision;
  MySQL DDL is not transactional, hence the pre-migration backup; prefer additive changes, since the
  draining old release keeps running against the same schema.

## Backups

- Nightly `mysqldump --single-transaction --quick --routines --triggers --events` of the main database,
  piped through `zstd` and uploaded with rclone as `db/<YYYY-MM-DD>.sql.zst`. Pre-migration dumps are
  `db/pre-deploy-<YYYY-MM-DD-HHMM>-<sha>.sql.zst`, tying a dump to its code.
- Plain dated files instead of restic: manual management means browsing and deleting dumps in the
  provider's web UI, which restic's opaque repository doesn't allow (its snapshots are removed only via
  `restic forget`). restic would also need delete rights for its lock files. The cost is no
  deduplication: storage grows by one full compressed dump per day, small at this DB size. Dumps are not encrypted; they contain password hashes, so the bucket stays
  private.
- Dump user: read-only (`SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES`), credentials in an option file.
- The backup pings a dead man's switch (healthchecks.io) on success; an external uptime monitor watches
  `/health`.

## Log retention

- Per log table, per whole day older than 7 days still present: export to
  `logs/<table>/<YYYY-MM-DD>.csv.zst`, upload with rclone and verify, then delete the day in batches
  (`LIMIT 5000` loop). Missed days are caught up on the next run. Kept forever, not encrypted.
- Written in Python in the server repo (e.g. `src/jobs/log_archive.py`), reusing config and models.
- Schema changes it needs (first real migrations): indexes on `ts` / `event_time`; `RESTResponseLog`
  merged into the request row (it has no timestamp of its own).
- Log tables move to a separate `intellector_logs` database (Alembic `include_schemas=True`), so a
  restore of the main database never wipes the last week of logs and backups need no exclusion list.
- `binlog_expire_logs_seconds` ≈ 2 days (MySQL's default keeps 30).
- After the first purge, `OPTIMIZE TABLE` once per log table to return the space.

## Restore

`restore.sh <dump> [target_db]` wraps: `rclone cat remote:<bucket>/db/<dump> | zstd -d | mysql <db>`.

1. **Bad data, server alive:** `systemctl stop intellector-server`; drop and recreate the database;
   load the dump; deploy the dump's `sha` (pre-deploy dumps) or fix forward (`alembic upgrade` runs on
   start). Everything after the dump is lost; games in progress are cut.
2. **VPS lost:** `bootstrap.sh`, clone, `.env` from the password manager, `apply.sh`, load the latest
   dump into the empty DB, repoint DNS, start. Caddy issues fresh certificates.
3. **Some rows:** load the dump into `intellector_restore`, `INSERT ... SELECT` across databases
   parents first, drop the scratch DB. The site stays up.
4. **An archived log day:** `rclone copy`, `zstd -d`, then DuckDB on the CSV or `LOAD DATA LOCAL INFILE`.

The restore-test unit needs read access: it uses a separate read-only key. Case 2 is rehearsed once in
WSL2 after setup.

## Test stage on the developer's PC (`STAGE=test`)

| Part | Locally |
|---|---|
| App server | TLS 8443 + plain 8080, no proxy headers |
| Frontend | Live Server on `127.0.0.1:5500` |
| Caddy | not run; deploy runs `caddy validate` on the Caddyfile |
| MySQL | existing local install |
| Alembic | same as prod, run by hand (`upgrade head` / `downgrade -1`) |
| Migration rehearsal | load the latest prod dump into a local scratch DB, `alembic upgrade head` on it before risky deploys |
| Backups | none |
| Log archive job | target is a local folder, retention overridable to 0 days |
| Alerts | off |
| systemd units, timers, drain restart, `bootstrap.sh`, `deploy.py` | WSL2 Ubuntu with systemd, as a rehearsal VPS, before the first real use |
| Drain logic | testable locally: `/shutdown`, finish a game, the process exits cleanly |

## Order of work

1. Server code: Uvicorn, optional SSL, proxy headers, `pool_pre_ping`, `/health`, requirements.
2. Alembic: setup, baseline, `create_all` removed, log-table migrations.
3. Log archive job.
4. `infra/` and `deploy.py`, rehearsed in WSL2.
5. Initial release (`[[initial_release_plan]]`).

## Open questions

- Offsite storage provider. Leaning to **Backblaze B2**: first 10 GB free, then $6/TB/month; application
  keys take per-capability rights (`listBuckets, listFiles, readFiles, writeFiles` without
  `deleteFiles`), which gives the VPS key no delete right; a different provider and jurisdiction than the
  Russian VPS. Before committing, upload a test file from the VPS with rclone, since traffic from Russia
  to foreign services is sometimes throttled. Cloudflare R2 is out: its tokens can't separate write from
  delete, and Cloudflare is throttled in Russia. Fallback if B2 is unreachable from the VPS: Yandex
  Object Storage or Selectel.
- The VPS's OS and RAM (`cat /etc/os-release`, `free -h`): the plan assumes Debian/Ubuntu with systemd;
  RAM sizes MySQL's buffer pool.
- Whether Hostland's shared hosting supports FTPS.
