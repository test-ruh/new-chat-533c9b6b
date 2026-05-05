# Step 5 of 5 — Access

## User Access

### Authorized Teams

| Team               | Access Level | Members (approx) |
|--------------------|-------------|-------------------|
| Marketing | submit and review | Social media managers, product marketers, founders, and campaign owners authorized in Slack or Email routing. |
| Brand Review | approve/reject/revise | Brand reviewers and creative leads designated by the workspace. |
| Creative Operations | operate and audit | Operators responsible for job status, failures, outputs, feedback history, and template maintenance. |

### Restricted From

| Team / Role          | Reason                          |
|----------------------|---------------------------------|
| External unauthenticated users | Inbound Slack and Email events require authorized channel/user context or inbound token validation. |
| Social publishing bots | External publishing is explicitly out of scope and requires separate human-approved tooling. |
| Legal decision makers by proxy | The agent flags obvious rights/safety concerns but does not replace legal review. |

## HiTL Approvers

| Skill                | Action                         | Approver             | Fallback Approver    |
|----------------------|--------------------------------|----------------------|----------------------|
| record-review-feedback | Approve generated draft before it can be treated as final or shared externally | Requester, brand reviewer, or authorized review group in Slack or Email | If no explicit approval is received, keep the job in completed/draft state and do not mark it approved. |

## Model Configuration

| Field                | Value                          |
|----------------------|--------------------------------|
| **Primary Model**    | claude-sonnet-4   |
| **Fallback Model**   | claude-haiku-3  |

## Token Budget

| Field                  | Value                  |
|------------------------|------------------------|
| **Monthly Budget**     | 1000000 tokens |
| **Alert Threshold**    | 800000 tokens |
| **Auto-Pause on Limit**| No |

## Security & Permissions

| Permission                         | Allowed    |
|------------------------------------|------------|
| read_slack_messages_and_metadata | ✅ |
| send_slack_native_messages | ✅ |
| read_email_inbound_events | ✅ |
| send_email_notifications | ✅ |
| call_sora_compatible_generation_api | ✅ |
| write_agent_result_tables | ✅ |
| save_brand_templates | ✅ |
| record_human_review_feedback | ✅ |
| publish_to_social_media | ❌ |
| generate_videos_over_30_seconds | ❌ |
| perform_destructive_database_operations | ❌ |
| commit_or_log_secrets | ❌ |
