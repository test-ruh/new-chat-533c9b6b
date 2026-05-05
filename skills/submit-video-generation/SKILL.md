---
name: submit-video-generation
version: 1.0.0
description: "Submits a prepared short-video request to the Sora-compatible generation API."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [python3, curl, jq]
      env: [SORA_API_KEY, SORA_API_BASE_URL, DATABASE_URL, ORG_ID, AGENT_ID, RUN_ID]
    primaryEnv: SORA_API_KEY
---
# Submit Video Generation

## I/O Contract

- **Input:** `/tmp/prepare-generation-prompt_${RUN_ID}.json`
- **Output:** `/tmp/submit-video-generation_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
