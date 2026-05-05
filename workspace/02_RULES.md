# Step 2 of 5 — Rules

## Custom Agent Rules

| #    | Rule                  | Category        |
|------|-----------------------|-----------------|
| FM1   | Never submit a video generation request with duration_seconds greater than 30; ask the user to reduce the duration first. | duration |
| FM2   | Reject or request revision for obvious copyrighted characters, music, footage, scripts, logos, celebrity likenesses, or private-person impersonation unless rights are clearly confirmed and the request is otherwise safe. | copyright_safety |
| FM3   | Treat every generated video as a draft until explicit human approval is recorded; never publish to social networks or share externally in v1. | approval |
| FM4   | Do not guarantee likes, views, sales, conversions, virality, or achievement of a 5,000-like target; store engagement targets as aspirational feedback only. | claims |
| FM5   | Use Slack for native threaded messages where possible and Email for inbound/outbound request, delivery, approval, and feedback flows while persisting cross-channel state consistently. | channels |
| FM6   | Persist job status transitions, prompts, scripts, settings, assets, outputs, provider errors, delivery timestamps, brand templates, and user feedback for audit and improvement. | data |

## Inherited Org Soul Rules (Cannot Be Removed)

| #    | Rule                  | Source          |
|------|-----------------------|-----------------|
| OS1  | Never perform DROP, DELETE, TRUNCATE, or ALTER TABLE operations on any database | Org Admin |
| OS2  | Never access or write to schemas outside the agent's own schema (`org_{ORG_ID}_a_{AGENT_ID}`) | Org Admin |
| OS3  | Never store credentials, API keys, or tokens in any file committed to the repository | Org Admin |
| OS4  | Respect API rate limits — add backoff/retry on HTTP 429 responses | Org Admin |
| OS5  | All external API calls must validate HTTP status codes and handle non-2xx responses explicitly | Org Admin |

## Rule Enforcement Summary

| Metric                  | Value                      |
|-------------------------|----------------------------|
| Total Custom Rules      | 6 |
| Total Inherited Rules   | 5 |
| **Total Active Rules**  | **11**               |
