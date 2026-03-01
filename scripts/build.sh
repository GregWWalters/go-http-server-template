#!/bin/sh
set -e

# Default values - these match the template TODOs
APP_NAME="my-service"
DEBUG_NAME="my-service-debug"
APP_VERSION_LABEL=""
APP_VCS_REVISION=""
OUTPUT_DIR="out"
MAIN_FILE="cmd/server/main.go"
PKG_PATH="github.com/OWNER/PROJECT-NAME"
TARGET_OS=""
TARGET_ARCH=""
FORCE_LINUX=false

# Function to display usage information
usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -a, --app-name NAME        Application name (default: $APP_NAME)"
  echo "  -d, --debug-name NAME      Debug binary name (default: $DEBUG_NAME)"
  echo "  -v, --version VERSION      Application version label"
  echo "  -r, --revision REVISION    VCS revision hash"
  echo "  -o, --output-dir DIR       Output directory (default: $OUTPUT_DIR)"
  echo "  -m, --main-file FILE       Path to main.go file (default: $MAIN_FILE)"
  echo "  -p, --package-path PATH    Go package path (default: $PKG_PATH)"
  echo "  -t, --target-os OS         Target OS (linux, darwin, windows)"
  echo "  -A, --target-arch ARCH     Target architecture (amd64, arm64, etc.)"
  echo "  -L, --force-linux          Force build for Linux (for containers)"
  echo
}

# Parse command line arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -a|--app-name)
      APP_NAME="$2"
      shift 2
      ;;
    -d|--debug-name)
      DEBUG_NAME="$2"
      shift 2
      ;;
    -v|--version)
      APP_VERSION_LABEL="$2"
      shift 2
      ;;
    -r|--revision)
      APP_VCS_REVISION="$2"
      shift 2
      ;;
    -o|--output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -m|--main-file)
      MAIN_FILE="$2"
      shift 2
      ;;
    -p|--package-path)
      PKG_PATH="$2"
      shift 2
      ;;
    -t|--target-os)
      TARGET_OS="$2"
      shift 2
      ;;
    -A|--target-arch)
      TARGET_ARCH="$2"
      shift 2
      ;;
    -L|--force-linux)
      FORCE_LINUX=true
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

# Detect host OS and architecture if not specified
if [ -z "$TARGET_OS" ]; then
  if [ "$FORCE_LINUX" = "true" ]; then
    TARGET_OS="linux"
  else
    TARGET_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    # Convert "darwin" to darwin for macOS
    if [ "$TARGET_OS" = "darwin" ]; then
      TARGET_OS="darwin"
    fi
  fi
fi

if [ -z "$TARGET_ARCH" ]; then
  ARCH=$(uname -m)
  # Convert architecture format
  if [ "$ARCH" = "x86_64" ]; then
    TARGET_ARCH="amd64"
  elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    TARGET_ARCH="arm64"
  else
    TARGET_ARCH="$ARCH"
  fi
fi

echo "Building for OS: $TARGET_OS, Architecture: $TARGET_ARCH"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Determine version information if not provided
if [ -z "$APP_VERSION_LABEL" ]; then
  if git rev-parse --git-dir > /dev/null 2>&1; then
    APP_VERSION_LABEL=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "dev"):$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo "Generated APP_VERSION_LABEL=$APP_VERSION_LABEL"
  else
    APP_VERSION_LABEL="dev:unknown"
    echo "Git not available, using default APP_VERSION_LABEL=$APP_VERSION_LABEL"
  fi
else
  echo "Using provided APP_VERSION_LABEL=$APP_VERSION_LABEL"
fi

if [ -z "$APP_VCS_REVISION" ]; then
  if git rev-parse --git-dir > /dev/null 2>&1; then
    APP_VCS_REVISION=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    echo "Generated APP_VCS_REVISION=$APP_VCS_REVISION"
  else
    APP_VCS_REVISION="unknown"
    echo "Git not available, using default APP_VCS_REVISION=$APP_VCS_REVISION"
  fi
else
  echo "Using provided APP_VCS_REVISION=$APP_VCS_REVISION"
fi

# Validate main file exists
if [ ! -f "$MAIN_FILE" ]; then
  echo "Error: Main file not found at $MAIN_FILE" >&2
  exit 1
fi

# Constants package path
CONSTANTS_PKG="${PKG_PATH}/internal/constants"

# Common ldflags
VERSION_FLAGS="-X ${CONSTANTS_PKG}.AppVersion=$APP_VERSION_LABEL \
-X ${CONSTANTS_PKG}.AppVCSRevision=$APP_VCS_REVISION"

# Skip build if APP_NAME is set to "false"
if [ "$APP_NAME" != "false" ]; then
  echo "Building optimized binary: ${OUTPUT_DIR}/${APP_NAME}"
  CGO_ENABLED=0 \
  GOOS=$TARGET_OS \
  GOARCH=$TARGET_ARCH \
  go build \
    -trimpath \
    -ldflags="-s -w $VERSION_FLAGS" \
    -o "${OUTPUT_DIR}/${APP_NAME}" ${MAIN_FILE}
fi

# Skip build if DEBUG_NAME is set to "false"
if [ "$DEBUG_NAME" != "false" ]; then
  echo "Building debug binary: ${OUTPUT_DIR}/${DEBUG_NAME}"
  CGO_ENABLED=0 \
  GOOS=$TARGET_OS \
  GOARCH=$TARGET_ARCH \
  go build \
    -gcflags 'all=-N -l' \
    -ldflags="$VERSION_FLAGS" \
    -o "${OUTPUT_DIR}/${DEBUG_NAME}" ${MAIN_FILE}
fi

echo "Build completed successfully"
