# 🎬 Film maker Agent

On-demand Slack and Email text-to-video draft generation with safety validation, Sora-compatible video generation, persistence, delivery, feedback, and human approval.

## Quick Start

```bash
git clone git@github.com:${GITHUB_OWNER}/film-maker-agent.git
cd film-maker-agent

# 1. Configure
cp .env.example .env
# Edit .env with your credentials (see "Required Environment Variables" below)

# 2. One-shot setup: validates env, installs deps, provisions DB, registers cron
chmod +x setup.sh
./setup.sh
```

## Manual Setup (if you prefer step-by-step)

```bash
cp .env.example .env             # then edit it
set -a; source .env; set +a       # load vars into the current shell
bash check-environment.sh         # verify everything required is set
bash install-dependencies.sh      # pip install psycopg2-binary, pyyaml
python3 scripts/data_writer.py provision   # create tables in your schema

```

## Running

```bash
bash test-workflow.sh             # run every skill in order locally (smoke test)

openclaw cron list                # see registered jobs
openclaw cron runs                # see run history
```

## Required Environment Variables

| Variable | Description |
|----------|-------------|
| `PG_CONNECTION_STRING` | PostgreSQL connection string |
| `DATABASE_URL` | Database URL used by runtime skills |
| `ORG_ID` | Organization ID for schema isolation |
| `AGENT_ID` | Agent ID for schema isolation |
| `RUN_ID` | Workflow run identifier |
| `PROJECT_ROOT` | OpenClaw project root path |
| `SORA_API_KEY` | Sora-compatible text-to-video API key |
| `SORA_API_BASE_URL` | Sora-compatible text-to-video API base URL |
| `SLACK_BOT_TOKEN` | Slack bot token |
| `EMAIL_INBOUND_TOKEN` | Inbound email authentication token |
| `EMAIL_SMTP_TOKEN` | Outbound email SMTP/API token |

## Skills

| Skill | Mode | Description |
|-------|------|-------------|
| `data-writer` | Auto | Provision, write, and query the agent database schema via scripts/data_writer.py. Use for all PostgreSQL operations and any result-table persistence. |
| `result-query` | User-invocable | Read stored records from the agent result tables for inspection and follow-up questions. |
| `github-action` | User-invocable | Git branch + PR workflow for syncing agent changes to GitHub. Creates feature branches, commits changes, and opens pull requests against main. NEVER pushes to main directly. MANDATORY for every agent. |
| `parse-video-request` | Auto | Normalizes Slack or Email video requests into a tracked creative brief. |
| `process-email-message` | Auto | Authenticates and parses inbound email requests or review replies. |
| `validate-policy-and-spec` | Auto | Enforces required fields, maximum 30-second duration, platform fit, and copyright/safety constraints. |
| `prepare-generation-prompt` | Auto | Builds the provider-ready Sora-compatible prompt and settings payload. |
| `submit-video-generation` | Auto | Submits a prepared short-video request to the Sora-compatible generation API. |
| `check-generation-status` | Auto | Polls the video provider and stores completed output URLs or failure metadata. |
| `send-email-notification` | Auto | Sends Email clarification, status, draft delivery, approval, and feedback messages. |
| `record-review-feedback` | User-invocable | Captures human approval, rejection, revision requests, ratings, and engagement targets. |



## Architecture

- **Runtime**: OpenClaw AI agent framework
- **Data Layer**: PostgreSQL via `scripts/data_writer.py`
- **Scheduling**: OpenClaw cron
- **Schema**: `org_{org_id}_a_film_maker_agent`

## Directory Structure

```
film-maker-agent/
├── README.md
├── openclaw.json
├── result-schema.yml
├── env-manifest.yml
├── .env.example
├── requirements.txt
├── .gitignore
├── check-environment.sh
├── install-dependencies.sh
├── test-workflow.sh
├── cron/
├── workflows/
├── scripts/
│   ├── data_writer.py
│   └── github_action.py
├── skills/
└── workspace/
    ├── SOUL.md
    ├── 01_IDENTITY.md
    ├── 02_RULES.md
    ├── 03_SKILLS.md
    ├── 04_TRIGGERS.md
    ├── 05_ACCESS.md
    ├── 06_WORKFLOW.md
    └── 07_REVIEW.md
```
