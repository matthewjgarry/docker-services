## 🐒⌨️ Monkeytype Reporting Workflows

Automated reporting system built on MongoDB + n8n + Discord.

Monkeytype → MongoDB → n8n → Discord

Each report is designed with a distinct purpose, not just different time ranges.

---

## 🐒⌨️ Daily Report — “Did I practice today?”

Purpose:
- Track daily activity
- Show immediate improvement
- Maintain streak awareness
- Highlight new personal bests

Data:
- Tests today
- Avg WPM vs yesterday
- Accuracy vs yesterday
- Consistency vs yesterday
- Total time typed
- Current streak
- Milestones

Highlights:
- New WPM PB
- New raw WPM PB
- Accuracy improvements
- Streak tracking

Style:
- Color: Purple
- Tone: Quick check-in

---

## 🐒📆 Weekly Report — “Am I improving?”

Purpose:
- Compare progress week-over-week
- Identify best performance days
- Track practice volume

Data:
- Tests this week vs last week
- Time typed vs last week
- Avg WPM vs last week
- Accuracy vs last week
- Consistency vs last week
- Best day
- Most active day

Highlights:
- Weekly PBs
- Increased practice volume
- Increased typing time

Style:
- Color: Green
- Tone: Progress review

---

## 🐒🗓️ Monthly Report — “What patterns are emerging?”

Purpose:
- Identify long-term trends
- Measure consistency
- Highlight strongest weeks

Data:
- Total tests
- Total time typed
- Active days in month
- Avg WPM vs last month
- Accuracy vs last month
- Consistency vs last month
- Best week
- Most active week

Highlights:
- Strong consistency
- Monthly PBs
- Increased practice time

Style:
- Color: Gold
- Tone: Performance analysis

---

## 🐒🎆 Year-End Report — “What did I accomplish?”

Purpose:
- Celebrate the year’s progress
- Summarize total effort
- Highlight major achievements

Data:
- Total tests
- Total time typed
- Avg WPM
- Best WPM
- Best raw WPM
- Avg accuracy
- Avg consistency
- Active days
- Longest streak
- Best month
- Most active month

Highlights:
- Total effort summary
- Hours spent typing
- Longest streak
- All-time PBs

Style:
- Color: Blue
- Tone: Celebration

---

## ⏱️ Scheduling (n8n Cron)

Format:
[Second] [Minute] [Hour] [Day of Month] [Month] [Day of Week]

Daily:   0 59 23 * * *
Weekly:  0 59 23 * * 0
Monthly: 0 59 23 28-31 * *
Yearly:  0 5 0 1 1 *

---

## 🧠 Design Principles

- Each report answers a different question
- Highlight change, not just totals
- Show milestones only when meaningful
- Keep reports readable

---

## 🚀 Future Improvements

- Trend graphs
- Real-time PB notifications
- Performance scoring
- Historical dashboards

🐒⌨️ Monkeytype reporting turns typing data into actionable insights.
