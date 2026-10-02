# Round-robin load balancer with Docker and Nginx

A minimal project to understand **load balancing**: an Nginx load balancer
distributes requests across 3 Docker servers.

```
                    ┌──────────────┐      ┌─────────────┐
 Clients ─────────► │ Load balancer│ ───► │ Server A    │
  (localhost:8080)  │   (Nginx)    │ ───► │ Server B    │
                    └──────────────┘ ───► │ Server C    │
                                          └─────────────┘
```

## Docker images used

The project uses **2 images**:

| Image | Role | Why |
|-------|------|-----|
| `nginx:alpine` | Load balancer | Nginx is a widely used web server / reverse proxy. The `alpine` variant is very lightweight (~40 MB). |
| `hashicorp/http-echo` | Backend servers (A, B, C) | A tiny web server that simply replies with a text configured at startup. Ideal for seeing which server answered. |

## Number of containers

The `docker-compose.yml` starts **4 containers**:

| Container | Image | Role |
|-----------|-------|------|
| `serveur-a` | `hashicorp/http-echo` | Backend A (replies "Réponse du serveur A") |
| `serveur-b` | `hashicorp/http-echo` | Backend B (replies "Réponse du serveur B") |
| `serveur-c` | `hashicorp/http-echo` | Backend C (replies "Réponse du serveur C") |
| `load-balancer` | `nginx:alpine` | Entry point, distributes requests across A, B and C |

Only the load balancer is reachable from the host machine (port `8080`).
The 3 servers can only be reached through the load balancer, via Docker Compose's internal network.

## How `docker-compose.yml` and `nginx.conf` are linked

The two files are connected in **4 ways**:

### 1. The config file is mounted into the container

In `docker-compose.yml`:

```yaml
volumes:
  - ./nginx.conf:/etc/nginx/nginx.conf:ro
```

The project's `nginx.conf` replaces Nginx's default configuration inside the container
(`:ro` = read-only). Editing `nginx.conf` therefore changes the behavior of the load balancer.

### 2. Service names become hostnames

In `docker-compose.yml`, the services are named `serveur-a`, `serveur-b` and `serveur-c`.
Docker Compose creates an internal network where each service name is a **DNS name**:

```nginx
upstream backend {
    server serveur-a:5678;
    server serveur-b:5678;
    server serveur-c:5678;
}
```

Nginx doesn't need IP addresses: it uses the names defined in the Compose file.

### 3. The ports match

| File | Port | Meaning |
|------|------|---------|
| `docker-compose.yml` | `8080:80` | Port 8080 on the host → port 80 of the Nginx container |
| `nginx.conf` | `listen 80;` | Nginx listens on port 80 inside its container |
| `nginx.conf` | `serveur-a:5678` | Port 5678 = default port of `http-echo` |

### 4. Startup order

```yaml
depends_on:
  - serveur-a
  - serveur-b
  - serveur-c
```

The load balancer starts after the 3 servers, because Nginx must be able to resolve their names at startup.

## Running the project

Prerequisites: Docker and Docker Compose.

```bash
docker compose up -d
chmod +x test.sh
./test.sh
```

Expected result: the responses alternate between A, B and C.

```
Request 1 -> Response from server A
Request 2 -> Response from server B
Request 3 -> Response from server C
Request 4 -> Response from server A
...
```

Stop: `docker compose down`

## Project structure

```
.
├── docker-compose.yml   # defines the 4 containers
├── nginx.conf           # load balancer configuration (mounted into the container)
├── test.sh              # test script (9 requests)
└── README.md
```