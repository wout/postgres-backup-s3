#!/usr/bin/env bash
# Derive rclone S3 remote config from base env vars. Source, don't exec.
export RCLONE_CONFIG_S3_TYPE=s3
export RCLONE_CONFIG_S3_PROVIDER="${S3_PROVIDER:-Other}"
export RCLONE_CONFIG_S3_ENDPOINT="$S3_ENDPOINT"
export RCLONE_CONFIG_S3_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID"
export RCLONE_CONFIG_S3_SECRET_ACCESS_KEY="$S3_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_S3_REGION="${S3_REGION:-us-east-1}"
export RCLONE_CONFIG_S3_ACL="${S3_ACL:-private}"
