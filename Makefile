.PHONY: help vet format check clean build run debug attach image test ensure-tools .cert
.PHONY: build-linux build-darwin-amd build-darwin-arm build-windows

help: ## Show this help
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  ${YELLOW}%-18s${GREEN}%s${RESET}\n", $$1, $$2}' $(MAKEFILE_LIST)

GOCMD ?= go
GOTEST = APP_TEST=1 $(GOCMD) test
GOVET = $(GOCMD) vet
GOFMT = gofmt -s -w

# Application settings
# TODO: Update these values for your project
export APP_NAME ?= my-service
export APP_VERSION ?= $(shell git rev-parse --abbrev-ref HEAD):$(shell git rev-parse --short HEAD)
export APP_VCS_REVISION ?= $(shell git rev-parse HEAD)
MAIN ?= cmd/server/main.go
BINARY_NAME ?= $(subst -api,,$(APP_NAME))
export DEBUG_NAME ?= $(subst -api,,$(BINARY_NAME))-debug

# Environment settings
ENV ?= local
ENV_FILE ?= ./configs/$(ENV).env
SERVICE_PORT ?= 3000
DEBUG_PORT ?= 2345

# Build settings
# TODO: Update PACKAGE_PATH to match your module path in go.mod
PACKAGE_PATH ?= github.com/OWNER/PROJECT-NAME
TARGET_OS := $(shell $(GOCMD) env GOOS)
TARGET_ARCH := $(shell $(GOCMD) env GOARCH)
DOCKERFILE ?= Dockerfile
BUILDS_DIR ?= out
BINARIES := $(BINARY_NAME) $(DEBUG_NAME)
SOURCE_DIRS := internal pkg
# TODO: Set GH_USERNAME if using private repositories
GH_USERNAME ?= your-github-username

# Include environment variables from .env file if it exists
-include ./.env
export

# Terminal colors
RED    := $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

ensure-tools: ## Ensure all required tools are installed
	@command -v dlv >/dev/null 2>&1 || { echo "Installing delve..."; go install github.com/go-delve/delve/cmd/dlv@latest; }

# Development and testing targets
vet: $(SOURCE_DIRS) ## Validate code with 'go vet'
	$(GOVET) $(MAIN)

format: $(SOURCE_DIRS) ## Format code with 'gofmt'
	$(GOFMT) $(SOURCE_DIRS)

test: ## Run tests
	$(GOTEST) ./...

check: vet format test ## Run all pre-commit checks (vet, format, test)

clean: ## Remove build artifacts
	rm -f $(addprefix $(BUILDS_DIR)/,$(BINARIES))
	find . -type f \( -name '*.orig' -o -name 'debug' -o -name '__debug_bin' \) -delete

# Ensure build directory exists
$(BUILDS_DIR):
	mkdir -p $@

# Main application targets
build: $(BUILDS_DIR)/$(BINARY_NAME) ## Build application binary

$(BUILDS_DIR)/$(BINARY_NAME): $(MAIN) $(SOURCE_DIRS) | $(BUILDS_DIR) vet format
	sh ./scripts/build.sh \
		--app-name $(BINARY_NAME) \
		--debug-name false \
		--version "$(APP_VERSION)" \
		--revision "$(APP_VCS_REVISION)" \
		--output-dir $(BUILDS_DIR) \
		--main-file $(MAIN) \
		--target-os $(TARGET_OS) \
		--target-arch $(TARGET_ARCH) \
		--package-path $(PACKAGE_PATH)

$(BUILDS_DIR)/$(DEBUG_NAME): $(MAIN) $(SOURCE_DIRS) | $(BUILDS_DIR) vet format
	sh ./scripts/build.sh \
		--app-name false \
		--debug-name $(DEBUG_NAME) \
		--version "$(APP_VERSION)" \
		--revision "$(APP_VCS_REVISION)" \
		--output-dir $(BUILDS_DIR) \
		--main-file $(MAIN) \
		--target-os $(TARGET_OS) \
		--target-arch $(TARGET_ARCH) \
		--package-path $(PACKAGE_PATH)

# Running and debugging
.cert: ## Generate self-signed TLS certificates for local development
	@echo "Generating self-signed certificates..."
	openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj '/CN=localhost'

run: $(BUILDS_DIR)/$(BINARY_NAME) ## Run the application
ifdef USE_TLS
run: | .cert
endif
	set -a && . $(ENV_FILE) && set +a && ./$(BUILDS_DIR)/$(BINARY_NAME)

debug: $(BUILDS_DIR)/$(DEBUG_NAME) ## Run with debugger
ifdef USE_TLS
debug: | .cert
endif
	set -a && . $(ENV_FILE) && set +a && \
	dlv --listen=:$(DEBUG_PORT) \
		--headless=true \
		--api-version=2 \
		--accept-multiclient \
		exec ./$(BUILDS_DIR)/$(DEBUG_NAME) --continue

attach: ## Attach to running debugger
	dlv connect localhost:$(DEBUG_PORT)

# Container image
image: ## Build container image
	docker build --rm --tag $(BINARY_NAME) . \
	--file $(DOCKERFILE) \
	--build-arg GH_USERNAME=$(GH_USERNAME) \
	--build-arg GH_ACCESSTOKEN=$(GH_ACCESSTOKEN) \
	--build-arg APP_VERSION_LABEL=$(APP_VERSION) \
	--build-arg APP_VCS_REVISION=$(APP_VCS_REVISION)

# Common Cross-compilation targets

build-linux: ## Build for Linux
	@$(MAKE) build TARGET_OS=linux TARGET_ARCH=amd64 BINARY_NAME=$(BINARY_NAME)-linux-amd64

build-darwin-amd: ## Build for Intel MacOS
	@$(MAKE) build TARGET_OS=darwin TARGET_ARCH=amd64 BINARY_NAME=$(BINARY_NAME)-darwin-amd64

build-darwin-arm:  ## Build for Apple Silicon
	@$(MAKE) build TARGET_OS=darwin TARGET_ARCH=arm64 BINARY_NAME=$(BINARY_NAME)-darwin-arm64

build-windows: ## Build for Windows
	@$(MAKE) build TARGET_OS=windows TARGET_ARCH=amd64 BINARY_NAME=$(BINARY_NAME)-windows-amd64.exe

