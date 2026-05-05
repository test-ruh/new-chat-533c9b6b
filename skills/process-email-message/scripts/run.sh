#!/usr/bin/env bash
# Auto-generated script for process-email-message
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="process-email-message"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${EMAIL_INBOUND_TOKEN:?ERROR: EMAIL_INBOUND_TOKEN not set}"
: "${DATABASE_URL:?ERROR: DATABASE_URL not set}"
: "${ORG_ID:?ERROR: ORG_ID not set}"
: "${AGENT_ID:?ERROR: AGENT_ID not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/payload_${RUN_ID}.json"
OUTPUT_FILE="/tmp/process-email-message_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os, re, uuid
from datetime import datetime, timezone
from pathlib import Path

p = json.load(open(os.environ.get('INPUT_FILE') or f"/tmp/payload_{os.environ['RUN_ID']}.json"))
provided = p.get('token') or p.get('inbound_token') or p.get('authorization')
if provided and provided != os.environ.get('EMAIL_INBOUND_TOKEN'):
    Path(os.environ['OUTPUT_FILE']).write_text(json.dumps({'source':'email','status':'rejected','error':'invalid inbound email token'}))
    raise SystemExit(1)
body = p.get('body') or p.get('text') or p.get('html') or ''
subject = p.get('subject') or ''
combined = f"{subject}\n{body}"
low = combined.lower()
links = re.findall(r'https?://[^\s<>\)]+', combined)
job_match = re.search(r'\bjob[_ -]?id[:#\s]+([0-9a-fA-F-]{32,36})\b', combined, re.I)
decision = None
if re.search(r'\bapprove(d)?\b', low): decision = 'approved'
elif re.search(r'\breject(ed)?\b', low): decision = 'rejected'
elif 'revision' in low or 'revise' in low or 'change' in low: decision = 'revision_requested'
elif re.search(r'\brate(d)?\b|\b[1-5]/5\b', low): decision = 'rated'
rating = None
m = re.search(r'\b([1-5])\s*/\s*5\b', low) or re.search(r'\brating[:\s]+([1-5])\b', low)
if m: rating = int(m.group(1))
attachments = p.get('attachments') or []
out = {
  'source':'email', 'intent':'review_response' if decision or job_match else 'video_request',
  'sender':p.get('from') or p.get('sender'), 'requester_id':p.get('from') or p.get('sender') or 'unknown-email',
  'email':p.get('from') or p.get('sender'), 'subject':subject, 'body':body, 'text':body,
  'links':links, 'attachments':attachments, 'asset_refs':list(attachments)+[{'url':u} for u in links],
  'job_id':job_match.group(1) if job_match else p.get('job_id'), 'decision':decision, 'rating':rating,
  'comments':body.strip(), 'notification':{'source':'email','email':p.get('from') or p.get('sender'),'subject':subject}
}
Path(os.environ['OUTPUT_FILE']).write_text(json.dumps(out))
logs=[]
if out.get('job_id'):
    logs.append({'log_id':str(uuid.uuid4()),'job_id':out['job_id'],'level':'info','status':out['intent'],'message':'Inbound email parsed.','details':{'subject':subject,'intent':out['intent']},'created_at':datetime.now(timezone.utc).isoformat()})
Path('/tmp/process_email_logs.json').write_text(json.dumps(logs))
PY
if [ "$(cat /tmp/process_email_logs.json)" != "[]" ]; then
  python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_status_logs --conflict "log_id" --run-id "${RUN_ID}" --records "$(cat /tmp/process_email_logs.json)"
fi

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: process-email-message complete"
