#!/usr/bin/env bash
# Auto-generated script for send-email-notification
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="send-email-notification"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${EMAIL_SMTP_TOKEN:?ERROR: EMAIL_SMTP_TOKEN not set}"
: "${DATABASE_URL:?ERROR: DATABASE_URL not set}"
: "${ORG_ID:?ERROR: ORG_ID not set}"
: "${AGENT_ID:?ERROR: AGENT_ID not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/data-writer_${RUN_ID}.json"
OUTPUT_FILE="/tmp/send-email-notification_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os
from pathlib import Path
p=json.load(open(os.environ['INPUT_FILE']))
recipient=(p.get('notification') or {}).get('email') or p.get('recipient') or p.get('email') or p.get('requester_id')
job=p.get('job_id')
subject=p.get('subject') or (p.get('notification') or {}).get('subject') or f"Film maker Agent update{(' - Job ID '+job) if job else ''}"
if p.get('status') == 'needs_input':
    body='🎬 I need a few details before generating your video draft:\n- ' + '\n- '.join(p.get('clarification_questions') or ['Please provide the missing creative details.'])
elif p.get('delivery_message'):
    body=p['delivery_message']
elif p.get('decision') == 'approved':
    body=f"🎬 Approved video recorded for Job ID {job}. Final draft link: {p.get('video_url','see prior draft link')}. External social publishing is not performed by this agent."
else:
    body=p.get('message') or f"🎬 Film maker Agent status for Job ID {job}: {p.get('status','update')}"
json.dump({'to':recipient,'subject':subject,'body':body,'job_id':job}, open('/tmp/email_payload.json','w'))
PY
status_code=$(curl -sS -w "%{http_code}" -o /tmp/email_response.json \
  -X POST "${EMAIL_API_BASE_URL:-https://api.email.local/send}" \
  -H "Authorization: Bearer ${EMAIL_SMTP_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-binary @/tmp/email_payload.json)
printf '%s' "$status_code" > /tmp/email_status_code.txt
if [ "$status_code" -lt 200 ] || [ "$status_code" -ge 300 ]; then
  echo "Email send failed HTTP $status_code: $(cat /tmp/email_response.json)" >&2
fi
python3 - <<'PY'
import json, os, uuid
from datetime import datetime, timezone
from pathlib import Path
orig=json.load(open(os.environ['INPUT_FILE']))
payload=json.load(open('/tmp/email_payload.json'))
raw=Path('/tmp/email_response.json').read_text()
try: resp=json.loads(raw)
except Exception: resp={'raw':raw}
code=int(Path('/tmp/email_status_code.txt').read_text())
now=datetime.now(timezone.utc).isoformat(); sent=200 <= code < 300
out={**orig,'email_status':'sent' if sent else 'failed','status':'sent' if sent else 'failed','recipient':payload.get('to'),'subject':payload.get('subject'),'body':payload.get('body'),'http_status':code,'email_response':resp,'updated_at':now}
Path(os.environ['OUTPUT_FILE']).write_text(json.dumps(out))
logs=[]
if payload.get('job_id'):
    logs.append({'log_id':str(uuid.uuid4()),'job_id':payload['job_id'],'level':'info' if sent else 'error','status':'email_sent' if sent else 'email_failed','message':'Email notification sent.' if sent else 'Email notification failed.','details':{'http_status':code,'recipient':payload.get('to'),'response':resp},'created_at':now})
Path('/tmp/email_logs.json').write_text(json.dumps(logs))
outputs=[]
if sent and orig.get('output_id') and orig.get('video_url'):
    outputs.append({'output_id':orig['output_id'],'job_id':orig['job_id'],'provider_job_id':orig.get('provider_job_id'),'video_url':orig['video_url'],'thumbnail_url':orig.get('thumbnail_url'),'captions_url':orig.get('captions_url'),'metadata':orig.get('provider_metadata') or {},'delivered_at':now,'created_at':now})
Path('/tmp/email_outputs.json').write_text(json.dumps(outputs))
if not sent: Path('/tmp/email_failed.flag').write_text('1')
PY
if [ "$(cat /tmp/email_logs.json)" != "[]" ]; then
  python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_status_logs --conflict "log_id" --run-id "${RUN_ID}" --records "$(cat /tmp/email_logs.json)"
fi
if [ "$(cat /tmp/email_outputs.json)" != "[]" ]; then
  python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_video_outputs --conflict "output_id" --run-id "${RUN_ID}" --records "$(cat /tmp/email_outputs.json)"
fi
if [ -f /tmp/email_failed.flag ]; then exit 1; fi

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: send-email-notification complete"
