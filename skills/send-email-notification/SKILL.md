---
name: send-email-notification
version: 1.0.0
description: "Sends Email clarification, status, draft delivery, approval, and feedback messages."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [python3, curl]
      env: [EMAIL_SMTP_TOKEN, DATABASE_URL, ORG_ID, AGENT_ID, RUN_ID]
    primaryEnv: EMAIL_SMTP_TOKEN
---
# Send Email Notification

## I/O Contract

- **Input:** `/tmp/data-writer_${RUN_ID}.json`
- **Output:** `/tmp/send-email-notification_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
