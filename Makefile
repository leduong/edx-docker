# Target OpenEdx release
EDX_ARCHIVE_URL           ?= https://github.com/edx/edx-platform/archive/open-release/lilac.master.tar.gz

# Target OpenEdx demo course release
EDX_DEMO_ARCHIVE_URL      ?= https://github.com/edx/edx-demo-course/archive/lilac.1.tar.gz

# Docker images
EDXAPP_IMAGE_NAME         ?= edxapp
EDXAPP_NGINX_IMAGE_NAME   ?= edxapp-nginx
EDXAPP_IMAGE_TAG          ?= $(EDX_RELEASE)

# Redis service used
REDIS_SERVICE             ?= redis

# Get local user ids
DOCKER_UID              = $(shell id -u)
DOCKER_GID              = $(shell id -g)

# Docker
COMPOSE          = \
  DOCKER_UID=$(DOCKER_UID) \
  DOCKER_GID=$(DOCKER_GID) \
  EDXAPP_IMAGE_TAG=$(EDXAPP_IMAGE_TAG) \
  docker-compose
COMPOSE_SSL      = NGINX_CONF=ssl $(COMPOSE)
COMPOSE_RUN      = $(COMPOSE) run --rm -e HOME="/tmp"
COMPOSE_EXEC     = $(COMPOSE) exec
WAIT_DB          = $(COMPOSE_RUN) dockerize -wait tcp://mysql57:3306 -timeout 60s
WAIT_MG          = $(COMPOSE_RUN) dockerize -wait tcp://mongo:27017 -timeout 60s

# Django
MANAGE_CMS       = $(COMPOSE_EXEC) cms python manage.py cms
MANAGE_LMS       = $(COMPOSE_EXEC) lms python manage.py lms

# Terminal colors
COLOR_DEFAULT = \033[0;39m
COLOR_ERROR   = \033[0;31m
COLOR_INFO    = \033[0;36m
COLOR_RESET   = \033[0m
COLOR_SUCCESS = \033[0;32m
COLOR_WARNING = \033[0;33m

# Shell functions
SHELL=bash
define BASH_FUNC_test-service%%
() {
  local service=$${1:-CMS}
  local environment=$${2:-production}
  local url=$${3:-http://localhost:8000}
  local http_version=$${4:-1.1}

  echo -n "Testing $${service} ($${environment})... "
  if curl -vLk --header "Accept: text/html" "$${url}" 2>&1 \
	| grep "< HTTP/$${http_version} 200 OK" > /dev/null ; then
	echo -e "$(COLOR_SUCCESS)OK$(COLOR_RESET)"
  else
	echo -e "$(COLOR_ERROR)NO$(COLOR_RESET)"
	echo -e "\n$(COLOR_ERROR)--- Error traceback ---"
	curl -vLk --header "Accept: text/html" "$${url}"
	echo -e "--- End error traceback ---$(COLOR_RESET)"
  fi
}
endef
export BASH_FUNC_test-service%%

default: help
check-activate: ## Check if an OpenEdx release version has been activated
check-activate:
	@if [[ -z "${EDX_RELEASE}" ]] ; then\
		echo -e "${COLOR_INFO}You must activate ENV an OpenEdx release first. Copy/paste the text\n${COLOR_RESET}";\
		echo -e "${COLOR_INFO}export EDX_RELEASE=\"lilac.1\"${COLOR_RESET}";\
		echo -e "${COLOR_INFO}export EDX_RELEASE_REF=\"open-release/lilac.1\"${COLOR_RESET}";\
		echo -e "${COLOR_INFO}export EDX_DEMO_RELEASE_REF=\"open-release/lilac.1\"${COLOR_RESET}";\
		exit 1;\
	fi
.PHONY: check-activate

bootstrap: \
  check-activate \
  stop \
  clean \
  initdb \
  build \
  dev-build \
  migrate \
  run
bootstrap:  ## install development dependencies
.PHONY: bootstrap

auth-init: \
  check-activate
auth-init: ## create an oauth client and API credentials
	@echo "Booting mysql service..."
	$(COMPOSE) up -d mysql57
	$(WAIT_DB)
	@$(COMPOSE_RUN) lms python /usr/local/bin/auth_init.py
.PHONY: auth-init

# Build production image. Note that the cms service uses the same image built
# for the lms service.
build: \
  check-activate \
  check-root-user \
  info
build:  ## build the edxapp production image
	@echo "🐳 Building production image..."
	$(COMPOSE) build lms
	$(COMPOSE) build nginx
.PHONY: build

check-root-user:  ## Make sure the user calling this is not currently root
	@if [[ $(shell id -u) -eq 0 ]]; \
	then \
		if [[ "$$ALLOW_ROOT" -ne 1 ]]; then \
			echo -e "We recommend you to not run this as root" ; \
			echo -e "If you want to run a make command as root please set ALLOW_ROOT=1" ; \
			echo -e "(ex: sudo ALLOW_ROOT=1 make bootstrap )\n" ; \
			exit 1 ; \
		fi \
	fi
.PHONY: check-root-user

# As we mount edx-platform as a volume in development, we need to re-create
# symlinks that points to our custom configuration
dev: \
  check-activate
dev:  ## start the cms and lms services (development image and servers)
	# starts lms-dev as well via docker-compose dependency
	$(COMPOSE) up -d cms-dev
	@echo "Wait for services to be up..."
	$(WAIT_DB)
	$(COMPOSE_RUN) dockerize -wait tcp://cms-dev:8000 -timeout 60s
	$(COMPOSE_RUN) dockerize -wait tcp://lms-dev:8000 -timeout 60s
.PHONY: dev

# In development, we work with local directories (on our host machine) for
# static files and for edx-platform sources, and mount them in the container
# (using Docker volumes). Hence, you will need to run the update_assets target
# everytime you update edx-platform sources and plan to develop in it.
dev-assets: \
  check-activate \
  check-root-user \
  dev-install
dev-assets:  ## run update_assets to copy required statics in local volumes
	$(COMPOSE_RUN) --no-deps lms-dev \
		bash -c 'source /edx/app/edxapp/.venv/bin/activate && \
			DJANGO_SETTINGS_MODULE="" NO_PREREQ_INSTALL=1 paver update_assets --settings devstack_decentralized --skip-collect'
.PHONY: dev-assets

# In development, we are mounting edx-platform's sources as a volume, hence,
# since sources are modified during the installation, we need to re-install
# them.
dev-install: \
  check-activate \
  check-root-user
dev-install:  ## Install development dependencies in a virtualenv
	$(COMPOSE_RUN) --no-deps lms-dev \
		bash -c 'source /edx/app/edxapp/.venv/bin/activate && \
			npm set progress=false && npm install && \
			pip install --no-cache-dir -r requirements/edx/development.txt'
.PHONY: dev-install

# Build development image. Note that the cms-dev service uses the same image
# built for the lms-dev service.
dev-build: \
  check-activate \
  check-root-user
dev-build:  ## build the edxapp production image
	@echo "🐳 Building development image..."
	$(COMPOSE) build lms-dev
.PHONY: dev-build

dev-watch: \
  check-activate \
  check-root-user
dev-watch:  ## Start assets watcher (front-end development)
	$(COMPOSE_EXEC) lms-dev paver watch_assets --settings=devstack_docker
.PHONY: dev-watch

info:  ## get activated release info
	@echo -e "\n.:: OPENEDX-DOCKER ::.\n";
	@if [[ -z "${EDX_RELEASE}" ]] ; then\
		echo -e "$(COLOR_INFO)No active configuration.$(COLOR_RESET)";\
	else\
		echo -e "== Active configuration ==\n";\
		echo -e "* EDX_RELEASE                : $(COLOR_INFO)$(EDX_RELEASE)$(COLOR_RESET)";\
		echo -e "* EDX_RELEASE_REF            : $(COLOR_INFO)$(EDX_RELEASE_REF)$(COLOR_RESET)";\
		echo -e "* EDX_ARCHIVE_URL            : $(COLOR_INFO)$(EDX_ARCHIVE_URL)$(COLOR_RESET)";\
		echo -e "* EDX_DEMO_RELEASE_REF       : $(COLOR_INFO)$(EDX_DEMO_RELEASE_REF)$(COLOR_RESET)";\
		echo -e "* EDX_DEMO_ARCHIVE_URL       : $(COLOR_INFO)$(EDX_DEMO_ARCHIVE_URL)$(COLOR_RESET)";\
		echo -e "* REDIS_SERVICE              : $(COLOR_INFO)$(REDIS_SERVICE)$(COLOR_RESET)";\
		echo -e "* EDXAPP_IMAGE_NAME          : $(COLOR_INFO)$(EDXAPP_IMAGE_NAME)$(COLOR_RESET)";\
		echo -e "* EDXAPP_IMAGE_TAG           : $(COLOR_INFO)$(EDXAPP_IMAGE_TAG)$(COLOR_RESET)";\
		echo -e "* EDXAPP_NGINX_IMAGE_NAME    : $(COLOR_INFO)$(EDXAPP_NGINX_IMAGE_NAME)$(COLOR_RESET)";\
	fi
	@echo -e "";
.PHONY: info

logs:  ## get development logs
	$(COMPOSE) logs -f
.PHONY: logs

# Nota bene: we do not use the MANAGE_* shortcut because, for some releases
# (e.g.  dogwood), we cannot run the LMS while migrations haven't been
# performed.
migrate: \
  check-activate \
  check-root-user
migrate:  ## perform database migrations
	@echo "Booting mysql service..."
	$(COMPOSE) up -d mysql57
	$(WAIT_DB)
	$(COMPOSE_RUN) lms python manage.py lms migrate
	$(COMPOSE_RUN) cms python manage.py cms migrate
.PHONY: migrate

run: \
  check-activate run \
  check-root-user
run:  ## start the cms and lms services (nginx + production image)
	$(COMPOSE) up -d nginx
	@echo "Wait for services to be up..."
	$(WAIT_DB)
	$(COMPOSE_RUN) dockerize -wait tcp://cms:8000 -timeout 60s
	$(COMPOSE_RUN) dockerize -wait tcp://lms:8000 -timeout 60s
	$(COMPOSE_RUN) dockerize -wait tcp://nginx:80 -timeout 60s
.PHONY: run

run-ssl: \
  check-activate \
  check-root-user
run-ssl:  ## start the cms and lms services over TLS (nginx + production image)
	$(COMPOSE_SSL) up -d nginx
	@echo "Wait for services to be up..."
	$(WAIT_DB)
	$(COMPOSE_RUN) dockerize -wait tcp://cms:8000 -timeout 60s
	$(COMPOSE_RUN) dockerize -wait tcp://lms:8000 -timeout 60s
	$(COMPOSE_RUN) dockerize -wait tcp://nginx:80 -timeout 60s
.PHONY: run-ssl

stop:  ## stop the development servers
	$(COMPOSE) stop
.PHONY: stop

clean: \
  check-activate \
  check-root-user \
  stop
clean:  ## Remove mongo, mysql databases
	$(COMPOSE) rm mongo mysql57
.PHONY: clean

initdb:
	$(COMPOSE) up -d mongo mysql57
	@$(WAIT_MG)
	$(COMPOSE) exec -T mongo bash -e -c "mongo" < ./data/mongo.js
	@$(WAIT_DB)
	$(COMPOSE) exec -T mysql57 mysql -uroot < ./data/provision.sql
.PHONY: initdb

superuser: \
  check-activate
superuser: ## Create an admin user with password "admin"
	@$(COMPOSE) up -d mysql57
	@echo "Wait for services to be up..."
	@$(WAIT_DB)
	$(COMPOSE_RUN) lms python manage.py lms createsuperuser
.PHONY: superuser

test: \
  test-cms \
  test-lms \
  test-cms-dev \
  test-lms-dev
test: ## test services (production & development)
.PHONY: test

test-cms: ## test the CMS (production) service
	@test-service CMS production http://localhost:8083 1.1
.PHONY: test-cms

test-cms-dev: ## test the CMS (development) service
	@test-service CMS development http://localhost:8082 1.0
.PHONY: test-cms-dev

test-lms: ## test the LMS (production) service
	@test-service LMS production http://localhost:8073 1.1
.PHONY: test-lms

test-lms-dev: ## test the LMS (development) service
	@test-service LMS development http://localhost:8072 1.0
.PHONY: test-lms-dev

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help
