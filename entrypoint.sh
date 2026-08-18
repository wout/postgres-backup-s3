#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?required}"
: "${AGE_PUBLIC_KEY:?required}"
: "${S3_BUCKET:?required}"
: "${S3_ENDPOINT:?required}"
: "${S3_ACCESS_KEY_ID:?required}"
: "${S3_SECRET_ACCESS_KEY:?required}"
: "${BACKUP_SCHEDULE:=0 * * * *}"

# shellcheck source=rclone-env.sh
source /usr/local/bin/rclone-env.sh

if [[ "${RUN_ON_START:-false}" == "true" ]]; then
  echo "RUN_ON_START=true; taking one backup before starting cron"
  /usr/local/bin/backup.sh
fi

crontab="/tmp/crontab"
printf '%s /usr/local/bin/backup.sh\n' "$BACKUP_SCHEDULE" >"$crontab"

echo "starting supercronic, schedule: ${BACKUP_SCHEDULE}"
exec /usr/local/bin/supercronic "$crontab"
