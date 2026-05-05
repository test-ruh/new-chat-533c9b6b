#!/usr/bin/env bash
# Auto-generated script for record-review-feedback
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="record-review-feedback"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${DATABASE_URL:?ERROR: DATABASE_URL not set}"
: "${ORG_ID:?ERROR: ORG_ID not set}"
: "${AGENT_ID:?ERROR: AGENT_ID not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/payload_${RUN_ID}.json"
OUTPUT_FILE="/tmp/record-review-feedback_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os, re, uuid
from datetime import datetime, timezone
from pathlib import Path

p=json.load(open(os.environ.get('INPUT_FILE') or f"/tmp/payload_{os.environ['RUN_ID']}.json"))
now=datetime.now(timezone.utc).isoformat()
text=' '.join(str(p.get(k,'')) for k in ['text','body','comments','message']).lower()
decision=p.get('decision')
if not decision:
    if re.search(r'\bapprove(d)?\b', text): decision='approved'
    elif re.search(r'\breject(ed)?\b', text): decision='rejected'
    elif 'revision' in text or 'revise' in text or 'change' in text: decision='revision_requested'
    elif 'rate' in text or re.search(r'\b[1-5]/5\b', text): decision='rated'
    else: decision='revision_requested'
if decision not in ['approved','rejected','revision_requested','rated']: decision='revision_requested'
rating=p.get('rating')
if rating is None:
    m=re.search(r'\b([1-5])\s*/\s*5\b', text) or re.search(r'\brating[:\s]+([1-5])\b', text)
    rating=int(m.group(1)) if m else None
eng=p.get('engagement_target')
if eng is None:
    m=re.search(r'(\d[\d,]*)\s*(likes|views)', text)
    eng=int(m.group(1).replace(',','')) if m else None
job_id=p.get('job_id')
if not job_id:
    Path(os.environ['OUTPUT_FILE']).write_text(json.dumps({'status':'failed','error':'review feedback requires job_id'}))
    raise SystemExit(1)
reviewer=p.get('reviewer_id') or p.get('requester_id') or p.get('user_id') or p.get('sender') or p.get('email') or 'unknown-reviewer'
feedback_id=p.get('feedback_id') or str(uuid.uuid5(uuid.NAMESPACE_URL, f"{job_id}:{reviewer}:{decision}:{text[:80]}"))
job_status='approved' if decision=='approved' else ('rejected' if decision=='rejected' else 'needs_input')
approved_at=now if decision=='approved' else None
message = f"Approval recorded for Job ID {job_id}. This draft may be treated as approved, but external publishing remains out of scope for v1." if decision=='approved' else f"Feedback recorded for Job ID {job_id}: {decision}. Reply with revised creative direction to start a revision."
out={'feedback_id':feedback_id,'job_id':job_id,'output_id':p.get('output_id'),'reviewer_id':str(reviewer),'decision':decision,'rating':rating,'engagement_target':eng,'comments':p.get('comments') or p.get('body') or p.get('text'),'status':job_status,'approved_at':approved_at,'video_url':p.get('video_url'),'delivery_message':message,'updated_at':now,'notification':p.get('notification') or {'source':p.get('source')}}
Path(os.environ['OUTPUT_FILE']).write_text(json.dumps(out))
Path('/tmp/feedback_records.json').write_text(json.dumps([{'feedback_id':feedback_id,'job_id':job_id,'output_id':p.get('output_id'),'reviewer_id':str(reviewer),'decision':decision,'rating':rating,'engagement_target':eng,'comments':out['comments'],'created_at':now}]))
Path('/tmp/feedback_jobs.json').write_text(json.dumps([{'job_id':job_id,'requester_id':p.get('requester_id') or str(reviewer),'requester_channel':p.get('requester_channel') or p.get('source') or 'unknown','target_platform':p.get('target_platform'),'template_id':p.get('template_id'),'status':job_status,'approval_required':True,'approved_at':approved_at,'created_at':p.get('created_at') or now,'updated_at':now}]))
Path('/tmp/feedback_logs.json').write_text(json.dumps([{'log_id':str(uuid.uuid4()),'job_id':job_id,'level':'info','status':job_status,'message':'Human review feedback recorded.','details':{'decision':decision,'rating':rating,'engagement_target':eng},'created_at':now}]))
PY
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_user_feedback --conflict "feedback_id" --run-id "${RUN_ID}" --records "$(cat /tmp/feedback_records.json)"
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_video_jobs --conflict "job_id" --run-id "${RUN_ID}" --records "$(cat /tmp/feedback_jobs.json)"
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_status_logs --conflict "log_id" --run-id "${RUN_ID}" --records "$(cat /tmp/feedback_logs.json)"

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: record-review-feedback complete"
