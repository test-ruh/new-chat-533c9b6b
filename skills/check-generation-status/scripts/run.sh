#!/usr/bin/env bash
# Auto-generated script for check-generation-status
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="check-generation-status"
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
INPUT_FILE="/tmp/submit-video-generation_${RUN_ID}.json"
OUTPUT_FILE="/tmp/check-generation-status_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os
p=json.load(open(os.environ['INPUT_FILE']))
json.dump(p, open('/tmp/check_context.json','w'))
PY
provider_job_id=$(jq -r '.provider_job_id // empty' /tmp/check_context.json)
if [ -z "$provider_job_id" ]; then
  echo '{"error":"missing provider_job_id"}' > /tmp/sora_status_response.json
  echo 400 > /tmp/sora_status_code.txt
else
  attempts=0
  while true; do
    attempts=$((attempts+1))
    code=$(curl -sS -w "%{http_code}" -o /tmp/sora_status_response.json \
      -H "Authorization: Bearer ${SORA_API_KEY}" \
      "${SORA_API_BASE_URL%/}/generations/${provider_job_id}")
    echo "$code" > /tmp/sora_status_code.txt
    provider_status=$(jq -r '.status // .state // empty' /tmp/sora_status_response.json 2>/dev/null || true)
    if [ "$code" = "429" ] || [ "$code" = "503" ]; then
      sleep $((attempts * 2)); [ "$attempts" -lt 5 ] || break; continue
    fi
    if [ "$code" -lt 200 ] || [ "$code" -ge 300 ]; then
      echo "Sora status failed HTTP $code: $(cat /tmp/sora_status_response.json)" >&2; break
    fi
    case "$provider_status" in completed|succeeded|success|failed|error|cancelled) break ;; esac
    [ "$attempts" -lt 20 ] || break
    sleep 10
  done
fi
python3 - <<'PY'
import json, os, uuid
from datetime import datetime, timezone
from pathlib import Path
ctx=json.load(open('/tmp/check_context.json'))
raw=Path('/tmp/sora_status_response.json').read_text()
try: resp=json.loads(raw)
except Exception: resp={'raw':raw}
code=int(Path('/tmp/sora_status_code.txt').read_text())
now=datetime.now(timezone.utc).isoformat()
pstat=(resp.get('status') or resp.get('state') or '').lower()
video_url=resp.get('video_url') or (resp.get('output') or {}).get('video_url') or resp.get('url')
completed = 200 <= code < 300 and pstat in ['completed','succeeded','success'] and bool(video_url)
status='completed' if completed else 'failed'
output_id=str(uuid.uuid5(uuid.NAMESPACE_URL, ctx['job_id']+':'+str(ctx.get('provider_job_id'))+':output'))
delivery = f"🎬 Draft video ready for review (Job ID: {ctx['job_id']}): {video_url}\nPlease reply approve, reject, rate, or request revision. This is a draft until human approval; no external publishing is performed." if completed else f"I couldn’t generate this draft because the video provider returned an error or did not complete in time. Job ID: {ctx['job_id']}. No video has been approved or published."
out={**ctx,'status':status,'provider_status':pstat or ('http_error' if code>=400 else 'timeout_or_incomplete'),'http_status':code,'output_id':output_id if completed else None,'video_url':video_url,'thumbnail_url':resp.get('thumbnail_url') or (resp.get('output') or {}).get('thumbnail_url'),'captions_url':resp.get('captions_url') or (resp.get('output') or {}).get('captions_url'),'provider_metadata':resp,'delivery_message':delivery,'updated_at':now}
Path(os.environ['OUTPUT_FILE']).write_text(json.dumps(out))
Path('/tmp/check_jobs.json').write_text(json.dumps([{'job_id':ctx['job_id'],'requester_id':ctx['requester_id'],'requester_channel':ctx['requester_channel'],'target_platform':ctx.get('target_platform'),'template_id':ctx.get('template_id'),'status':status,'approval_required':True,'approved_at':None,'created_at':ctx.get('created_at') or now,'updated_at':now}]))
Path('/tmp/check_logs.json').write_text(json.dumps([{'log_id':str(uuid.uuid4()),'job_id':ctx['job_id'],'level':'info' if completed else 'error','status':status,'message':'Video generation completed.' if completed else 'Video generation failed or timed out.','details':{'http_status':code,'provider_status':pstat,'provider_job_id':ctx.get('provider_job_id'),'response':resp},'created_at':now}]))
Path('/tmp/check_outputs.json').write_text(json.dumps([{'output_id':output_id,'job_id':ctx['job_id'],'provider_job_id':ctx.get('provider_job_id'),'video_url':video_url,'thumbnail_url':out.get('thumbnail_url'),'captions_url':out.get('captions_url'),'metadata':resp,'delivered_at':None,'created_at':now}]) if completed else '[]')
if not completed: Path('/tmp/check_failed.flag').write_text('1')
PY
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_video_jobs --conflict "job_id" --run-id "${RUN_ID}" --records "$(cat /tmp/check_jobs.json)"
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_status_logs --conflict "log_id" --run-id "${RUN_ID}" --records "$(cat /tmp/check_logs.json)"
if [ "$(cat /tmp/check_outputs.json)" != "[]" ]; then
  python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_video_outputs --conflict "output_id" --run-id "${RUN_ID}" --records "$(cat /tmp/check_outputs.json)"
fi
if [ -f /tmp/check_failed.flag ]; then exit 1; fi

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: check-generation-status complete"
