# 🐳 docker-services

A modular, reproducible Docker stack for a homelab — built around **secure secrets**, **internal HTTPS**, and **host-level monitoring & automation**.

Pairs with host bootstrap repo:
👉 https://github.com/matthewjgarry/linux-environments

---

## 🧠 Philosophy

* 🔁 **Reproducible** — rebuild everything from scratch
* 🔐 **Secure by default** — SOPS + age for secrets
* 🧩 **Composable** — consistent service patterns
* 🌐 **Layered networking** — DNS → proxy → apps
* 📡 **Observable** — systemd + Discord notifications
* ⚙️ **Automated** — scripts enforce correct state

---

## 🏗️ Current Stack

| Service       | Purpose             | Notes                          |
| ------------- | ------------------- | ------------------------------ |
| 🧱 Pi-hole    | DNS filtering       | macvlan + static IP (OPNsense) |
| 🌐 Caddy      | Reverse proxy + TLS | Cloudflare DNS-01              |
| 🔎 SearXNG    | Private search      | internal HTTPS                 |
| 🗄️ Postgres  | Database            | internal only                  |
| ⌨️ Monkeytype | Typing app          | optional (`apps` profile)      |

---

## 📡 Monitoring & Alerts

Host-level monitoring is handled via **systemd timers**, not containers.

### Included checks

| Check                | Purpose                     | Frequency     |
| -------------------- | --------------------------- | ------------- |
| 🔄 Container Monitor | Detect state/health changes | every 1 min   |
| 🚀 Startup Check     | Validate stack after boot   | on boot       |
| 💾 Disk Check        | Prevent host exhaustion     | every 6 hours |
| 📦 Image Check       | Detect new container images | daily         |

### Notifications

* 📣 Sent via **Discord webhooks**
* 🧾 JSON embed format (structured, readable)
* 🔀 Separate channel from system bootstrap alerts

Webhook location:

```text
~/.config/docker-services/discord-webhook
```

Install monitoring:

```bash
./scripts/install-monitoring-units.sh
```

---

## 🌐 Networking

```text
LAN / OPNsense
      │
   Pi-hole (DNS)
      │
Docker Host
  ├── Caddy (TLS + routing)
  └── Services (internal)
```

* Pi-hole is **not proxied**
* Caddy handles **all HTTPS**
* Apps live on an internal Docker network
* Services are exposed via **internal DNS + valid certs**

---

## 🔐 Secrets

Managed with:

* 🔑 age
* 🛡️ SOPS

```text
secrets/   → encrypted
runtime/   → decrypted (ignored)
```

Decrypt before running:

```bash
./scripts/decrypt-secrets.sh
```

---

## ⚙️ Environment

Per-host config:

```bash
cp env/server01.env.example env/server01.env
```

Example (trimmed):

```dotenv
TZ=America/New_York

SEARXNG_HOSTNAME=search.wormlogic.com
MONKEYTYPE_HOSTNAME=type.wormlogic.com
MONKEYTYPE_API_HOSTNAME=type-api.wormlogic.com
```

---

## 🚀 Usage

```bash
./scripts/up.sh        # core services
./scripts/up-apps.sh   # core + optional apps
./scripts/down.sh      # stop everything
./scripts/validate.sh  # config checks
```

---

## 🔍 Access

* 🔎 SearXNG

  ```
  https://search.wormlogic.com
  ```

* ⌨️ Monkeytype

  ```
  https://type.wormlogic.com
  ```

Requires internal DNS (OPNsense):

```text
*.wormlogic.com → <docker-host-ip>
```

---

## 🧩 Structure

```text
compose.yaml
env/
config/
secrets/
runtime/      # ignored
scripts/
systemd/      # host-level monitoring units
```

---

## 🧠 Patterns

* Services communicate via **Docker network**
* No unnecessary host port exposure
* One database/user per app (future-ready)
* Optional services grouped via **Compose profiles**
* Monitoring handled at **host level (systemd)**

---

## ⚠️ Notes

* Internal HTTPS via **Cloudflare DNS-01**
* No public exposure yet (VPN planned)
* Monitoring runs outside Docker for reliability
* Optional features (Firebase, email, etc.) are disabled by default

---

## 🔜 Next

* 🔐 VPN access layer
* 🤖 n8n automation
* 💾 Backup strategy + verification
* 🌍 Selective public exposure

---

## 🤝 Related

👉 https://github.com/matthewjgarry/linux-environments

---

💡 *If you can’t rebuild it, you don’t own it.*
