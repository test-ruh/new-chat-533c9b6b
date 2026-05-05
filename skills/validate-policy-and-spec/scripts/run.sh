#!/usr/bin/env bash
# Auto-generated script for validate-policy-and-spec
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="validate-policy-and-spec"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${DATABASE_URL:?ERROR: DATABASE_URL not set}"
: "${ORG_ID:?ERROR: ORG_ID not set}"
: "${AGENT_ID:?ERROR: AGENT_ID not set}"
: "${RUN_ID:?ERROR: RUN_ID not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/parse-video-request_${RUN_ID}.json"
OUTPUT_FILE="/tmp/validate-policy-and-spec_${RUN_ID}.json"
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
missing=list(p.get('missing_fields') or [])
warnings=[]; questions=[]; safety=[]
if not (p.get('prompt') or p.get('script')) and 'prompt_or_script' not in missing: missing.append('prompt_or_script')
if not p.get('target_platform') and 'target_platform' not in missing: missing.append('target_platform')
dur=int(p.get('duration_seconds') or 0)
if dur <= 0 and 'duration_seconds' not in missing: missing.append('duration_seconds')
if dur > 30:
    warnings.append(f'Requested duration {dur}s exceeds the 30-second maximum.')
    questions.append('Please reduce the requested duration to 30 seconds or less.')
platform=(p.get('target_platform') or '').lower()
default_ratio='9:16' if any(x in platform for x in ['tiktok','reels','shorts']) else ('16:9' if platform == 'youtube' else None)
ratio=p.get('aspect_ratio') or default_ratio or '9:16'
if default_ratio and not p.get('aspect_ratio'):
    warnings.append(f'Aspect ratio defaulted to {default_ratio} for {p.get("target_platform")}.')
text=f"{p.get('prompt','')} {p.get('script','')} {p.get('music_preference','')}".lower()
flag_terms=['disney','marvel','pixar','star wars','harry potter','pokemon','celebrity','copyrighted song','famous character','taylor swift','drake']
if any(t in text for t in flag_terms) and not p.get('rights_confirmed'):
    safety.append('Potential copyrighted character/music/likeness request without rights confirmation.')
    questions.append('Please confirm you own or have licensed rights to the requested characters, music, logos, likenesses, footage, and scripts, or revise the brief.')
if any(t in text for t in ['deepfake','impersonate private person']):
    safety.append('Disallowed deceptive likeness or impersonation request.')
for m in missing:
    if m == 'prompt_or_script': questions.append('Please provide a prompt or script for the video.')
    if m == 'duration_seconds': questions.append('Please provide a duration of 30 seconds or less.')
    if m == 'target_platform': questions.append('Please provide the target platform, such as TikTok, Instagram Reels, or YouTube Shorts.')
status='valid'
if missing or questions: status='needs_input'
if any('Disallowed' in s for s in safety): status='rejected'
out={**p,'status':status,'duration_seconds':min(dur or 30,30),'aspect_ratio':ratio,'warnings':warnings,'clarification_questions':questions,'safety_notes':'; '.join(safety) if safety else None,'approved_for_generation':status=='valid','updated_at':now}
Path(os.environ['OUTPUT_FILE']).write_text(json.dumps(out))
Path('/tmp/validate_jobs.json').write_text(json.dumps([{'job_id':p['job_id'],'requester_id':p['requester_id'],'requester_channel':p['requester_channel'],'target_platform':p.get('target_platform'),'template_id':p.get('template_id'),'status':status,'approval_required':True,'approved_at':None,'created_at':p.get('created_at') or now,'updated_at':now}]))
Path('/tmp/validate_inputs.json').write_text(json.dumps([{'input_id':str(uuid.uuid5(uuid.NAMESPACE_URL,p['job_id']+':input')),'job_id':p['job_id'],'prompt':p.get('prompt') or '', 'script':p.get('script'),'aspect_ratio':ratio,'duration_seconds':min(dur or 30,30),'music_preference':p.get('music_preference'),'voiceover_text':p.get('voiceover_text'),'captions_required':bool(p.get('captions_required')),'asset_refs':p.get('asset_refs') or [],'safety_notes':out['safety_notes'],'created_at':p.get('created_at') or now}]))
Path('/tmp/validate_logs.json').write_text(json.dumps([{'log_id':str(uuid.uuid4()),'job_id':p['job_id'],'level':'warning' if status!='valid' else 'info','status':status,'message':'Request validation completed.','details':{'warnings':warnings,'questions':questions,'safety':safety},'created_at':now}]))
PY
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_video_jobs --conflict "job_id" --run-id "${RUN_ID}" --records "$(cat /tmp/validate_jobs.json)"
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_video_inputs --conflict "job_id" --run-id "${RUN_ID}" --records "$(cat /tmp/validate_inputs.json)"
python3 "${PROJECT_ROOT}/scripts/data_writer.py" write --table result_status_logs --conflict "log_id" --run-id "${RUN_ID}" --records "$(cat /tmp/validate_logs.json)"

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: validate-policy-and-spec complete"
