#!/usr/bin/env bash
# Auto-generated script for parse-video-request
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="parse-video-request"
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
OUTPUT_FILE="/tmp/parse-video-request_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os, re, uuid
from datetime import datetime, timezone
from pathlib import Path

input_file = os.environ.get('INPUT_FILE') or f"/tmp/payload_{os.environ['RUN_ID']}.json"
p = json.load(open(input_file)) if os.path.exists(input_file) else {}
now = datetime.now(timezone.utc).isoformat()
text = "\n".join(str(p.get(k, "")) for k in ["text", "message", "body", "prompt", "script"] if p.get(k)).strip()
low = text.lower()
source = (p.get('source') or p.get('requester_channel') or 'slack').lower()
requester = p.get('requester_id') or p.get('user_id') or p.get('sender') or p.get('from') or 'unknown'
job_id = p.get('job_id') or str(uuid.uuid5(uuid.NAMESPACE_URL, f"{os.environ['RUN_ID']}:{source}:{requester}:{text[:160]}"))

def duration():
    if p.get('duration_seconds') is not None: return int(p['duration_seconds'])
    m = re.search(r'(\d{1,3})\s*(sec|second|seconds|s)\b', low)
    return int(m.group(1)) if m else None

def platform():
    if p.get('target_platform'): return p['target_platform']
    for raw, val in [('tiktok','TikTok'),('instagram reels','Instagram Reels'),('reels','Instagram Reels'),('youtube shorts','YouTube Shorts'),('shorts','YouTube Shorts'),('instagram','Instagram'),('youtube','YouTube')]:
        if raw in low: return val
    return None

ratio = p.get('aspect_ratio')
if not ratio:
    m = re.search(r'\b(9:16|16:9|1:1|4:5)\b', text)
    ratio = m.group(1) if m else None
assets = p.get('asset_refs') or p.get('attachments') or p.get('files') or []
if isinstance(assets, dict): assets = [assets]
dur = duration(); plat = platform(); prompt = p.get('prompt') or text
missing = []
if not prompt: missing.append('prompt_or_script')
if dur is None: missing.append('duration_seconds')
if not plat: missing.append('target_platform')
status = 'needs_input' if missing else 'requested'
out = {
  'job_id': job_id, 'requester_id': str(requester), 'requester_channel': source,
  'prompt': prompt, 'script': p.get('script'), 'target_platform': plat, 'template_id': p.get('template_id'),
  'aspect_ratio': ratio, 'duration_seconds': dur or 30, 'music_preference': p.get('music_preference'),
  'voiceover_text': p.get('voiceover_text'), 'captions_required': bool(p.get('captions_required', 'caption' in low or 'subtitle' in low)),
  'asset_refs': assets, 'rights_confirmed': bool(p.get('rights_confirmed') or 'i have rights' in low or 'licensed' in low),
  'missing_fields': missing, 'notification': {'source': source, 'channel_id': p.get('channel_id'), 'thread_ts': p.get('thread_ts'), 'email': p.get('email') or p.get('from') or p.get('sender'), 'subject': p.get('subject')},
  'created_at': now, 'updated_at': now
}
Path(os.environ['OUTPUT_FILE']).write_text(json.dumps(out))
Path('/tmp/parse_jobs.json').write_text(json.dumps([{'job_id':job_id,'requester_id':str(requester),'requester_channel':source,'target_platform':plat,'template_id':p.get('template_id'),'status':status,'approval_required':True,'approved_at':None,'created_at':now,'updated_at':now}]))
Path('/tmp/parse_inputs.json').write_text(json.dumps([{'input_id':str(uuid.uuid5(uuid.NAMESPACE_URL, job_id+':input')),'job_id':job_id,'prompt':prompt or '', 'script':p.get('script'),'aspect_ratio':ratio,'duration_seconds':dur or 30,'music_preference':p.get('music_preference'),'voiceover_text':p.get('voiceover_text'),'captions_required':out['captions_required'],'asset_refs':assets,'safety_notes':None,'created_at':now}]))
Path('/tmp/parse_logs.json').write_text(json.dumps([{'log_id':str(uuid.uuid4()),'job_id':job_id,'level':'info','status':status,'message':'Video request parsed and normalized.','details':{'missing_fields':missing,'source':source},'created_at':now}]))
PY
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_video_jobs --conflict "job_id" --run-id "${RUN_ID}" --records "$(cat /tmp/parse_jobs.json)"
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_video_inputs --conflict "job_id" --run-id "${RUN_ID}" --records "$(cat /tmp/parse_inputs.json)"
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_status_logs --conflict "log_id" --run-id "${RUN_ID}" --records "$(cat /tmp/parse_logs.json)"

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: parse-video-request complete"
