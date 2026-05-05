---
name: record-review-feedback
version: 1.0.0
description: "Captures human approval, rejection, revision requests, ratings, and engagement targets."
user-invocable: true
metadata:
  openclaw:
    requires:
      bins: [python3]
      env: [DATABASE_URL, ORG_ID, AGENT_ID, RUN_ID]
    primaryEnv: DATABASE_URL
---
# Record Review Feedback

## I/O Contract

- **Input:** `/tmp/payload_${RUN_ID}.json`
- **Output:** `/tmp/record-review-feedback_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
