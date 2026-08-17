#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?required}"
: "${AGE_PUBLIC_KEY:?required}"
: "${S3_BUCKET:?required}"
: "${S3_ENDPOINT:?required}"
: "${S3_ACCESS_KEY_ID:?required}"
: "${S3_SECRET_ACCESS_KEY:?required}"
: "${BACKUP_SCHEDULE:=0 * * * *}"

# rclone reads config from RCLONE_CONFIG_<REMOTE>_<KEY> env vars, so no config
# file needed. Remote name below is "s3".
export RCLONE_CONFIG_S3_TYPE=s3
export RCLONE_CONFIG_S3_PROVIDER="${S3_PROVIDER:-Other}"
export RCLONE_CONFIG_S3_ENDPOINT="$S3_ENDPOINT"
export RCLONE_CONFIG_S3_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID"
export RCLONE_CONFIG_S3_SECRET_ACCESS_KEY="$S3_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_S3_REGION="${S3_REGION:-us-east-1}"
export RCLONE_CONFIG_S3_ACL="${S3_ACL:-private}"

if [[ "${RUN_ON_START:-false}" == "true" ]]; then
  echo "RUN_ON_START=true; taking one backup before starting cron"
  /usr/local/bin/backup.sh
fi

crontab="/tmp/crontab"
printf '%s /usr/local/bin/backup.sh\n' "$BACKUP_SCHEDULE" >"$crontab"

echo "starting supercronic, schedule: ${BACKUP_SCHEDULE}"
exec supercronic "$crontab"
