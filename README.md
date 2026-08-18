# postgres-backup-s3

Tiny container that dumps a Postgres database, encrypts the dump with
[age](https://age-encryption.org), and pushes it to any S3-compatible bucket on
a cron schedule.

One container per database. Same image, different env vars.

## How it works

`supercronic` runs `backup.sh` on the schedule you set. Each run streams
`pg_dump | age | rclone rcat` straight into S3. Nothing ever hits local disk.

If `BACKUP_KEEP_DAYS` is set, old objects under your prefix are pruned after
each successful upload.

Encryption uses age with an asymmetric key. Only the public key lives on the
backup box. The private key stays offline. A compromised backup container
cannot read anything it wrote.

## First-time setup

1. Generate an age keypair on a trusted machine:

   ```sh
   age-keygen -o age.key
   ```

   The file starts with a comment line containing the `age1...` public key.
   Copy that string into `AGE_PUBLIC_KEY`.

2. Back the private key up somewhere safe and offline. A password manager entry
   plus a printed copy in a drawer is a good baseline. Lose the private key and
   every backup ever taken is unreadable.

3. Set the Postgres major version in the Dockerfile to match your server
   (`ARG PG_VERSION=17`). Restore needs a matching or newer server.

## Deploy to CapRover

Every push to `main` builds a multi-arch image and pushes it to GHCR as
`ghcr.io/<owner>/<repo>:latest` (plus a short-sha tag, and on git tags the tag
name). See `.github/workflows/build.yml`.

Create one CapRover app per database. For each app:

- Deployment method: "Deploy via ImageName"
- Image: `ghcr.io/wout/postgres-backup-s3:latest` (or pin a sha/tag)
- Set env vars from `.env.example`
- Keep `S3_PATH` unique per app (for example `project/staging`,
  `project/production`) so their backups do not mingle

To auto-redeploy every app on a new image push, copy each app's webhook URL
from CapRover, comma-join them into a repo secret named `CAPROVER_WEBHOOKS`,
and uncomment the `notify` job in the workflow.

## Deploy with docker-compose

For local testing:

```sh
cp .env.example .env  # fill it in
docker compose up --build
```

## Restore

The container ships with `restore.sh`. It is manual on purpose. Mount your age
private key into the container, then:

```sh
docker exec -it <container> \
  env AGE_IDENTITY_FILE=/run/secrets/age.key \
  restore.sh 2026/08/17/120000Z.dump.age
```

The script prompts for confirmation before writing. It runs `pg_restore --clean
--if-exists`, so every object in the target database gets dropped and
recreated. Point it at a scratch database the first time.

## Files

- `Dockerfile`: base image, pins PG major and supercronic version
- `entrypoint.sh`: validates env, configures rclone, runs cron
- `backup.sh`: the dump + encrypt + upload pipeline
- `restore.sh`: manual restore helper
- `captain-definition`: CapRover build manifest
- `docker-compose.yml`: local testing
- `.env.example`: all supported env vars

## Env vars

See `.env.example` for the full list with defaults. The required ones:

- `DATABASE_URL`
- `AGE_PUBLIC_KEY`
- `S3_ENDPOINT`
- `S3_BUCKET`
- `S3_ACCESS_KEY_ID`
- `S3_SECRET_ACCESS_KEY`

`BACKUP_SCHEDULE` defaults to hourly on the hour, UTC.

## Restore drill

Do one now. Not the day you need it. Point `restore.sh` at a throwaway database
and confirm the dump round-trips.
