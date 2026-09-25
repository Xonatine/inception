*This project has been created as part of the 42 curriculum by frlorenz.*

# Inception

## Description

Inception is a System Administration project whose goal is to build a small, production-style web infrastructure entirely with Docker, without relying on any pre-built service images. The whole stack is orchestrated with Docker Compose and runs inside a dedicated virtual machine (Debian 12 "bookworm").

The infrastructure is made up of three custom-built Docker images, each running in its own container:

- **NGINX** — the single entrypoint of the infrastructure, serving HTTPS traffic over TLSv1.2/TLSv1.3 on port 443 only.
- **WordPress + PHP-FPM** — the WordPress application, running without any embedded web server (NGINX proxies PHP requests to it over FastCGI on port 9000).
- **MariaDB** — the database backend used by WordPress, not reachable from outside the Docker network.

Data persistence is handled through two Docker named volumes (WordPress files and the MariaDB database), both stored under `/home/frlorenz/data` on the host. All three containers communicate through a single custom Docker bridge network, with no exposed ports other than NGINX's 443.

## Instructions

### Prerequisites

- A Debian 12 (bookworm) virtual machine, with Docker Engine and the Docker Compose plugin installed.

### Setup

1. Clone the repository.
2. Create the `secrets/` folder at the project root containing:
   - `db_root_password.txt`
   - `db_password.txt`
   - `wp_admin_password.txt`
3. Fill in `srcs/.env` with your own values.

### Running the project

```bash
make            # builds all images and starts every container
make down       # stops and removes the containers
make clean      # stops containers and removes images/volumes
make fclean     # full cleanup, including persisted data on disk
make re         # fclean + make
```

### Accessing the site

Open `https://frlorenz.42.fr` in a browser the WordPress admin panel is available at `https://frlorenz.42.fr/wp-admin`.

## Project description

### Why Docker for this project

Docker lets each service (web server, application, database) run in an isolated, reproducible environment while sharing the host's kernel, instead of simulating a whole machine per service. This keeps the stack lightweight, makes it easy to rebuild a service in isolation, and mirrors how real production infrastructures are commonly deployed today.

### Virtual Machines vs Docker

A Virtual Machine virtualizes an entire computer, including its own kernel, which makes it heavier, slower to boot, and more resource-hungry, but fully isolated from the host. A Docker container instead shares the host's kernel and only packages the application and its dependencies, making it start in seconds and consume a fraction of the resources. In this project, Docker was the right choice for running multiple lightweight, disposable services side by side, while the VM itself provides the outer layer of isolation that the school's evaluation setup requires.

### Secrets vs Environment Variables

Plain environment variables (as set in `.env` or `docker-compose.yml`) are visible in plaintext through `docker inspect`, in the container's `/proc/<pid>/environ`, and sometimes in logs — anyone with access to the Docker daemon or the host can read them. Docker secrets, instead, are mounted as read-only files inside `/run/secrets/` at runtime, are not persisted in the image or in `docker inspect` output, and can have restricted file permissions. This project uses `.env` only for non-sensitive configuration (domain name, database name, usernames) and Docker secrets for every password.

### Docker Network vs Host Network

With `network: host`, a container shares the host's network namespace directly, losing isolation and making port management explicit and error-prone. A custom Docker bridge network, which this project uses, gives each container its own network namespace plus automatic DNS resolution between containers by service name (e.g. `wordpress` resolves to the WordPress container's internal IP) — so hostnames keep working even if a container restarts and gets a new IP. This is also why the subject explicitly forbids `network: host` and `--link`.

### Docker Volumes vs Bind Mounts

A bind mount ties a container path directly to an arbitrary host path, with no lifecycle management from Docker and less flexible permission handling. A named volume is managed by Docker itself (created, listed, and removed through the Docker CLI/API), and its data survives container recreation regardless of the specific host path. This project uses named volumes with `driver_opts` (`type: none`, `o: bind`) to force their underlying storage location to `/home/frlorenz/data`, satisfying both the subject's requirement of named volumes and the requirement that data be visible at that specific host path.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [WP-CLI documentation](https://wp-cli.org/)
- [WordPress Codex](https://developer.wordpress.org/)

### AI usage

An AI assistant (Claude) was used throughout this project as a debugging and learning aid.