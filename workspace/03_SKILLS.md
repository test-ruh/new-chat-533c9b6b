# Step 3 of 5 — Skills

## Added Skills

| #    | Skill ID                  | Skill Name               | Mode   | Risk Level | Description                |
|------|---------------------------|--------------------------|--------|------------|----------------------------|
| S1   | `data-writer` | Data Writer | Auto | Low | Provision, write, and query the agent database schema via scripts/data_writer.py. Use for all PostgreSQL operations and any result-table persistence. |
| S2   | `result-query` | Result Query | Auto | Low | Read stored records from the agent result tables for inspection and follow-up questions. |
| S3   | `github-action` | GitHub Action | Auto | Low | Git branch + PR workflow for syncing agent changes to GitHub. Creates feature branches, commits changes, and opens pull requests against main. NEVER pushes to main directly. MANDATORY for every agent. |
| S4   | `parse-video-request` | Parse Video Request | Auto | Low | Normalizes Slack or Email video requests into a tracked creative brief. |
| S5   | `process-email-message` | Process Email Message | Auto | Low | Authenticates and parses inbound email requests or review replies. |
| S6   | `validate-policy-and-spec` | Validate Policy and Spec | Auto | Low | Enforces required fields, maximum 30-second duration, platform fit, and copyright/safety constraints. |
| S7   | `prepare-generation-prompt` | Prepare Generation Prompt | Auto | Low | Builds the provider-ready Sora-compatible prompt and settings payload. |
| S8   | `submit-video-generation` | Submit Video Generation | Auto | Low | Submits a prepared short-video request to the Sora-compatible generation API. |
| S9   | `check-generation-status` | Check Generation Status | Auto | Low | Polls the video provider and stores completed output URLs or failure metadata. |
| S10   | `send-email-notification` | Send Email Notification | Auto | Low | Sends Email clarification, status, draft delivery, approval, and feedback messages. |
| S11   | `record-review-feedback` | Record Review Feedback | Auto | Low | Captures human approval, rejection, revision requests, ratings, and engagement targets. |

## Skill Dependencies (Execution Order)

```
data-writer
result-query
github-action
parse-video-request
process-email-message
validate-policy-and-spec ← depends on parse-video-request
prepare-generation-prompt ← depends on validate-policy-and-spec
submit-video-generation ← depends on prepare-generation-prompt
check-generation-status ← depends on submit-video-generation
send-email-notification
record-review-feedback ← depends on check-generation-status
```

## Execution Mode Summary

| Mode  | Count          |
|-------|----------------|
| HiTL  | 0              |
| Auto  | 11 |
