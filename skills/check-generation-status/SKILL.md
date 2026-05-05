---
name: check-generation-status
version: 1.0.0
description: Polls the video provider and stores completed output URLs or failure metadata.
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [python3, curl, jq]
      env: [SORA_API_KEY, SORA_API_BASE_URL, DATABASE_URL, ORG_ID, AGENT_ID, RUN_ID]
    primaryEnv: SORA_API_KEY
---
# Check Generation Status

## I/O Contract

- **Input:** `/tmp/submit-video-generation_${RUN_ID}.json`
- **Output:** `/tmp/check-generation-status_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
