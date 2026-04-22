# 🐳 docker-services

A modular, reproducible Docker stack for homelab services — focused on **secure secrets**, **clean networking**, and **automation-first deployment**.

Pairs with host bootstrap repo:
👉 https://github.com/matthewjgarry/linux-environments

---

## 🧠 Philosophy

* 🔁 **Reproducible** — rebuild from scratch reliably
* 🔐 **Secure by default** — secrets encrypted with SOPS + age
* 🧩 **Composable** — services follow a consistent pattern
* 🌐 **Separated networking** — infra and apps stay isolated
* ⚙️ **Automation-first** — scripts enforce correct state

---

## 🏗️ Current Stack

| Service    | Purpose                                | Network                  |
| ---------- | -------------------------------------- | ------------------------ |
| 🧱 Pi-hole | DNS filtering (static IP for OPNsense) | `home_network` (macvlan) |
| 🌐 Caddy   | Reverse proxy / edge router            | `proxy_network`          |
| 🔎 SearXNG | Private metasearch engine              | `proxy_network`          |

---

## 🌐 Networking Model

```id="s9g4k2"
LAN / OPNsense
      │
   Pi-hole (static IP)
      │
Docker Host
  ├── Caddy
  └── SearXNG
```

**Key points:**

* Pi-hole is **not proxied**
* Pi-hole uses **macvlan + static IP**
* Caddy handles **all web services**
* Apps share an internal **proxy network**

---

## 🔐 Secrets

Managed with:

* 🔑 age
* 🛡️ SOPS

```id="j1x7o2"
secrets/        → encrypted (.enc)
runtime/        → decrypted (ignored)
```

Decrypt:

```bash id="a9k2m1"
./scripts/decrypt-secrets.sh
```

---

## ⚙️ Environment

Per-host config:

```bash id="q3x7w1"
cp env/server01.env.example env/server01.env
```

Example:

```dotenv id="d2m7p4"
TZ=America/New_York

PIHOLE_PARENT_INTERFACE=eno1
PIHOLE_IPV4_ADDRESS=10.42.42.11

SEARXNG_HOSTNAME=search.home.arpa
SEARXNG_BASE_URL=http://search.home.arpa:8080
SEARXNG_SECRET=<generated>
```

---

## 🚀 Usage

```bash id="z7m2c9"
./scripts/up.sh        # start stack (decrypt + validate + up)
./scripts/down.sh      # stop stack
./scripts/validate.sh  # validate config only
```

---

## 🔍 Access

* **Pi-hole:**

  ```id="k8x3m2"
  http://<pihole-ip>
  ```

* **SearXNG (via Caddy):**

  ```id="n2v9k1"
  http://search.home.arpa:8080
  ```

Requires DNS:

```id="p4l8c7"
search.home.arpa → <docker-host-ip>
```

---

## 📁 Structure

```id="u7f3x1"
compose.yaml
env/
secrets/
config/
runtime/      # ignored
scripts/
```

---

## 🧩 Pattern

```id="y2q8b6"
config/   → service config
secrets/  → encrypted
runtime/  → decrypted
compose   → orchestration
```

---

## ⚠️ Current State

* HTTP only (`:8080`)
* No TLS yet
* No public exposure
* No backup system (config only via Git)

---

## 🔜 Next

* 🔒 Proper HTTPS (DNS-01)
* 🌍 Public/private domain split
* 🔎 SearXNG tuning
* ➕ More services (n8n, Postgres, etc.)
* 💾 Backup strategy

---

## 🤝 Related

👉 https://github.com/matthewjgarry/linux-environments

---

💡 *If you can’t rebuild it, you don’t own it.*
