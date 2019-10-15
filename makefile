#!/usr/bin/make
include .env
export

.PHONY: help
.DEFAULT_GOAL := help

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Initialize work

init: ## Start a new develop enviroment
	cp .env.example .env
	docker-compose up -d
	$(MAKE) install
	$(MAKE) publish
	$(MAKE) generate
	sleep 10
	$(MAKE) migrate
	$(MAKE) dump
	$(MAKE) seed
	docker-compose down

publish: ## Publish package changes
	docker exec -it ${APP_PHP_SERVICE} bash -c "su -c \"php artisan vendor:publish --tag=laravelroles && php artisan vendor:publish --tag=laravel2step\" application"

generate: ## Generate application key
	docker exec -it ${APP_PHP_SERVICE} bash -c "su -c \"php artisan key:generate\" application"

##@ Docker actions

dev: ## Start containers desatached
	docker-compose up -d

logs: ## Show the output logs
	docker-compose logs

log: ## Open the logs and follow the news
	docker-compose logs --follow

##@ Database tools

migrate: ## Perform migrations
	docker exec -it ${APP_PHP_SERVICE} bash -c "su -c \"php artisan migrate\" application"

seed: ## Perform seeds
	docker exec -it ${APP_PHP_SERVICE} bash -c "su -c \"php artisan db:seed\" application"

db-export: ## Export database
	docker exec -it ${APP_MYSQL_SERVICE}\
     bash -c "mysqldump -u root -p database > /var/www/app/database/dump.sql"
	docker exec -it ${APP_MYSQL_SERVICE}\
     bash -c "chown 1000:1000 /var/www/app/database/dump.sql"

db-import: ## Import database
	docker exec -it ${APP_MYSQL_SERVICE}\
     bash -c "mysql -u root -p database < /var/www/app/database/dump.sql"

##@ Composer

install: ## Install Composer dependencies
	docker exec -it ${APP_PHP_SERVICE} bash -c "su -c \"composer install\" application"

dump: ## Run the Composer command dump
	docker exec -it ${APP_PHP_SERVICE} bash -c "su -c \"composer dump-autoload\" application"

