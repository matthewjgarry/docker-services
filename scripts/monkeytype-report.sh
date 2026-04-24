#!/usr/bin/env bash
set -euo pipefail

UID_FILTER="${1:-WbdqpIgNzoTvEM0RqkMYkUFhW8l2}"
PERIOD="${2:-daily}"

case "$PERIOD" in
  daily)
    START_MS=$(date -d "today 00:00" +%s000)
    LABEL="daily"
    ;;
  weekly)
    NOW_SECONDS=$(date +%s)
    DOW=$(date +%u)
    START_SECONDS=$(( NOW_SECONDS - ((DOW - 1) * 86400) ))
    START_MS=$(date -d "@$START_SECONDS" +%Y-%m-%d | xargs -I{} date -d "{} 00:00" +%s000)
    LABEL="weekly"
    ;;
  monthly)
    START_MS=$(date -d "$(date +%Y-%m-01) 00:00" +%s000)
    LABEL="monthly"
    ;;
  all)
    START_MS=0
    LABEL="all"
    ;;
  *)
    echo "Usage: $0 [uid] [daily|weekly|monthly|all]" >&2
    exit 1
    ;;
esac

docker compose --env-file ./env/server01.env --profile apps exec -T monkeytype-mongodb \
  mongosh monkeytype --quiet --eval "
const uid = '$UID_FILTER';
const startMs = NumberLong('$START_MS');
const period = '$LABEL';

const result = db.results.aggregate([
  {
    \$match: {
      uid,
      timestamp: { \$gte: startMs }
    }
  },
  {
    \$group: {
      _id: null,
      tests: { \$sum: 1 },
      avgWpm: { \$avg: '\$wpm' },
      bestWpm: { \$max: '\$wpm' },
      avgRawWpm: { \$avg: '\$rawWpm' },
      bestRawWpm: { \$max: '\$rawWpm' },
      avgAcc: { \$avg: '\$acc' },
      avgConsistency: { \$avg: '\$consistency' },
      totalTestSeconds: { \$sum: '\$testDuration' },
      latestTimestamp: { \$max: '\$timestamp' }
    }
  },
  {
    \$project: {
      _id: 0,
      uid,
      period,
      since: { \$toDate: startMs },
      tests: 1,
      avgWpm: { \$round: ['\$avgWpm', 2] },
      bestWpm: { \$round: ['\$bestWpm', 2] },
      avgRawWpm: { \$round: ['\$avgRawWpm', 2] },
      bestRawWpm: { \$round: ['\$bestRawWpm', 2] },
      avgAcc: { \$round: ['\$avgAcc', 2] },
      avgConsistency: { \$round: ['\$avgConsistency', 2] },
      totalMinutesTyped: { \$round: [{ \$divide: ['\$totalTestSeconds', 60] }, 2] },
      latestResultAt: { \$toDate: '\$latestTimestamp' }
    }
  }
]).toArray()[0] || {
  uid,
  period,
  since: new Date(Number(startMs)),
  tests: 0,
  avgWpm: null,
  bestWpm: null,
  avgRawWpm: null,
  bestRawWpm: null,
  avgAcc: null,
  avgConsistency: null,
  totalMinutesTyped: 0,
  latestResultAt: null
};

print(JSON.stringify(result, null, 2));
"
