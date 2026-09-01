# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/$(USER)/data

all: build up

# Build images
build:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) build

# Start services
up:
	docker compose -f $(COMPOSE_FILE) up -d

# Stop services
down:
	docker compose -f $(COMPOSE_FILE) down

# Clean containers and images
clean:
	docker compose -f $(COMPOSE_FILE) down
	docker system prune -af

# Full clean including volumes
fclean: clean
	docker volume prune -f
	sudo rm -rf $(DATA_DIR)

# Rebuild everything
re: fclean all

ps:
	docker ps

mariadbLogs:
	docker logs mariadb

wordpressLogs:
	docker logs wordpress

nginxLogs:
	docker logs nginx

.PHONY: all build up down clean fclean re ps mariadbLogs wordpressLogs nginxLogs