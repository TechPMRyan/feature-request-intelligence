# Feature Request Intelligence Pipeline

> Turns scattered customer feedback from multiple sources into a scored, ranked backlog, automatically.

---

## The Problem

Customer feedback is scattered across App Store reviews, G2, Typeform, support tickets, and sales calls, each in a different format with different signal strengths. Synthesizing it into a prioritized backlog is manual, time-consuming, and still subjective: high-severity enterprise complaints get buried next to casual wishlist items, revenue signal is ignored, and effort is a gut call.

This pipeline automates that synthesis end-to-end.

---

## What It Does

Ingestion pipeline that normalizes customer feedback into a unified schema, uses Claude to perform thematic clustering, scores each cluster across four weighted dimensions, and emits a prioritized backlog report to Markdown, Slack, or Notion.

**Input sources:** App Store reviews (live via iTunes RSS)

**Triggers:** Manual execution, Slack slash command (`/customer-fr`)

**Output:** A scored, ranked report with executive summary, theme-by-theme breakdown, representative quotes, and recommended next actions. Saves to Markdown, posts to Slack (with file upload), or writes to Notion.

---

## Architecture

```
[Trigger: Manual or Slack /customer-fr]
        |
        v
Config (Manual)  OR  Config (Slack)
        |                   |
        +-------+-----------+
                |
                v
        iTunes RSS API
        (live App Store reviews, no auth required)
                |
                v
        Parse + Normalize
        (unified schema: text, source, date, rating)
        (Unicode sanitization, date/platform filtering)
                |
                v
        IF - Has Data?
        |           |
     [yes]        [no]
        |           |
        v           v
  Claude Pipeline   "No results" Slack message
        |
        v
  Thematic Clustering
  (groups feedback into named themes)
        |
        v
  Multi-Dimensional Scoring
  (frequency, sentiment, revenue signal, effort)
        |
        v
  Sort by composite score
        |
        v
  Report Generation
  (exec summary, ranked themes, quotes, recommendations)
        |
        v
  Switch: Output Mode
  |         |           |
  v         v           v
markdown   slack       notion
  |         |           |
  v         v           v
File      Block Kit   Notion API
Writer    summary +   page
          file upload
```

---

## Design Decisions

**Clustering over summarization.** Most feedback tools summarize: they tell you what people said. This pipeline clusters: it identifies which customers said the same thing in different ways and groups them together. Summarization flattens signal; clustering preserves it. Each cluster surfaces item count, source distribution, and verbatim feedback per item.

**RICE-adjacent scoring, not sentiment alone.** Sentiment tells you how people feel. It doesn't tell you what to build next. Each theme gets scored across four dimensions: frequency (how many items), sentiment (positive demand vs. frustration-driven churn risk), revenue signal (enterprise accounts, upgrade blockers, churned customers), and effort hint. The composite score produces a ranked list that maps directly to how a PM would actually prioritize, not just what's loudest.

**Chained prompts, not one big prompt.** The three Claude calls build on each other: clustering produces structured theme definitions, scoring operates on those definitions (not raw feedback), and the report generates from scored data. Each stage emits auditable output before the next prompt executes, making failures easy to isolate.

**Config node pattern.** All credentials and settings live in a single Code node at the start of the workflow. Every downstream node references the Config output. Changing the API key, output mode, or target app ID is a one-node operation: no hunting through 30 nodes to update a value.

**Dual trigger, shared pipeline.** Both Manual Trigger and the Slack Webhook feed into the same Claude pipeline through separate Config nodes. Only one fires at a time. This means one workflow handles both use cases without duplicating any logic.

---

## Sample Output

```
# Feature Request Intelligence Report
Generated: 2025-01-14 | Sources: 47 items across 4 sources

## Executive Summary
Customers are most frustrated by the lack of bulk export functionality,
with churn risk elevated among enterprise accounts. Mobile performance
issues represent a high-frequency complaint skewing heavily 1-star.
Collaboration features are requested with positive sentiment: users
want them rather than being blocked by their absence.

## Prioritized Themes

### 1. Bulk Export / Data Portability - Score: 91/100
- **Frequency:** 18 mentions across App Store, G2, and Typeform
- **Sentiment:** Strongly negative, described as a "dealbreaker" repeatedly
- **Revenue signal:** 4 enterprise accounts cited this in churned feedback
- **Effort hint:** API work + permissions model, medium complexity
- **Representative quotes:**
  > "We can't use this at scale without a way to export everything at once." - G2, 2 stars
  > "I've been waiting 2 years for bulk export. Moving to a competitor." - App Store, 1 star

### 2. Mobile Performance - Score: 78/100
- **Frequency:** 14 mentions (App Store-heavy)
- **Sentiment:** Negative, frustration, not feature requests
- **Revenue signal:** Low (consumer segment; no enterprise signals detected)
- **Effort hint:** Platform-level performance work, high complexity
- **Representative quotes:**
  > "Crashes every time I try to open a large file on iPhone." - App Store, 1 star

### 3. Real-Time Collaboration - Score: 61/100
- **Frequency:** 9 mentions across G2 and Typeform
- **Sentiment:** Positive, framed as excitement, not frustration
- **Revenue signal:** 2 mid-market accounts mentioned in expansion feedback
- **Effort hint:** Infrastructure-level change, high complexity

## Recommended Next Actions
1. Prioritize bulk export: high frequency, confirmed revenue signal, active churn risk
2. Investigate mobile crash reports before next App Store release cycle
3. Add collaboration to roadmap with a public timeline, positive sentiment makes it a win to announce
```

---

## The AI Pipeline

Three Claude calls, chained: each builds on structured output from the last.

| Step | Input | Output |
|------|-------|--------|
| 1. Clustering | Raw feedback array (text, source, date, rating) | Named theme clusters with item assignments |
| 2. Scoring | Theme clusters + constituent items | Each theme scored: frequency, sentiment, revenue signal, effort |
| 3. Report | Scored + sorted clusters | Full Markdown report with exec summary, ranked themes, quotes, recommendations |

Claude doesn't see raw feedback at the scoring stage: it works from the clustering output. This reduces noise and keeps scoring focused on theme-level signal rather than individual item variation.

---

## Integrations

| Source | Method | Auth | Status |
|--------|--------|------|--------|
| App Store reviews | iTunes RSS API | None | Live |
| Claude | Anthropic API | API key | Live |
| Slack (trigger) | Slash command `/customer-fr` | Bot token | Live |
| Slack (output) | `chat.postMessage` + file upload | Bot token | Live |
| Notion (output) | Notion API | Integration token | Live |

---

## Roadmap

| # | Source | Notes |
|---|--------|-------|
| 1 | **Zendesk** | Ingest tickets via Zendesk Search API as a parallel source branch |
| 2 | **G2 / Typeform** | Add live ingestion from G2 RSS and Typeform webhooks |
| 3 | **Sleekplan** | Ingest feature votes and feedback posts via Sleekplan API; weight by vote count as a frequency signal |

New sources feed the existing Normalize stage with no changes to the Claude pipeline or output layer.

---

## Setup

### Prerequisites
- n8n running locally or on Cloud
- `file-writer.ps1` running on `localhost:9998` (Markdown output mode only; see [File writing workaround](#file-writing-workaround) below)

### Quick Start: Sample data, no external credentials needed

1. Import `workflows/phase-1-csv-to-report.json` into n8n
2. Open the **Config** node and set your Anthropic API key
3. Run `file-writer.ps1` (Markdown mode only)
4. Click **Execute Workflow**
5. Report appears in your configured output path

### Full Pipeline: Live App Store reviews with multi-output routing

1. Import `workflows/phase-3-multi-output.json`
2. Open **Config (Manual)** and set:
   - `apiKey`: your Anthropic API key (or use n8n's HTTP Header Auth credential)
   - `appId`: your App Store app ID (the number after `/id` in any App Store URL)
   - `outputMode`: `'markdown'` | `'slack'` | `'notion'`
   - `outputPath`: absolute path to your output directory
   - `slackBotToken`: your Slack bot token (Slack mode)
   - `notionDatabaseId`: your Notion database ID (Notion mode)
3. Run `file-writer.ps1` (Markdown mode only)
4. Click **Execute Workflow**

**App ID example:**
```
https://apps.apple.com/us/app/notion/id1252015962
                                         ^^^^^^^^^^
```

### Slack Trigger: Run from any Slack channel

The same `phase-3-multi-output.json` workflow includes a Slack webhook trigger. No separate workflow needed.

1. **Publish** the workflow (production webhooks only register on published workflows)
2. Open **Config (Slack)** and set your Anthropic API key and Slack bot token

**Slack App setup:**

1. Create a Slack App at [api.slack.com/apps](https://api.slack.com/apps)
2. Add bot scopes: `chat:write`, `commands`, `files:write` (OAuth & Permissions)
3. Install to workspace, copy the Bot User OAuth Token
4. Create slash command `/customer-fr` pointing to `https://<your-n8n-host>/webhook/fri-slack-trigger`
5. Invite the bot to channels where you want to use the command: `/invite @YourBotName`

**Slash command parameters:**
- `/customer-fr` : all sources, last 30 days
- `/customer-fr ios` : filter feedback by keyword
- `/customer-fr last 7 days` : custom time range
- `/customer-fr ios last 14 days` : both filters combined
- `/customer-fr all` : all time (no date filter)

**Local development:** n8n must be reachable from Slack. Use [ngrok](https://ngrok.com) (`ngrok http 5678`) to expose your local instance.

**n8n v2 notes:**
- "Publish" is how n8n v2 activates workflows. Production webhook URLs only work on published workflows.
- Every `n8n import:workflow` deactivates the workflow. You must republish after each import.
- Production webhook executions don't appear on the canvas. Check the **Executions** list in the sidebar.

---

### File writing workaround

n8n's Code node sandbox blocks `fs`. Markdown output works by POSTing to a local HTTP listener instead:

```powershell
powershell -ExecutionPolicy Bypass -File "path\to\file-writer.ps1"
```

Any HTTP listener that accepts `POST { filename, content }` and writes the file to disk will work.

---

## Files

```
workflows/
  phase-1-csv-to-report.json       - Quick start: sample data to report (no external APIs)
  phase-3-multi-output.json        - Full pipeline: dual trigger, multi-output routing
  *-with-creds.json                - Gitignored variants with credentials baked in
prompts/       - Claude prompt templates: clustering, scoring, report
samples/       - Sample input CSV
outputs/       - Generated reports (gitignored)
docs/          - Architecture notes
file-writer.ps1 - Local HTTP listener for Markdown file output
```
