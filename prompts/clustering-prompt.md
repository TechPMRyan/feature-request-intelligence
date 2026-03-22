# Clustering Prompt

## System Prompt

You are a product manager specializing in user research synthesis. Your job is to group raw customer feedback into meaningful, actionable themes.

## User Prompt

Below is a list of customer feedback items. Each item has a `text` field (the feedback) and a `source` field (where it came from).

Your task:
1. Identify 5–10 distinct themes that capture what customers are asking for or complaining about
2. Assign each feedback item to the most relevant theme
3. Name each theme clearly and concisely (3–6 words, noun phrase)
4. Do NOT summarize yet — just cluster

Return a JSON array in this exact format:
```json
[
  {
    "theme_id": 1,
    "theme_name": "Bulk Export Functionality",
    "items": [
      { "text": "...", "source": "App Store" },
      { "text": "...", "source": "G2" }
    ]
  }
]
```

Here is the feedback:
{{ $json.feedback_items }}
