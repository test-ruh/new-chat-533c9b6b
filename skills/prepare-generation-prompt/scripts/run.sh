#!/usr/bin/env bash
# Auto-generated script for prepare-generation-prompt
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="prepare-generation-prompt"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${DATABASE_URL:?ERROR: DATABASE_URL not set}"
: "${ORG_ID:?ERROR: ORG_ID not set}"
: "${AGENT_ID:?ERROR: AGENT_ID not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/validate-policy-and-spec_${RUN_ID}.json"
OUTPUT_FILE="/tmp/prepare-generation-prompt_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json, os, uuid
from datetime import datetime, timezone
from pathlib import Path

p=json.load(open(os.environ['INPUT_FILE']))
now=datetime.now(timezone.utc).isoformat()
if p.get('status') != 'valid':
    Path(os.environ['OUTPUT_FILE']).write_text(json.dumps({**p,'error':'Cannot prepare generation payload for an invalid or incomplete request.'}))
    raise SystemExit(0)
creative = p.get('prompt') or ''
if p.get('script'):
    creative += '\n\nScript or narration to follow:\n' + p['script']
instructions = [
  f"Create a concise {p['duration_seconds']}-second short-form draft video for {p.get('target_platform')}.",
  f"Aspect ratio: {p.get('aspect_ratio')}.",
  'Use original, brand-safe visuals and provider-safe/licensed audio only.',
  'This is a draft for human review; do not imply external publishing or guaranteed performance.'
]
if p.get('captions_required'): instructions.append('Include captions/subtitles where supported.')
if p.get('music_preference'): instructions.append(f"Music direction: {p['music_preference']}.")
if p.get('voiceover_text'): instructions.append(f"Voiceover text: {p['voiceover_text']}")
prompt='\n'.join(instructions)+'\n\nCreative brief:\n'+creative
payload={'prompt':prompt,'duration_seconds':p['duration_seconds'],'aspect_ratio':p['aspect_ratio'],'target_platform':p.get('target_platform'),'music':p.get('music_preference'),'voiceover':p.get('voiceover_text'),'subtitles':bool(p.get('captions_required')),'assets':p.get('asset_refs') or [],'metadata':{'job_id':p['job_id'],'requester_id':p.get('requester_id'),'template_id':p.get('template_id'),'approval_required':True}}
out={**p,'status':'ready_to_submit','provider_payload':payload,'idempotency_key':str(uuid.uuid5(uuid.NAMESPACE_URL,p['job_id']+':generation:v1')),'brief_summary':f"{p['duration_seconds']}s {p.get('aspect_ratio')} draft for {p.get('target_platform')}",'updated_at':now}
Path(os.environ['OUTPUT_FILE']).write_text(json.dumps(out))
Path('/tmp/prepare_logs.json').write_text(json.dumps([{'log_id':str(uuid.uuid4()),'job_id':p['job_id'],'level':'info','status':'ready_to_submit','message':'Provider-ready video generation payload prepared.','details':{'brief_summary':out['brief_summary'],'asset_count':len(payload['assets'])},'created_at':now}]))
PY
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_status_logs --conflict "log_id" --run-id "${RUN_ID}" --records "$(cat /tmp/prepare_logs.json)"

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: prepare-generation-prompt complete"
