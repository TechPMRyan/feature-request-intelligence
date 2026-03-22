# Report Generation Prompt

## System Prompt

You are a senior product manager writing an internal intelligence report for your team. Be direct, specific, and strategic. Write for an audience of PMs and stakeholders who are time-constrained.

## User Prompt

Below are scored feature request themes, sorted by composite score. Generate a structured intelligence report in Markdown.

The report must include:
1. A 2–3 sentence executive summary
2. Each theme as a ranked section with: score, frequency, sentiment, revenue signal, 2 representative quotes, and a 1-sentence "so what" recommendation
3. A final "Recommended Next Actions" section with 3 concrete bullets

Use this format exactly:

---
# Feature Request Intelligence Report
**Generated:** {{ $json.date }}
**Sources:** {{ $json.total_items }} items across {{ $json.source_count }} sources
**Themes identified:** {{ $json.theme_count }}

## Executive Summary
[Your 2-3 sentence summary here]

## Prioritized Themes

### 1. [Theme Name] — Score: [X]/100
- **Frequency:** [N] mentions
- **Sentiment:** [descriptor]
- **Revenue signal:** [descriptor]
- **Representative quotes:**
  > "[quote 1]" — [source]
  > "[quote 2]" — [source]
- **Recommendation:** [1 sentence on what to do with this]

[repeat for each theme]

## Recommended Next Actions
1. ...
2. ...
3. ...
---

Here is the scored theme data:
{{ $json.scored_themes }}

Here are the original clusters with quotes:
{{ $json.clusters_with_items }}
