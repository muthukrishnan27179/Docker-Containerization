# 🐳 Docker & Containerization: Production-Grade Multi-Tier Web Application

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)
![Python](https://img.shields.io/badge/Python_3.11-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL_16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis_7-DC382D?style=for-the-badge&logo=redis&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)

A comprehensive, industry-standard project demonstrating **Docker fundamentals, Multi-Stage Dockerfile optimizations, Container Networking, Persistent Volumes, and Multi-Service Orchestration with Docker Compose**.

---

## 📑 Curriculum & Documentation Index

| Module | Title | Description |
| :--- | :--- | :--- |
| **01** | [Containers vs. Virtual Machines](docs/01-containers-vs-vms.md) | Architecture, Linux namespaces (`pid`, `net`, `mnt`), `cgroups`, and hypervisor differences. |
| **02** | [Docker Architecture Deep Dive](docs/02-docker-architecture.md) | Client, Daemon (`dockerd`), containerd, runc, OCI specifications, images, and registries. |
| **03** | [Dockerfile Optimization & Best Practices](docs/03-dockerfile-optimization.md) | Multi-stage builds, layer caching order, slim/alpine base images, and non-root security. |
| **04** | [Docker Commands, Networking & Volumes](docs/04-docker-commands-networking-volumes.md) | Essential CLI cheat sheet, bridge networks, DNS service discovery, and volume persistence. |
| **05** | [Docker Compose & Orchestration](docs/05-docker-compose-orchestration.md) | Multi-container coordination, healthcheck dependencies, and dev vs prod overrides. |
| **Deliverables**| [Submission Deliverables Guide](DELIVERABLES.md) | Instructions for GitHub repository push and ready-to-publish LinkedIn post. |

---

## 🏗️ Architectural Topology

```
                                  [ User Browser ]
                                         │
                                         ▼ Port 80 (HTTP)
                       ┌───────────────────────────────────┐
                       │           Docker Host             │
                       │                                   │
                       │   ┌───────────────────────────┐   │
                       │   │  reverse-proxy (Nginx)    │   │
                       │   └─────────────┬─────────────┘   │
                       │                 │ frontend-network│
                       │                 ▼                 │
                       │   ┌───────────────────────────┐   │
                       │   │   web-app (Flask/Gunicorn)│   │
                       │   │   (Port 5000)             │   │
                       │   └───────┬───────────┬───────┘   │
                       │           │           │           │
                       │           │ backend-network       │
                       │           ▼           ▼           │
                       │    ┌─────────────┐ ┌────────────┐ │
                       │    │postgres-db  │ │redis-cache │ │
                       │    │(Port 5432)  │ │(Port 6379) │ │
                       │    └──────┬──────┘ └─────┬──────┘ │
                       │           │              │        │
                       │           ▼              ▼        │
                       │      [postgres_data] [redis_data] │
                       │          (Persistent Volumes)     │
                       └───────────────────────────────────┘
```

### Network Segmentation & Security
- **`frontend-network`**: Connects the reverse proxy (`nginx`) to the application backend (`web`).
- **`backend-network`**: Connects the application backend (`web`) to `db` (Postgres) and `cache` (Redis).
- *Security Benefit*: The database and Redis instances are **completely unreachable** from outside the host; they communicate exclusively through the internal Docker bridge network.

---

## 🚀 End-to-End Pipeline: Source Code to Running Application

1. **Source Code**: Python 3.11 Flask application with interactive telemetry dashboard, task management API, Redis cache-aside layer, and PostgreSQL persistence.
2. **Dockerfile**: Production multi-stage build:
   - *Stage 1 (Builder)*: Installs `gcc`, `libpq-dev`, builds Python wheels.
   - *Stage 2 (Runtime)*: Uses lean `python:3.11-slim`, installs pre-compiled wheels, switches to non-root `appuser`, and configures healthchecks.
3. **Image**: Minimal OCI container image with zero compilers or build dependencies.
4. **Container**: Isolated, ephemeral process instances managed by `runc` and `containerd`.
5. **Docker Compose**: Coordinates the 4 services, establishes health checks (`condition: service_healthy`), mounts persistent volumes, and wires private bridge networks.
6. **Running Application**: Highly available, responsive full-stack application served via Nginx.

---

## ⚡ Quick Start & Hands-On Verification

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed on Windows/macOS or Docker Engine + Docker Compose on Linux.

### 1. Launch the Stack
Run the following command from the project root:

```bash
docker compose up -d --build
```

### 2. Verify Service Health
Check the real-time status of all four containers:

```bash
docker compose ps
```

*Expected Output:*
```text
NAME                IMAGE                  COMMAND                  SERVICE         STATUS                    PORTS
postgres-db         postgres:16-alpine     "docker-entrypoint.s…"   db              Up (healthy)              5432/tcp
redis-cache         redis:7-alpine         "docker-entrypoint.s…"   cache           Up (healthy)              6379/tcp
reverse-proxy       docker-reverse-proxy   "nginx -g 'daemon of…"   reverse-proxy   Up (healthy)              0.0.0.0:80->80/tcp
web-app             docker-web             "gunicorn --bind 0.0…"   web             Up (healthy)              0.0.0.0:5000->5000/tcp
```

### 3. Open the Application
Navigate in your browser to:
- **Primary (via Nginx Reverse Proxy)**: [`http://localhost`](http://localhost)
- **Direct Application Port**: [`http://localhost:5000`](http://localhost:5000)

### 4. Interactive Verification Features
- **Container Telemetry**: Real-time display of Container ID, Host OS kernel, Python version, memory usage, and IP address.
- **Database & Cache Diagnostics**: Real-time status indicators for PostgreSQL connectivity and Redis cache hit/miss metrics.
- **Volume Persistence Test**:
  1. Add a custom task in the dashboard (e.g. *"Verify Docker Volume Persistence"*).
  2. Stop and delete the containers:
     ```bash
     docker compose down
     ```
  3. Recreate the containers:
     ```bash
     docker compose up -d
     ```
  4. Refresh the browser. Your task remains intact because it was safely persisted to the `postgres_data` Docker volume!

---

## 🛠️ Docker CLI Quick Reference

```bash
# View live logs
docker compose logs -f web

# Inspect container internal state
docker inspect web-app

# Execute shell in web application
docker compose exec web sh

# Connect directly to Postgres CLI
docker compose exec db psql -U postgres -d taskdb

# Connect directly to Redis CLI
docker compose exec cache redis-cli ping

# Teardown and delete persistent data
docker compose down -v
```

---

## 📂 Repository Structure

```text
docker-containerization-project/
├── app/                        # Web Application Service
│   ├── src/                    # Application source code
│   │   ├── app.py              # Flask application, REST API, healthchecks
│   │   └── config.py           # 12-Factor App environment configuration
│   ├── static/                 # CSS & JavaScript for interactive UI
│   ├── templates/              # Jinja2 HTML Dashboard
│   ├── Dockerfile              # Multi-stage production build
│   ├── Dockerfile.dev          # Development build with live-reloading
│   └── requirements.txt        # Python dependency manifest
├── nginx/                      # Ingress Reverse Proxy Service
│   ├── Dockerfile              # Minimal Nginx Alpine image
│   └── nginx.conf              # Reverse proxy, caching, and upstream definitions
├── docs/                       # Technical Deep-Dive Documentation
│   ├── 01-containers-vs-vms.md
│   ├── 02-docker-architecture.md
│   ├── 03-dockerfile-optimization.md
│   ├── 04-docker-commands-networking-volumes.md
│   └── 05-docker-compose-orchestration.md
├── docker-compose.yml          # Production 4-service orchestration specification
├── docker-compose.dev.yml      # Local development override
├── .dockerignore               # Build context exclusion list
├── .gitignore                  # Git tracking exclusion list
├── DELIVERABLES.md             # GitHub push instructions & LinkedIn post draft
└── README.md                   # Repository overview & setup guide
```

---

## 📜 Submission Deliverables
- **GitHub Repository Setup**: See [DELIVERABLES.md](DELIVERABLES.md#deliverable-1-github-repository-link) for the step-by-step git push commands.
- **LinkedIn Post Copy**: See [DELIVERABLES.md](DELIVERABLES.md#deliverable-2-linkedin-post-link) for the ready-to-publish post text with emojis and hashtags.

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).
