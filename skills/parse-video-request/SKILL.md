---
name: parse-video-request
version: 1.0.0
description: Normalizes Slack or Email video requests into a tracked creative brief.
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [python3]
      env: [DATABASE_URL, ORG_ID, AGENT_ID, RUN_ID]
    primaryEnv: DATABASE_URL
---
# Parse Video Request

## I/O Contract

- **Input:** `/tmp/payload_${RUN_ID}.json`
- **Output:** `/tmp/parse-video-request_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
