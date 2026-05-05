# Workflow — End-to-End Process Flow

## Workflow Steps

1. **data-writer** → data-writer
2. **process_email_message** → process-email-message
3. **parse_video_request** → parse-video-request
4. **validate_policy_and_spec** → validate-policy-and-spec (depends on parse_video_request)
5. **request_clarification_slack** → native-tool: message (depends on validate_policy_and_spec)
6. **request_clarification_email** → send-email-notification (depends on validate_policy_and_spec)
7. **prepare_generation_prompt** → prepare-generation-prompt (depends on validate_policy_and_spec)
8. **submit_video_generation** → submit-video-generation (depends on prepare_generation_prompt)
9. **check_generation_status** → check-generation-status (depends on submit_video_generation)
10. **deliver_draft_slack** → native-tool: message (depends on check_generation_status)
11. **deliver_draft_email** → send-email-notification (depends on check_generation_status)
12. **record_review_feedback** → record-review-feedback (depends on check_generation_status)
13. **deliver_approved_slack** → native-tool: message (depends on record_review_feedback)
14. **deliver_approved_email** → send-email-notification (depends on record_review_feedback)

## Diagram

```
data-writer → process_email_message → parse_video_request → validate_policy_and_spec → request_clarification_slack → request_clarification_email → prepare_generation_prompt → submit_video_generation → check_generation_status → deliver_draft_slack → deliver_draft_email → record_review_feedback → deliver_approved_slack → deliver_approved_email
```
