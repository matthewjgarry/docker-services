# 🐳 docker-services — Automated Container Platform

> Declarative Docker environment with integrated monitoring, alerting, and event-driven automation.

---

## 🚀 Overview

This repository manages your **container runtime layer**, including:

* 🐳 Docker Compose orchestration
* 📡 Monitoring + health checks
* 🔔 Event emission into n8n
* 🧠 Integration with centralized alerting + reporting
* 🔐 Local secret management (no secrets in Git)

---

## ⚠️ Current State

This project is operational for the current homelab, but it is **not yet fully self-deployable**.

It currently assumes:

- host bootstrap is handled by `linux-environments`
- secrets are restored locally
- n8n is already configured
- Postgres schema exists
- Discord webhooks are created manually
- internal DNS points service hostnames at the Docker host

The long-term goal is full rebuild-from-scratch automation, but this repo still has manual setup steps by design.

---

## 🏗️ Architecture

```text
                ┌──────────────────────────────┐
                │     linux-environments       │
                │ (host bootstrap + services)  │
                └──────────────┬───────────────┘
                               │
                               ▼
                ┌──────────────────────────────┐
                │       docker-services        │
                │   (this repository)          │
                │                              │
                │  • docker compose            │
                │  • monitoring scripts        │
                │  • systemd timers            │
                └──────────────┬───────────────┘
                               │
                               ▼
                ┌──────────────────────────────┐
                │        emit-event.sh         │
                │  (structured event output)   │
                └──────────────┬───────────────┘
                               │
                               ▼
                ┌──────────────────────────────┐
                │             n8n              │
                │                              │
                │  • dedupe / suppression      │
                │  • escalation logic          │
                │  • recovery detection        │
                │  • routing decisions         │
                └──────────────┬───────────────┘
                               │
              ┌────────────────┴───────────────┐
              ▼                                ▼
    ┌──────────────────────┐        ┌────────────────────────┐
    │      Postgres        │        │        Discord         │
    │                      │        │                        │
    │  incidents           │        │  🚨 alerts             │
    │  incident_events     │        │  🐳 containers         │
    │                      │        │  📊 reports            │
    └──────────────────────┘        └────────────────────────┘
```

---

## ⚙️ Core Responsibilities

### 🐳 Container Orchestration

* Centralized `docker compose` configuration
* Multi-service management
* Clean startup / shutdown lifecycle

---

### 📡 Monitoring System

Systemd timers execute checks:

| Check            | Purpose                      |
| ---------------- | ---------------------------- |
| 🩺 startup-check | validate services after boot |
| 📊 monitor       | continuous health checks     |
| 💽 disk-check    | disk usage alerts            |
| 🐳 image-check   | stale container detection    |

---

### 🔔 Event Emission

All checks emit structured events via:

```bash
scripts/emit-event.sh
```

Example:

```json
{
  "source": "docker-services",
  "hostname": "server01",
  "service": "docker",
  "check_name": "container-health",
  "severity": "error",
  "title": "Container failure",
  "message": "nginx is unhealthy"
}
```

---

## 🔗 n8n Integration

Events are sent to:

```text
$N8N_EVENT_WEBHOOK_URL
```

n8n handles:

* 🧹 deduplication
* 🔁 escalation
* ♻️ recovery detection
* 🗄️ Postgres persistence
* 🚨 alert routing
* 📊 daily + weekly summaries

---

## 🧠 Event Flow

```text
docker-services
  ↓
emit-event.sh
  ↓
n8n webhook
  ↓
Code (normalize + dedupe)
  ↓
Postgres
  ├─ incidents (active state)
  └─ incident_events (history)
  ↓
IF (alert logic)
  ↓
Discord alerts + reports
```

---

## 🔐 Secrets & Configuration

Secrets are stored locally:

```text
~/.config/docker-services/
  ├─ discord-webhook
  ├─ n8n-webhook
```

Environment config:

```text
env/server01.env
```

---

## 🧱 Reproducibility Model

Designed for rebuild flow:

```text
1. bootstrap host (linux-environments)
2. clone docker-services
3. restore secrets
4. install monitoring units
5. start containers
```

---

## 🛠️ Installation

```bash
git clone https://github.com/matthewjgarry/docker-services.git
cd docker-services
cp env/example.env env/server01.env
./scripts/install-monitoring-units.sh
docker compose --env-file env/server01.env up -d
```

---

## 🧪 Testing

### Emit test event

```bash
./scripts/emit-event.sh \
  "docker-services" \
  "test-check" \
  "error" \
  "Test Event" \
  "This is a test" \
  "docker"
```

---

### Run startup check

```bash
sudo systemctl start docker-services-startup-check.service
```

---

### View logs

```bash
journalctl -u docker-services-monitor.service -n 50 --no-pager
```

---

## 🚨 Alerting Model

### Local

* container-level Discord webhook

### Centralized (n8n)

* alerts-only channel 🚨
* deduplicated
* escalated
* state-aware

---

## 📊 Monitoring Philosophy

### 🔕 Signal > Noise

* suppression windows
* escalation thresholds

### 🧠 Event-Driven

Everything is:

```
event → decision → action
```

### ♻️ System-Oriented

This is not just monitoring—it is a **feedback loop**.

---

## 🧯 What Breaks If Misconfigured?

### 🌐 Caddy / DNS

| Symptom | Likely Cause | Fix |
|---|---|---|
| Service does not load | hostname missing from internal DNS | add DNS record or wildcard |
| Cert does not issue | Cloudflare token missing/invalid | verify Caddy env secret |
| New route ignored | Caddy still using old config | `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile` |

---

### 🔐 Secrets

| Symptom | Likely Cause | Fix |
|---|---|---|
| Compose warns variables are blank | env file not loaded | use `--env-file env/server01.env` |
| Service starts but auth fails | decrypted runtime secret missing | run decrypt script |
| n8n encryption error | key changed after first boot | preserve `N8N_ENCRYPTION_KEY` |

---

### 🧠 n8n

| Symptom | Likely Cause | Fix |
|---|---|---|
| Webhook returns 404 | workflow inactive or test URL expired | activate workflow and use `/webhook/events` |
| Events arrive but no alert | suppressed or severity not alert-worthy | check Code output + IF node |
| Alert IF always false | previous node replaced `$json` | reference `Code - Normalize Incident` directly |
| Daily summary all zeroes | Code node wired to schedule instead of Postgres | connect `Schedule → Postgres → Code` only |

---

### 🗄️ Postgres

| Symptom | Likely Cause | Fix |
|---|---|---|
| n8n cannot connect | using `localhost` | use host `postgres` |
| Table missing | schema not created | run SQL setup |
| Active incident missing | upsert node not reached | check workflow execution path |
| History empty | `incident_events` node not reached | verify it runs after incident upsert |

---

### 📡 Monitoring

| Symptom | Likely Cause | Fix |
|---|---|---|
| No n8n event from script | `N8N_EVENT_WEBHOOK_URL` missing | add runtime/env secret |
| No Discord from systemd | service environment differs from shell | load env/secrets in script |
| Systemd unit not found | user vs system unit mismatch | try `systemctl --user` |
| Monitor sends nothing | no state change detected | force a container stop/start test |

---

### 🐳 Docker Networking

| Symptom | Likely Cause | Fix |
|---|---|---|
| n8n cannot reach Postgres | wrong host | use `postgres:5432` inside Docker network |
| Host cannot reach Postgres | port intentionally not published | use `docker compose exec postgres psql ...` |
| Container route fails through Caddy | service not on proxy network | attach service to Caddy network |

---

## 📈 Future Direction

* 🔁 auto-remediation workflows
* 📊 dashboards (Grafana)
* 📉 trend analysis
* 🔐 improved secret management
* 🚀 full self-deployment pipeline

---

## ⚡ TL;DR

```text
Compose → Monitor → Emit → n8n → Store → Alert → Report

linux-environments
        │
        ▼
docker-services ──► emit-event.sh
        │
        ▼
       n8n
   (dedupe / logic)
        │
   ┌────┴────┐
   ▼         ▼
Postgres   Discord
(state)    (alerts + reports)
```

---

## 🧭 Related

* linux-environments → host bootstrap + system setup
* n8n → automation + orchestration

---

## 🧑‍💻 Author

Matthew Garry

---

## 🪪 License

MIT
