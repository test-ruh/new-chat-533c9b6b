---
name: validate-policy-and-spec
version: 1.0.0
description: "Enforces required fields, maximum 30-second duration, platform fit, and copyright/safety constraints."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [python3]
      env: [DATABASE_URL, ORG_ID, AGENT_ID, RUN_ID]
    primaryEnv: DATABASE_URL
---
# Validate Policy and Spec

## I/O Contract

- **Input:** `/tmp/parse-video-request_${RUN_ID}.json`
- **Output:** `/tmp/validate-policy-and-spec_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
