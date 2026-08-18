#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?required}"
: "${AGE_PUBLIC_KEY:?required}"
: "${S3_BUCKET:?required}"
: "${S3_PATH:=}"

source /usr/local/bin/rclone-env.sh

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

hourly_days="${BACKUP_KEEP_HOURLY_DAYS:-3}"
daily_days="${BACKUP_KEEP_DAILY_DAYS:-30}"

if ((daily_days <= hourly_days)); then
  log "BACKUP_KEEP_DAILY_DAYS must exceed BACKUP_KEEP_HOURLY_DAYS" >&2
  exit 1
fi

log "thinning to one/day between ${hourly_days}d and ${daily_days}d"
mapfile -t candidates < <(
  rclone lsf --files-only --recursive --s3-no-check-bucket \
    --min-age "${hourly_days}d" --max-age "${daily_days}d" \
    "s3:${S3_BUCKET}/${prefix}" | sort
)
declare -A newest_per_day
for path in "${candidates[@]}"; do
  newest_per_day["${path%/*}/"]="$path"
done
for path in "${candidates[@]}"; do
  day="${path%/*}/"
  [[ "$path" == "${newest_per_day[$day]}" ]] && continue
  rclone deletefile --s3-no-check-bucket \
    "s3:${S3_BUCKET}/${prefix}${path}"
done

log "pruning objects older than ${daily_days}d"
rclone delete \
  --min-age "${daily_days}d" \
  --s3-no-check-bucket \
  "s3:${S3_BUCKET}/${prefix}"
