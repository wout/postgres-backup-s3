#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?required}"
: "${AGE_PUBLIC_KEY:?required}"
: "${S3_BUCKET:?required}"
: "${S3_PATH:=}"

log() { printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*"; }

now=$(date -u +%Y/%m/%d/%H%M%SZ)
prefix="${S3_PATH:+${S3_PATH%/}/}"
object="${prefix}${now}.dump.age"
remote="s3:${S3_BUCKET}/${object}"

log "backup start -> ${remote}"

pg_dump --format=custom --no-owner --no-acl --compress=9 "$DATABASE_URL" |
  age --recipient "$AGE_PUBLIC_KEY" |
  rclone rcat --s3-no-check-bucket "$remote"

log "backup done"

if [[ -n "${BACKUP_KEEP_DAYS:-}" ]]; then
  log "pruning objects older than ${BACKUP_KEEP_DAYS}d under ${prefix:-<root>}"
  rclone delete \
    --min-age "${BACKUP_KEEP_DAYS}d" \
    --s3-no-check-bucket \
    "s3:${S3_BUCKET}/${prefix}"
fi
