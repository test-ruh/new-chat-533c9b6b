---
name: prepare-generation-prompt
version: 1.0.0
description: "Builds the provider-ready Sora-compatible prompt and settings payload."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [python3]
      env: [DATABASE_URL, ORG_ID, AGENT_ID, RUN_ID]
    primaryEnv: DATABASE_URL
---
# Prepare Generation Prompt

## I/O Contract

- **Input:** `/tmp/validate-policy-and-spec_${RUN_ID}.json`
- **Output:** `/tmp/prepare-generation-prompt_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
