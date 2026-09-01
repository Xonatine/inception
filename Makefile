# /NAME        = inception
# COMPOSE_FILE = /srcs/docker-compose.yml
# DATA_PATH   = /home/$(USER)/data

# all:up

# up:
# 	@mkdir -p $(DATA_PATH)/db
# 	@mkdir -p $(DATA_PATH)/wordpress
# 	docker compose -f $(COMPOSE_FILE) up --build -d

# down:
# 	docker compose -f $(COMPOSE_FILE) down

# clean: down
# 	docker system prune -a -f

# fclean: clean
# 	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
# 	@rm -rf $(DATA_PATH)

# re: fclean all

# ps:
# 	docker ps

# mariadbLogs:
# 	docker logs mariadb

# wordpressLogs:
# 	docker logs wordpress

# nginxLogs:
# 	docker logs nginx

# .PHONY: all up down clean fclean re ps mariadbLogs wordpressLogs nginxLogs


# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/$(USER)/data


all: build up

# Create data directories
$(DATA_DIR)/mariadb:
    mkdir -p $(DATA_DIR)/mariadb

$(DATA_DIR)/wordpress:
    mkdir -p $(DATA_DIR)/wordpress

# Build images
build: $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
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