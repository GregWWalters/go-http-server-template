# syntax=docker/dockerfile:1

# GLOBAL ARGS
# TODO: Update GO_VERSION as needed
ARG GO_VERSION=1.24
ARG ALPINE_VERSION=3.21
ARG DELVE_VERSION=v1.21.0
# TODO: Update APP_NAME to match your service name
ARG APP_NAME=my-service
ARG APP_PORT=8080
ARG APP_VERSION_LABEL
ARG APP_VCS_REVISION
ARG DEBUG_NAME=my-service-debug
ARG DEBUG_PORT=2345
# TODO: Update BUILD_DIR to match your module path
ARG BUILD_DIR=/go/src/github.com/OWNER/PROJECT-NAME

# ------------------------------------------------------------------------------
# Build Stage
# ------------------------------------------------------------------------------
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS build
# TODO: Update image metadata
LABEL org.opencontainers.image.authors="Your Name <your.email@example.com>"
LABEL org.opencontainers.image.vendor="Your Organization"

# Build options
ARG BUILD_DIR
ARG APP_NAME
ARG APP_VERSION_LABEL
ARG APP_VCS_REVISION
ARG DEBUG_NAME
ARG DELVE_VERSION

# GitHub authentication for private repositories (optional - remove if not needed)
# TODO: Remove this section if you don't use private Go modules
ARG GH_USERNAME
ARG GH_ACCESSTOKEN

# Install necessary build dependencies
RUN apk add --no-cache openssl git

# Configure git to use access token via BuildKit secret (more secure than ARG)
# Usage: docker build --secret id=gh_token,env=GH_ACCESSTOKEN ...
RUN --mount=type=secret,id=gh_token \
    if [ -f /run/secrets/gh_token ] && [ -n "$GH_USERNAME" ]; then \
      GH_TOKEN=$(cat /run/secrets/gh_token) && \
      git config --global url."https://${GH_USERNAME}:${GH_TOKEN}@github.com".insteadOf "https://github.com"; \
    elif [ -n "$GH_USERNAME" ] && [ -n "$GH_ACCESSTOKEN" ]; then \
      git config --global url."https://${GH_USERNAME}:${GH_ACCESSTOKEN}@github.com".insteadOf "https://github.com"; \
    fi

# Set the working directory
WORKDIR ${BUILD_DIR}

# Copy go.mod and go.sum first (for better layer caching)
COPY go.mod go.sum ./

RUN go mod download

# Copy the rest of the source code
COPY . .

# Install delve debugger with specific version for reproducibility
RUN go install github.com/go-delve/delve/cmd/dlv@${DELVE_VERSION}

# Determine version information if not provided
RUN mkdir -p /tmp/version_info && \
    if [ -z "$APP_VERSION_LABEL" ]; then \
      if [ -d .git ]; then \
        APP_VERSION_LABEL=$(git rev-parse --abbrev-ref HEAD):$(git rev-parse --short HEAD) || APP_VERSION_LABEL="unknown:unknown"; \
      else \
        APP_VERSION_LABEL="unknown:unknown"; \
      fi; \
    fi && \
    if [ -z "$APP_VCS_REVISION" ]; then \
      if [ -d .git ]; then \
        APP_VCS_REVISION=$(git rev-parse HEAD) || APP_VCS_REVISION="unknown"; \
      else \
        APP_VCS_REVISION="unknown"; \
      fi; \
    fi && \
    echo "$APP_VERSION_LABEL" > /tmp/version_info/label && \
    echo "$APP_VCS_REVISION" > /tmp/version_info/revision && \
    echo "Version: $APP_VERSION_LABEL" && \
    echo "Revision: $APP_VCS_REVISION"

# Run the build script with flags specifically for Linux target
# TODO: Update --main-file and --package-path to match your project
RUN APP_VERSION_LABEL=$(cat /tmp/version_info/label) APP_VCS_REVISION=$(cat /tmp/version_info/revision) \
      sh ./scripts/build.sh \
      --app-name "${APP_NAME}" \
      --debug-name "${DEBUG_NAME}" \
      --version "${APP_VERSION_LABEL}" \
      --revision "${APP_VCS_REVISION}" \
      --target-os "linux" \
      --target-arch "amd64" \
      --output-dir out \
      --main-file cmd/server/main.go \
      --package-path github.com/OWNER/PROJECT-NAME

# ------------------------------------------------------------------------------
# Main Stage
# ------------------------------------------------------------------------------
FROM alpine:${ALPINE_VERSION} AS run

ARG APP_NAME
ARG APP_PORT
ARG DEBUG_NAME
ARG DEBUG_PORT
ARG BUILD_DIR
ARG BIN_DIR=/app

# Import version information from build stage
COPY --from=build /tmp/version_info /tmp/

# TODO: Update image metadata
LABEL org.opencontainers.image.authors="Your Name <your.email@example.com>"
LABEL org.opencontainers.image.vendor="Your Organization"
LABEL org.opencontainers.image.title="${APP_NAME}"
LABEL org.opencontainers.image.description="Your service description"

# Install wget for healthcheck
RUN apk add --no-cache wget

# Create non-root user for running the application
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Persist these values for runtime
ENV BIN_DIR=${BIN_DIR} \
    SCRIPT_DIR="/app/scripts" \
    APP_NAME=${APP_NAME} \
    APP_PORT=${APP_PORT} \
    DEBUG_NAME=${DEBUG_NAME} \
    DEBUG_PORT=${DEBUG_PORT}

WORKDIR ${BIN_DIR}

# Copy only necessary files from build stage
RUN mkdir -p "${SCRIPT_DIR}"
COPY --from=build ${BUILD_DIR}/scripts/start.sh ${BUILD_DIR}/scripts/debug.sh ${BUILD_DIR}/scripts/helpers.sh ${SCRIPT_DIR}/
COPY --from=build ${BUILD_DIR}/out .
COPY --from=build /go/bin/dlv ./

# Set ownership for security
RUN chown -R appuser:appgroup ${BIN_DIR}

# Switch to non-root user
USER appuser

EXPOSE ${APP_PORT} ${DEBUG_PORT}

ENTRYPOINT ["./scripts/start.sh"]

STOPSIGNAL SIGINT

HEALTHCHECK --start-period=5s --interval=1m --timeout=5s --retries=3 \
  CMD if [ -n "$USE_TLS" ]; then \
        wget --no-verbose --tries=1 --spider "https://localhost:${APP_PORT:-8080}/health" || exit 1; \
      else \
        wget --no-verbose --tries=1 --spider "http://localhost:${APP_PORT:-8080}/health" || exit 1; \
      fi
