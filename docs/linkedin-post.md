Summarization is the easy problem.

Clustering is the hard one.

18 customers described the same bug this month. Different words. Different platforms. Different star ratings.

A summarization tool tells you what 18 people said.
A clustering pipeline tells you it was the same problem, 18 times.

I built the second one.

It ingests App Store reviews, G2, Typeform, and CSV uploads. Normalizes everything into a unified schema. Then Claude groups every item by theme across every source, regardless of how it was phrased.

Each cluster gets scored: frequency, sentiment, revenue signal, and estimated effort. The output isn't a list of complaints. It's a ranked backlog with representative quotes, revenue context, and recommended next actions.

Three Claude calls, chained. Live App Store ingestion. Delivers to Markdown, Slack, or Notion.

The PM job isn't to summarize feedback. It's to know what to build next.

This does that, automatically.

#ProductManagement #AITools #n8n #BuildInPublic

---

<!-- POST INSTRUCTIONS -->
<!-- 1. Copy everything above the --- line into LinkedIn -->
<!-- 2. Attach docs/workflow-canvas.png as the image -->
<!-- 3. After posting, drop this as the first comment: -->
<!-- https://github.com/TechPMRyan/feature-request-intelligence -->
