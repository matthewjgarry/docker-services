# 🐒⌨️ Monkeytype Reporting Workflows

Automated Monkeytype analytics built on **MongoDB + n8n + Discord + OpenAI**.

```text
Monkeytype → MongoDB → n8n → Discord
                         └→ OpenAI Coach
```

Each workflow is designed to answer a different question instead of repeating the same metrics at different time ranges.

---

## 🧩 Data Source

Monkeytype results are stored locally in MongoDB.

```text
database: monkeytype
collection: results
```

Primary user UID:

```text
WbdqpIgNzoTvEM0RqkMYkUFhW8l2
```

Result documents include:

- WPM / raw WPM
- accuracy
- consistency
- test duration
- timestamp
- per-second chart data
- mode / mode2

---

## 🐒⌨️ Daily Report — “Did I practice today?”

### Purpose

Daily reports are quick check-ins focused on activity, immediate improvement, streaks, and personal bests.

### Metrics

- tests today
- average WPM
- best WPM
- best raw WPM
- average accuracy
- average consistency
- total time typed
- current streak
- comparison vs yesterday

### Highlights

- WPM change vs yesterday
- accuracy change vs yesterday
- consistency change vs yesterday
- current streak
- daily milestones

### Style

- color: purple
- tone: short daily check-in

---

## 🐒📆 Weekly Report — “Am I improving?”

### Purpose

Weekly reports act as a progress review. They compare current-week performance against the previous week and highlight the strongest/most active days.

### Metrics

- tests this week vs last week
- time typed vs last week
- average WPM vs last week
- average accuracy vs last week
- average consistency vs last week
- best WPM
- best raw WPM
- best day
- most active day

### Highlights

- new all-time WPM PB during the week
- new all-time raw WPM PB during the week
- more tests than last week
- more practice time than last week

### Style

- color: green
- tone: progress review

---

## 🐒🗓️ Monthly Report — “What patterns are emerging?”

### Purpose

Monthly reports are higher-level performance reviews focused on patterns, consistency, and strongest weeks.

### Metrics

- tests this month vs last month
- total time typed vs last month
- active days this month
- average WPM vs last month
- average accuracy vs last month
- average consistency vs last month
- best WPM
- best raw WPM
- best week
- most active week

### Highlights

- new all-time WPM PB during the month
- new all-time raw WPM PB during the month
- more tests than last month
- more practice time than last month
- strong consistency when active days are high

### Style

- color: gold
- tone: monthly performance analysis

---

## 🐒🎆 Year-End Report — “What did I accomplish?”

### Purpose

The yearly report is the celebration report. It runs on New Year’s Day and summarizes the previous calendar year.

If it runs on January 1, 2027, it reports on 2026.

### Metrics

- total tests
- active days
- longest streak
- average WPM
- best WPM
- best raw WPM
- average accuracy
- average consistency
- total time typed
- best month
- most active month

### Highlights

- total effort summary
- total time typed
- longest streak
- all-time PBs
- best month
- most active month

### Style

- color: blue
- tone: celebration / annual recap

---

## 🐒🚀 Real-Time PB Alerts

### Purpose

PB alerts create an immediate feedback loop when a new personal best is recorded.

```text
New Monkeytype result → MongoDB → n8n PB detection → Discord alert → notification record
```

### Detection

The PB workflow checks recent unnotified results and compares each result against all older results.

Currently tracked PB types:

- WPM PB
- raw WPM PB

Accuracy and consistency PBs are better suited for daily/weekly reporting to avoid alert noise.

### Deduplication

PB alerts are deduplicated through:

```text
collection: monkeytype_pb_notifications
```

Each notification stores:

- resultId
- uid
- timestamp
- pbTypes
- wpm
- rawWpm
- acc
- consistency
- createdAt

The workflow inserts one record after a Discord notification succeeds.

### Index

Create a unique index to prevent duplicate alerts:

```javascript
db.monkeytype_pb_notifications.createIndex(
  { resultId: 1 },
  { unique: true }
)
```

### Insert Fields

The n8n MongoDB Insert node uses top-level fields from the Code node output.

```text
resultId,uid,timestamp,pbTypes,wpm,rawWpm,acc,consistency,createdAt
```

---

## 🐒⌨️ Session Summary

### Purpose

Session summaries are sent after a typing session ends.

A session is treated as a group of tests separated by less than the configured inactivity threshold.

```text
tests close together → session
no activity for threshold → summary
```

### Current Behavior

The workflow checks recent tests, groups them into sessions, waits for inactivity, and sends one Discord summary per session.

### Metrics

- tests in session
- time typed
- average WPM
- best WPM
- best raw WPM
- average accuracy
- average consistency
- session start/end time

### Deduplication

Session summaries are deduplicated through:

```text
collection: monkeytype_session_notifications
```

Each summary stores:

- sessionId
- uid
- firstTimestamp
- lastTimestamp
- tests
- avgWpm
- bestWpm
- bestRawWpm
- avgAcc
- avgConsistency
- totalMinutesTyped
- createdAt

### Index

Create a unique index:

```javascript
db.monkeytype_session_notifications.createIndex(
  { sessionId: 1 },
  { unique: true }
)
```

---

## 🐒🧠 OpenAI Coaching

### Purpose

The coaching layer adds written analysis on top of the factual reports.

The current implementation is attached to the weekly report.

```text
Weekly MongoDB aggregate
→ Weekly stats Code node
→ OpenAI node
→ Coach formatting Code node
→ Discord
```

### Weekly Coach Prompt

The OpenAI node receives the structured weekly report and generates a concise coaching summary.

The coach focuses on:

- speed trend
- accuracy trend
- consistency
- practice volume
- one practical recommendation

### Output

The coaching message is sent as a separate Discord embed:

```text
🐒🧠 Wormlogic Weekly Typing Coach
```

This keeps the factual report and coaching analysis separate.

---

## ⏱️ Scheduling

n8n cron format:

```text
[Second] [Minute] [Hour] [Day of Month] [Month] [Day of Week]
```

Recommended pattern:

```text
Daily:   shortly after the day ends
Weekly:  shortly after the week ends
Monthly: days 28–31, filtered in-workflow
Yearly:  January 1, reports previous year
PB:      every 2 minutes
Session: every 5 minutes
```

Monthly uses `28-31` instead of `L` for portability across n8n/runtime cron behavior.

The monthly workflow should guard internally so it only sends on the final day of the month.

---

## 🧠 Design Principles

- each report answers a different question
- daily is tactical
- weekly is progress-oriented
- monthly is pattern-oriented
- yearly is celebratory
- PB alerts are immediate
- session summaries wrap up practice bursts
- OpenAI coaching explains trends without replacing raw metrics
- milestones should be meaningful, not noisy
- Discord messages should be visually distinct

---

## 🧪 Testing

### Verify Monkeytype Results

```javascript
db.results.find().sort({ timestamp: -1 }).limit(5).pretty()
```

### Verify PB Notifications

```javascript
db.monkeytype_pb_notifications.find().pretty()
```

### Verify Session Notifications

```javascript
db.monkeytype_session_notifications.find().pretty()
```

### Reset PB Notification Test Data

```javascript
db.monkeytype_pb_notifications.deleteMany({})
```

### Reset Session Notification Test Data

```javascript
db.monkeytype_session_notifications.deleteMany({})
```

Only reset notification collections for testing. Do not delete from `results`.

---

## 🚀 Future Improvements

- local dashboard
- Postgres reporting tables
- Metabase charts
- historical WPM trend
- accuracy trend
- consistency trend
- agent-generated monthly analysis
- richer session insights
- typing mode breakdown
- time-of-day performance analysis

---

🐒⌨️ Monkeytype reporting turns raw typing data into a feedback system: instant PB alerts, useful session summaries, progress reports, and coaching insight.
