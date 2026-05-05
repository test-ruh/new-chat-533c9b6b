#!/usr/bin/env bash
# Check required environment variables are set.
set -euo pipefail

missing=0
if [ -z "${PG_CONNECTION_STRING:-}" ]; then echo "MISSING: PG_CONNECTION_STRING"; missing=$((missing+1)); fi
if [ -z "${DATABASE_URL:-}" ]; then echo "MISSING: DATABASE_URL"; missing=$((missing+1)); fi
if [ -z "${ORG_ID:-}" ]; then echo "MISSING: ORG_ID"; missing=$((missing+1)); fi
if [ -z "${AGENT_ID:-}" ]; then echo "MISSING: AGENT_ID"; missing=$((missing+1)); fi
if [ -z "${RUN_ID:-}" ]; then echo "MISSING: RUN_ID"; missing=$((missing+1)); fi
if [ -z "${PROJECT_ROOT:-}" ]; then echo "MISSING: PROJECT_ROOT"; missing=$((missing+1)); fi
if [ -z "${SORA_API_KEY:-}" ]; then echo "MISSING: SORA_API_KEY"; missing=$((missing+1)); fi
if [ -z "${SORA_API_BASE_URL:-}" ]; then echo "MISSING: SORA_API_BASE_URL"; missing=$((missing+1)); fi
if [ -z "${SLACK_BOT_TOKEN:-}" ]; then echo "MISSING: SLACK_BOT_TOKEN"; missing=$((missing+1)); fi
if [ -z "${EMAIL_INBOUND_TOKEN:-}" ]; then echo "MISSING: EMAIL_INBOUND_TOKEN"; missing=$((missing+1)); fi
if [ -z "${EMAIL_SMTP_TOKEN:-}" ]; then echo "MISSING: EMAIL_SMTP_TOKEN"; missing=$((missing+1)); fi

if [ $missing -gt 0 ]; then
    echo "$missing required env var(s) missing"
    exit 1
fi
echo "OK: all required env vars set"
