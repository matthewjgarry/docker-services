# 🐳 docker-services

A modular, reproducible Docker stack for a homelab — built around **secure secrets**, **internal HTTPS**, and **automation-first deployment**.

Pairs with host bootstrap repo:
👉 https://github.com/matthewjgarry/linux-environments

---

## 🧠 Philosophy

* 🔁 **Reproducible** — rebuild everything from scratch
* 🔐 **Secure by default** — SOPS + age for secrets
* 🧩 **Composable** — consistent service patterns
* 🌐 **Layered networking** — DNS → proxy → apps
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

  ```text
  https://search.wormlogic.com
  ```

* ⌨️ Monkeytype

  ```text
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
secrets/
config/
runtime/      # ignored
scripts/
```

---

## 🧠 Patterns

* Services communicate via **Docker network**
* No unnecessary host port exposure
* One database/user per app (future-ready)
* Optional services grouped via **Compose profiles**

---

## ⚠️ Notes

* Internal HTTPS via **Cloudflare DNS-01**
* No public exposure yet (VPN planned)
* Optional features (Firebase, email, etc.) are disabled by default

---

## 🔜 Next

* 🔐 VPN access layer
* 🤖 n8n integration
* 💾 Backup strategy
* 🌍 selective public exposure

---

## 🤝 Related

👉 https://github.com/matthewjgarry/linux-environments

---

💡 *If you can’t rebuild it, you don’t own it.*
