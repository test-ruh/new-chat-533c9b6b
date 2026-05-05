# Step 4 of 5 — Triggers

## Active Triggers

### slack-video-request — A user submits prompt/script, platform, duration, and optional assets/preferences in Slack; the workflow parses, validates, generates, stores, and responds.

| Field       | Value                              |
|-------------|------------------------------------|
| **Type**    | conversational                     |
| **Status**  | enabled                   |

**Sample User Queries This Trigger Handles:**

- "Create a 20 second TikTok product teaser with captions using this logo."
- "Make an Instagram Reels draft from this launch script, 15 seconds, upbeat music."

---

### email-video-request — A user sends an email containing prompt/script, preferences, attachments, or asset links; the workflow authenticates, parses, validates, generates, stores, and replies.

| Field       | Value                              |
|-------------|------------------------------------|
| **Type**    | event                     |
| **Status**  | enabled                   |

---

### review-response — A reviewer approves, rejects, rates, or requests revision from Slack thread or Email reply; the workflow records feedback and updates job status.

| Field       | Value                              |
|-------------|------------------------------------|
| **Type**    | conversational                     |
| **Status**  | enabled                   |

**Sample User Queries This Trigger Handles:**

- "approve job id 11111111-1111-1111-1111-111111111111"
- "Revision requested: make the hook faster and rate 4/5."

