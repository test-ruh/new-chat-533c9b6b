# Review — Final Summary Before Deployment

## Agent Card

| Field              | Value                          |
|--------------------|--------------------------------|
| **Name**           | 🎬 Film maker Agent |
| **ID**             | `film-maker-agent`           |
| **Version**        | 1.0.0 |
| **Scope**          | On-demand Slack and Email text-to-video draft generation with safety validation, Sora-compatible video generation, persistence, delivery, feedback, and human approval.      |
| **Tone**           | Helpful, creative, concise, and production-minded.             |
| **Model**          | claude-sonnet-4 (primary), claude-haiku-3 (fallback) |
| **Token Budget**   | 1000000 tokens/month |

## Skills Summary

| Skill                     | Mode         |
|---------------------------|--------------|
| Data Writer | 🟢 Auto |
| Result Query | 🟢 Auto |
| GitHub Action | 🟢 Auto |
| Parse Video Request | 🟢 Auto |
| Process Email Message | 🟢 Auto |
| Validate Policy and Spec | 🟢 Auto |
| Prepare Generation Prompt | 🟢 Auto |
| Submit Video Generation | 🟢 Auto |
| Check Generation Status | 🟢 Auto |
| Send Email Notification | 🟢 Auto |
| Record Review Feedback | 🟢 Auto |

## Post-Deployment Checklist

- [ ] Set PG_CONNECTION_STRING or DATABASE_URL, ORG_ID, AGENT_ID, SORA_API_KEY, SORA_API_BASE_URL, SLACK_BOT_TOKEN, EMAIL_INBOUND_TOKEN, and EMAIL_SMTP_TOKEN in the deployment environment.
- [ ] Run check-environment.sh and confirm all required binaries and environment variables are present.
- [ ] Run data_writer.py provision against the PostgreSQL database and verify all result_ tables exist in org_${ORG_ID}_a_${AGENT_ID}.
- [ ] Configure Slack inbound routing and native message delivery for authorized request and review channels.
- [ ] Configure Email inbound token validation and outbound EMAIL_API_BASE_URL/SMTP proxy.
- [ ] Verify the Sora-compatible API contract supports POST /generations and GET /generations/{provider_job_id}, or route through a compatibility proxy.
- [ ] Submit a test Slack request for a 10-second draft and verify validation, generation, output persistence, draft delivery, and approval capture.
- [ ] Submit a test Email request with an asset link and verify parsing, response threading, draft delivery, and feedback capture.
- [ ] Test rejection/clarification for a request over 30 seconds and for obvious copyrighted content without rights confirmation.
- [ ] Confirm approved drafts are recorded but not automatically published to any external social destination.
