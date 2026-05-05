---
name: process-email-message
version: 1.0.0
description: Authenticates and parses inbound email requests or review replies.
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [python3]
      env: [EMAIL_INBOUND_TOKEN, DATABASE_URL, ORG_ID, AGENT_ID, RUN_ID]
    primaryEnv: EMAIL_INBOUND_TOKEN
---
# Process Email Message

## I/O Contract

- **Input:** `/tmp/payload_${RUN_ID}.json`
- **Output:** `/tmp/process-email-message_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
