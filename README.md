# Go HTTP Server Template

A production-ready template for building HTTP servers in Go, featuring configuration management, middleware, graceful shutdown, and Docker support.

## Features

- **Configuration Management**: Support for environment variables, .env files, YAML, and JSON configs
- **HTTP Router**: chi for lightweight, idiomatic routing
- **Middleware Stack**: Logging, recovery, and CORS middleware
- **Health Checks**: Built-in health check endpoint
- **Graceful Shutdown**: Proper signal handling for clean server shutdown
- **Docker Support**: Multi-stage Dockerfile with debug capabilities
- **Build Scripts**: Flexible build system with version injection
- **Development Tools**: Makefile targets for common tasks

## Quick Start

### 1. Use This Template

Click "Use this template" on GitHub to create your own repository, or see `TEMPLATE_SETUP.md` for detailed setup instructions.

### 2. Update Project References

Find and replace the following placeholders throughout the project:

- `github.com/OWNER/PROJECT-NAME` → Your module path (in `go.mod`, handlers, server files)
- `my-service` → Your service name (in `Makefile`, `Dockerfile`, scripts)
- `Your Name <your.email@example.com>` → Your contact info (in `Dockerfile`)
- `Your Organization` → Your organization name (in `Dockerfile`)

**Files to update:**
- `go.mod`: Update module path
- `Makefile`: Update `APP_NAME`, `PACKAGE_PATH`, and optionally `GH_USERNAME`
- `Dockerfile`: Update `APP_NAME`, `BUILD_DIR`, and metadata labels
- `scripts/build.sh`: Update default values to match your project
- `internal/handlers/*.go`: Update import paths
- `internal/server/*.go`: Update import paths
- `cmd/server/main.go`: Update import paths

**Tip:** Run `grep -r "OWNER/PROJECT-NAME" .` and `grep -r "my-service" .` to find all occurrences.

### 3. Install Dependencies

```bash
go mod download
```

### 4. Build and Run

```bash
# Build the application
make build

# Run the application
make run

# Or run directly
./out/my-service
```

## Configuration

Configuration is loaded in the following order (later sources override earlier ones):

1. Default values (in `internal/config/vars.go`)
2. Environment file (`.env`, YAML, or JSON via `--env-file` flag)
3. Environment variables
4. Command-line flags

### Environment Variables

- `PORT` - Server port (default: 8080)
- `USE_TLS` - Enable TLS (default: false)
- `DEBUG_MODE` - Enable debug mode (default: false)
- `LOG_LEVEL` - Logging level (default: INFO)

### Example Configuration File

**configs/example.env:**
```env
DEBUG=TRUE
LOG_LEVEL=TRACE
TLS=FALSE
PORT=8080
```

Copy to create your own:
```bash
cp configs/example.env .env
```

## Development

### Available Make Targets

```bash
make help              # Show all available targets
make build             # Build application binary
make run               # Build and run the application
make debug             # Build and run with debugger
make attach            # Attach to running debugger
make test              # Run tests
make vet               # Run go vet
make format            # Format code with gofmt
make check             # Run all pre-commit checks (vet + format + test)
make clean             # Remove build artifacts
make image             # Build Docker image
make ensure-tools      # Install required development tools
```

### Cross-Compilation

```bash
make build-linux        # Build for Linux (amd64)
make build-darwin-amd   # Build for Intel macOS
make build-darwin-arm   # Build for Apple Silicon
make build-windows      # Build for Windows (amd64)
```

### Running Tests

```bash
go test ./...
# or
make test
```

## Docker

### Building the Image

```bash
# Build the image
make image

# Or use docker directly
docker build -t my-service .
```

**Note:** If you use private Go modules, you'll need to provide GitHub credentials.

**Recommended (more secure):** Use BuildKit secrets:
```bash
export DOCKER_BUILDKIT=1
echo "your-github-token" | docker build -t my-service . \
  --secret id=gh_token,env=GH_ACCESSTOKEN \
  --build-arg GH_USERNAME=your-username
```

**Alternative (less secure):** Use build args:
```bash
docker build -t my-service . \
  --build-arg GH_USERNAME=your-username \
  --build-arg GH_ACCESSTOKEN=your-token
```

If you don't use private modules, remove the GitHub authentication section from the Dockerfile.

### Running the Container

```bash
# Run the production build
docker run -p 8080:8080 my-service

# Run with debug mode
docker run -p 8080:8080 -p 2345:2345 my-service --debug

# With environment variables
docker run -p 8080:8080 -e PORT=3000 -e LOG_LEVEL=DEBUG my-service
```

## Project Structure

```
.
├── cmd/
│   └── server/          # Application entry point
│       └── main.go
├── internal/            # Application code
│   ├── config/          # Configuration management
│   │   ├── config.go    # Config loader
│   │   ├── envfile.go   # File parsers (.env, YAML, JSON)
│   │   ├── flags.go     # Command-line flags
│   │   └── vars.go      # Config struct and defaults
│   ├── constants/       # Build-time constants
│   │   └── version.go
│   ├── handlers/        # HTTP request handlers
│   │   ├── health.go    # Health check endpoint
│   │   └── example.go   # Example API handlers
│   ├── middleware/      # HTTP middleware
│   │   ├── cors.go      # CORS middleware
│   │   ├── logging.go   # Request logging
│   │   └── recovery.go  # Panic recovery
│   └── server/          # HTTP server
│       ├── server.go    # Server setup and lifecycle
│       └── routes.go    # Route registration
├── pkg/                 # Public shared packages (empty)
├── configs/             # Configuration file examples
│   └── example.env
├── scripts/             # Build and runtime scripts
│   ├── build.sh         # Build script with version injection
│   ├── start.sh         # Container entrypoint
│   ├── debug.sh         # Debug mode launcher
│   └── helpers.sh       # Shared shell functions
├── Dockerfile           # Multi-stage Docker build
├── Makefile             # Build automation
├── go.mod               # Go module definition
└── README.md            # This file
```

## Adding New Endpoints

1. **Create a handler** in `internal/handlers/`:

```go
package handlers

import (
    "encoding/json"
    "net/http"
)

func MyHandler() http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(map[string]string{
            "message": "Hello, World!",
        })
    }
}
```

2. **Register the route** in `internal/server/routes.go`:

```go
func (s *Server) RegisterRoutes() {
    // ... existing routes ...
    s.router.Get("/api/myendpoint", handlers.MyHandler())
}
```

## Adding Configuration Options

1. **Add field to Config struct** in `internal/config/vars.go`:

```go
type Config struct {
    // ... existing fields ...
    MyOption string `env:"MY_OPTION" yaml:"my_option" json:"my_option" flag:"my-option"`
}

var defaults = Config{
    // ... existing defaults ...
    MyOption: "default-value",
}
```

2. **Add flag definition** in `internal/config/flags.go`:

```go
func DefineFlags(defaults, dest *Config) {
    // ... existing flags ...
    flag.StringVar(&dest.MyOption, "my-option", defaults.MyOption, "Description")
}
```

3. **Add environment variable handler** in `internal/config/config.go`:

```go
func LoadFromEnv(cfg *Config) {
    // ... existing handlers ...
    if val := os.Getenv("MY_OPTION"); val != "" {
        cfg.MyOption = val
    }
}
```

4. **Add env file parser case** in `internal/config/envfile.go`:

```go
switch key {
    // ... existing cases ...
    case "MY_OPTION":
        cfg.MyOption = value
}
```

## Endpoints

### Health Check

**GET** `/health`

Returns server health status and version information.

**Response:**
```json
{
  "status": "ok",
  "version": "main:abc123",
  "revision": "abc123def456"
}
```

### Example API

**GET** `/api/example` - List example resources

**GET** `/api/example/{id}` - Get specific resource

**POST** `/api/example` - Create new resource

**TODO:** Replace example endpoints with your actual API.

## Debugging

### Local Debugging

```bash
# Build and start debugger
make debug

# In another terminal, attach
make attach
```

The debugger listens on port `2345` by default.

### Docker Debugging

```bash
# Run container with debug mode
docker run -p 8080:8080 -p 2345:2345 my-service --debug
```

Connect your IDE's debugger to `localhost:2345`.

## Improvements in This Version

### Build System
- **Fixed Makefile:** Added `test` target, fixed cross-compilation targets to use variables, corrected config path
- **Improved build.sh:** Better error handling for git commands, removed redundant flags, added `-trimpath` for reproducible builds
- **Added `.PHONY` declarations:** Prevents conflicts with files of the same name

### Docker
- **Enhanced security:** BuildKit secrets support for GitHub credentials (keeps tokens out of layer history)
- **Fixed healthcheck:** Installs wget and properly handles TLS detection
- **Optimized layers:** Only copies necessary scripts instead of entire directory
- **Better error handling:** Git commands include fallbacks

### Scripts
- **Fixed debug.sh:** Corrected PID handling and added delay to prevent race conditions
- **Improved helpers.sh:** POSIX-compliant (removed bash-specific `function` keyword)
- **Enhanced start.sh:** Cleaner boolean parsing with better error messages
- **Added `.dockerignore`:** Reduces Docker build context size and build time

### Developer Experience
- **Consistent defaults:** All TODO placeholders now match across files
- **Better documentation:** Updated README with new features and security best practices

## TODO After Creating Project

- [ ] Update all placeholder values (see "Update Project References" above)
- [ ] Replace example handlers with your actual API endpoints
- [ ] Configure CORS settings in `internal/middleware/cors.go`
- [ ] Add authentication/authorization middleware if needed
- [ ] Set up TLS certificates for production
- [ ] Add database connection and models (if needed)
- [ ] Add tests for your handlers and middleware
- [ ] Configure CI/CD pipeline
- [ ] Update this README with project-specific information
- [ ] Delete `TEMPLATE_SETUP.md` after initial setup

## License

MPL-2.0

## Contributing

Contributions welcome! Please read the contributing guidelines before submitting PRs.
