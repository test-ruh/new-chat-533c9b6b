#!/usr/bin/env bash
# Auto-generated script for submit-video-generation
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="submit-video-generation"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${SORA_API_KEY:?ERROR: SORA_API_KEY not set}"
: "${SORA_API_BASE_URL:?ERROR: SORA_API_BASE_URL not set}"
: "${DATABASE_URL:?ERROR: DATABASE_URL not set}"
: "${ORG_ID:?ERROR: ORG_ID not set}"
: "${AGENT_ID:?ERROR: AGENT_ID not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/prepare-generation-prompt_${RUN_ID}.json"
OUTPUT_FILE="/tmp/submit-video-generation_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os
p=json.load(open(os.environ['INPUT_FILE']))
json.dump(p, open('/tmp/submit_context.json','w'))
json.dump(p.get('provider_payload') or {}, open('/tmp/sora_submit_payload.json','w'))
PY
status_code=$(curl -sS -w "%{http_code}" -o /tmp/sora_submit_response.json \
  -X POST "${SORA_API_BASE_URL%/}/generations" \
  -H "Authorization: Bearer ${SORA_API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(jq -r '.idempotency_key' /tmp/submit_context.json)" \
  --data-binary @/tmp/sora_submit_payload.json)
printf '%s' "$status_code" > /tmp/sora_submit_status_code.txt
if [ "$status_code" -lt 200 ] || [ "$status_code" -ge 300 ]; then
  echo "Sora submit failed HTTP $status_code: $(cat /tmp/sora_submit_response.json)" >&2
fi
python3 - <<'PY'
import json, os, uuid
from datetime import datetime, timezone
from pathlib import Path
ctx=json.load(open('/tmp/submit_context.json'))
raw=Path('/tmp/sora_submit_response.json').read_text()
try: resp=json.loads(raw)
except Exception: resp={'raw':raw}
code=int(Path('/tmp/sora_submit_status_code.txt').read_text())
now=datetime.now(timezone.utc).isoformat()
failed=code < 200 or code >= 300
provider_job_id=resp.get('id') or resp.get('job_id') or resp.get('generation_id')
out={**ctx,'status':'failed' if failed else 'generating','provider_job_id':provider_job_id,'provider_status':resp.get('status','submitted' if not failed else 'error'),'http_status':code,'provider_response':resp,'updated_at':now}
Path(os.environ['OUTPUT_FILE']).write_text(json.dumps(out))
Path('/tmp/submit_jobs.json').write_text(json.dumps([{'job_id':ctx['job_id'],'requester_id':ctx['requester_id'],'requester_channel':ctx['requester_channel'],'target_platform':ctx.get('target_platform'),'template_id':ctx.get('template_id'),'status':out['status'],'approval_required':True,'approved_at':None,'created_at':ctx.get('created_at') or now,'updated_at':now}]))
Path('/tmp/submit_logs.json').write_text(json.dumps([{'log_id':str(uuid.uuid4()),'job_id':ctx['job_id'],'level':'error' if failed else 'info','status':out['status'],'message':'Video generation submission failed.' if failed else 'Video generation submitted to provider.','details':{'http_status':code,'provider_job_id':provider_job_id,'provider_status':out['provider_status'],'response':resp},'created_at':now}]))
if failed: Path('/tmp/submit_failed.flag').write_text('1')
PY
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_video_jobs --conflict "job_id" --run-id "${RUN_ID}" --records "$(cat /tmp/submit_jobs.json)"
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_status_logs --conflict "log_id" --run-id "${RUN_ID}" --records "$(cat /tmp/submit_logs.json)"
if [ -f /tmp/submit_failed.flag ]; then exit 1; fi

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: submit-video-generation complete"
