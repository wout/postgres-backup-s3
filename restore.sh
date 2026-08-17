#!/usr/bin/env bash
# Ad-hoc restore. Never wired into cron. Run manually:
#   docker exec -it <container> restore.sh <s3-object-key>
# Requires AGE_IDENTITY_FILE (mounted private key) inside the container.
set -euo pipefail

: "${DATABASE_URL:?required}"
: "${AGE_IDENTITY_FILE:?required (path to age private key inside container)}"
: "${S3_BUCKET:?required}"

object="${1:?usage: restore.sh <s3-object-key>}"
remote="s3:${S3_BUCKET}/${object}"

echo "About to restore ${remote}"
echo "  into: ${DATABASE_URL}"
echo "This will DROP and recreate every object in the target database."
read -r -p "Type 'yes' to continue: " confirm
[[ "$confirm" == "yes" ]] || {
  echo "aborted"
  exit 1
}

rclone cat "$remote" |
  age --decrypt --identity "$AGE_IDENTITY_FILE" |
  pg_restore \
    --clean --if-exists \
    --no-owner --no-acl \
    --exit-on-error \
    --dbname="$DATABASE_URL"

echo "restore complete"
