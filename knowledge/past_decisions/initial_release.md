# Initial v3 release: plan

The one-time switchover from v1 to v3. Infrastructure is in `[[infra_plan]]`, deploys in `[[versioning_plan]]`.

## Starting point

- v1 server runs on the VPS behind `play-intellector.ru:8443`, with a Let's Encrypt certificate renewed by
  a certbot setup nobody remembers.
- v1 frontend is on Hostland shared hosting (`intellector.info`), uploaded over FTP into
  `htdocs/www/game` (previous build in `exgame`).
- v1 data lives in `/root/{player,game,study,logs,other}` on the VPS; `backup.bat` / `backup_light.py`
  pull it into dated Yandex Disk folders, which is where the migrator's prompt looks.
- No v3 prod database exists. v1 data is files: `game/<id>`, `player/<login>` (JSON), `study/<id>` (JSON),
  `other/passwords.json`, `logs/antifraud.txt`. `migrator.py` turns them into v3 rows, together with
  `old_games_datetimes.csv` and `first_messages.csv` from the server repo root.

## Approach: migrate on the PC, ship a dump

The migrator runs on the developer's PC against a fresh local DB, not on the VPS. The result is checked
locally, dumped, and loaded on the VPS through the ordinary restore path. Reasons:

- It can be rehearsed any number of times on recent v1 backups before release day, with timings known.
- The VPS never needs the migrator's dependencies or the CPU/RAM for its `ProcessPoolExecutor`.
- Release day exercises `restore.sh` for real.

## Migrator facts

- Tables must exist before it runs: `alembic upgrade head` on the empty DB first (the server's startup `create_all` is
  gone). The log tables are in `intellector_logs`, which must exist too.
- Not idempotent: a failed run means drop the database, recreate it, upgrade, rerun.
- Order inside is fixed by foreign keys: games → players, passwords, follows → studies → antifraud.
- Game 5524 is skipped on purpose.
- The guest id counter needs no migration step: the server derives it on startup (`last_guest_id.sql`).
- Duplicate sibling plies in v1 studies get merged, and illegal plies repaired or removed, each change printed as
  `Study <id>: ...`; review them after the
  final run, as v1 can still produce more.
- Run it with `STAGE=test`, which is required and selects the prompt for a backup folder. `STAGE=prod` reads the
  backup from the current directory instead.
- The prompt branch imports `prompt_toolkit`, which isn't in `requirements.txt`.

## Findings from the infra work (2026-11-04)

- **A Windows copy of the v1 data loses players.** `player/` has case-colliding files (`Divan`/`divan`, `Groot`,
  `Leo169`/`leo169`, `KatziRina`/`katzirina`, `PaulNotIntellector`/`paulnotintellector`), so `backup_light.py` into Yandex Disk
  and the migrator on Windows see 1289 of 1293. The exact copy is `v1/v1-data-2026-11-04.tar.zst` in the B2 bucket (made on
  the VPS); on release day take the final one the same way (`tar | zstd | rclone rcat`), and decide how the migrator treats
  the colliding pairs before the rehearsal.
- `backup_light.py` has a bug: if today's folder already holds a partial `game/`, it picks it as the "previous" backup and
  crashes copying it onto itself. Run it once per day, or exclude today's folder.
- Port 8000 on the VPS is v1's `webserver.py`, port 5000 is v1's server; 80 and 443 are free (certbot uses standalone mode).
- Caddy is installed but disabled; `systemctl enable --now caddy` is a release-day step, after certbot's timer is disabled.
- On release day also: `bootstrap.sh --firewall --harden-ssh`, `admin.env`, an `ADMIN` account in the restored DB, the
  alert channel, and `systemctl start intellector.target` (or `deploy.py`).

## Before release day

1. Infra done and rehearsed in WSL2 (`[[infra_plan]]` order of work, steps 1-4).
2. Find out the current certbot setup:
   - `sudo certbot certificates` (domains, expiry, paths);
   - `/etc/letsencrypt/renewal/<domain>.conf` (`authenticator`: standalone / webroot / nginx / apache,
     and any deploy hook that restarts the v1 server);
   - `systemctl list-timers | grep -i certbot`, `sudo crontab -l`, `/etc/cron.d/`;
   - `sudo ss -tlnp` (what listens on 80, 443, 8443).
3. `bootstrap.sh` on the VPS: MySQL, Caddy installed but Caddy **not started** if anything already holds
   port 80 or 443. v1 keeps running untouched.
4. Full rehearsal on the PC with the latest v1 backup: fresh DB, `alembic upgrade head`, migrator,
   checks (below), dump. Note how long it takes.
5. Optional side-by-side test: if 80/443 are free, start Caddy and the v3 server on the VPS with the
   rehearsal dump and point a debug frontend build at it, while v1 keeps serving `:8443`.
6. Announce the maintenance window.

## Release day

1. Drain v1 (admin stop), wait for ongoing games, stop it, disable its autostart.
2. Pull the final v1 data with `backup_light.py`. Keep this copy forever, offsite (it's the last v1 state).
3. On the PC: fresh DB, `alembic upgrade head`, migrator, checks, `mysqldump | zstd`.
4. Upload the dump, `restore.sh` it into the empty prod DB.
5. Retire certbot: disable its timer / cron entry, stop whatever held 80/443. Start Caddy; confirm it
   obtained the certificate (`journalctl -u caddy`).
6. Start the v3 server (`ExecStartPre` migrations are a no-op).
7. Take the first backup immediately (`ictl backup`) and confirm the restore-test timer is armed.
8. Upload the v3 frontend to the static hosting (first `deploy.py` run). Its production address, set in `index.html`, is
   `https://play-intellector.ru` (port 443), no longer `:8443`.
9. Smoke test (below). Then announce.

## Checks after migration

- Row counts against file counts: games (minus 5524), players, studies.
- A few known players: log in with their old password works, Elo and game count look right, follows
  are present.
- A few known games open, replay to the end, have correct results and time controls.
- A few studies open with their trees intact.
- The v3 server starts against the DB locally and the home page lists recent games.

## Rollback

Until the first game is played on v3, rollback is: stop v3 and Caddy, re-enable certbot and v1,
restore the v1 frontend. After that, games played on v3 would be lost by rolling back; fix forward instead.

## Afterwards

- Delete the v1 certificate (`certbot delete --cert-name ...`) and uninstall certbot once Caddy has
  renewed at least once.
- Remove v1 server files from the VPS after a few weeks; the final data copy from step 2 remains.
- On the static hosting, delete `exgame/`, the `deprecated_*` folders and `tools/gen` (no longer used).

## Static hosting placement

v3 stays at `intellector.info/game/`, with `/v/<api>/` inside `game/` (replacing v1's `game/` +
`exgame/` rotation). v3's router uses the same `<pathname>?p=<page path>` form as v1, so old
`intellector.info/game/?p=...` links keep resolving, as far as v1 page paths (`live/<id>`, `join/<id>`,
`study/<id>`, ...) still exist in v3.
