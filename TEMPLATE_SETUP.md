# Template Setup Guide

This document provides a step-by-step checklist for setting up a new project from this template.

## Initial Setup Steps

### 1. Module Path

Update the Go module path throughout the project:

**Find:** `github.com/OWNER/PROJECT-NAME`
**Replace with:** Your actual module path (e.g., `github.com/myorg/myproject`)

**Files to update:**
- [ ] `go.mod` (line 1)
- [ ] `Makefile` - `PACKAGE_PATH` variable (line ~34)
- [ ] `Dockerfile` - `BUILD_DIR` ARG (line ~16)
- [ ] `Dockerfile` - build script `--package-path` (line ~99)
- [ ] `scripts/build.sh` - `PKG_PATH` default (line ~11)
- [ ] `internal/handlers/health.go` (import)
- [ ] `internal/handlers/example.go` (import)
- [ ] `internal/server/server.go` (imports)
- [ ] `internal/server/routes.go` (import)
- [ ] `cmd/server/main.go` (imports)

### 2. Application Name

Update the service name:

**Find:** `my-service`
**Replace with:** Your service name (e.g., `user-api`)

**Files to update:**
- [ ] `Makefile` - `APP_NAME` variable (line ~16)
- [ ] `Dockerfile` - `APP_NAME` ARG (line ~9)
- [ ] `Dockerfile` - `DEBUG_NAME` ARG (line ~13)
- [ ] `scripts/build.sh` - `APP_NAME` default (line ~5)
- [ ] `scripts/build.sh` - `DEBUG_NAME` default (line ~6)

### 3. Main File Path

If you changed the main file location from `cmd/server/main.go`:

**Files to update:**
- [ ] `Makefile` - `MAIN` variable (line ~22)
- [ ] `Dockerfile` - build script `--main-file` (line ~98)
- [ ] `scripts/build.sh` - `MAIN_FILE` default (line ~10)

### 4. Metadata

Update author and organization information:

**Files to update:**
- [ ] `Dockerfile` - `org.opencontainers.image.authors` labels (lines ~23, ~117)
- [ ] `Dockerfile` - `org.opencontainers.image.vendor` labels (lines ~24, ~118)
- [ ] `Dockerfile` - `org.opencontainers.image.title` label (line ~119)
- [ ] `Dockerfile` - `org.opencontainers.image.description` label (line ~120)

### 5. GitHub Authentication (Optional)

If you **don't** use private Go modules:

- [ ] Remove GitHub authentication section from `Dockerfile` (lines ~35-50)
- [ ] Remove `GH_USERNAME` and related build args from `Makefile` image target (lines ~123-124)

If you **do** use private Go modules:

**Recommended:** Use BuildKit secrets (more secure):
```bash
export DOCKER_BUILDKIT=1
echo "your-token" | docker build -t my-service . \
  --secret id=gh_token,env=GH_ACCESSTOKEN \
  --build-arg GH_USERNAME=your-username
```

**Alternative:** Use build args (less secure, credentials in layer history):
- [ ] Update `GH_USERNAME` in `Makefile` (line ~39) to your GitHub username
- [ ] Set `GH_ACCESSTOKEN` environment variable when building

### 6. Configuration

Review and customize configuration:

- [ ] Update default values in `internal/config/vars.go`
- [ ] Add any project-specific config fields
- [ ] Create environment-specific configs in `configs/` directory (e.g., `local.env`, `dev.env`)
- [ ] Update `configs/example.env` with your environment variables

### 7. Replace Example Code

Remove placeholder code and add your implementation:

- [ ] Remove or replace `internal/handlers/example.go`
- [ ] Update `internal/server/routes.go` to register your actual routes
- [ ] Update CORS settings in `internal/middleware/cors.go` for your needs

### 8. Documentation

- [ ] Update README.md with project-specific information
- [ ] Remove or update the "Improvements in This Version" section in README
- [ ] Add API documentation for your endpoints
- [ ] Delete this TEMPLATE_SETUP.md file when done

### 9. Optional Enhancements

Consider adding:

- [ ] Database connection and models
- [ ] Authentication/authorization middleware
- [ ] TLS certificate configuration
- [ ] Structured logging (e.g., with `zap` or `logrus`)
- [ ] Request validation
- [ ] Rate limiting
- [ ] Metrics and monitoring (e.g., Prometheus)
- [ ] OpenAPI/Swagger documentation
- [ ] Unit and integration tests
- [ ] CI/CD configuration (.github/workflows)
- [ ] Linting with `golangci-lint`

## Quick Search and Replace

You can use these commands to quickly find files that need updates:

```bash
# Find all references to placeholder module path
grep -r "github.com/OWNER/PROJECT-NAME" . --exclude-dir=.git

# Find all references to placeholder service name
grep -r "my-service" . --exclude-dir=.git --exclude-dir=out

# Find all TODO comments
grep -r "TODO:" . --exclude-dir=.git

# Find placeholder author/organization info
grep -r "Your Name" . --exclude-dir=.git
grep -r "Your Organization" . --exclude-dir=.git
```

**Pro tip:** Use `sed` for batch replacements (macOS users: install GNU sed with `brew install gnu-sed`):

```bash
# Replace module path (be careful with this!)
find . -type f -name "*.go" -o -name "*.mod" | xargs sed -i 's|github.com/OWNER/PROJECT-NAME|github.com/myorg/myproject|g'

# Replace service name in config files
find . -type f \( -name "Makefile" -o -name "Dockerfile" -o -name "*.sh" \) | xargs sed -i 's/my-service/myproject/g'
```

## Verification

After completing the setup:

1. **Verify all TODOs are addressed:**
   ```bash
   grep -r "TODO:" . --exclude-dir=.git --exclude="TEMPLATE_SETUP.md"
   ```

2. **Download dependencies:**
   ```bash
   go mod download
   go mod tidy
   ```

3. **Build the project:**
   ```bash
   make build
   ```

4. **Run tests:**
   ```bash
   make test
   ```

5. **Start the server:**
   ```bash
   make run
   ```

6. **Test the health endpoint:**
   ```bash
   curl http://localhost:8080/health
   ```
   Expected output:
   ```json
   {"status":"ok","version":"main:xxxxx","revision":"xxxxx"}
   ```

7. **Build Docker image:**
   ```bash
   make image
   ```

8. **Test Docker container:**
   ```bash
   docker run -p 8080:8080 my-service
   # In another terminal:
   curl http://localhost:8080/health
   ```

If all these steps succeed, your template is properly configured!

## Next Steps

1. **Commit your changes:**
   ```bash
   git add .
   git commit -m "Initial project setup from template"
   ```

2. **Start building your application by adding:**
   - Your domain models in `internal/models/`
   - Business logic in `internal/services/`
   - Additional API endpoints in `internal/handlers/`
   - Unit tests for handlers and middleware
   - Integration tests in `test/`

3. **Set up CI/CD:**
   - Create `.github/workflows/` for GitHub Actions
   - Add build, test, and lint jobs
   - Set up Docker image publishing

4. **Delete this file when you're done:**
   ```bash
   git rm TEMPLATE_SETUP.md
   git commit -m "Remove template setup guide"
   ```

## Troubleshooting

### Build fails with "main file not found"
- Check that `MAIN_FILE` path is correct in `Makefile` and `scripts/build.sh`
- Ensure `cmd/server/main.go` exists or update paths

### Docker build fails with private module errors
- Use BuildKit secrets instead of build args for better security
- Ensure `GH_USERNAME` and token are set correctly
- Check that git config in Dockerfile matches your repository URL

### Tests fail with import errors
- Run `go mod tidy` to clean up dependencies
- Ensure all import paths have been updated from placeholders
- Check that `go.mod` module path is correct

### Cross-compilation produces wrong binary names
- The cross-compilation targets now use `BINARY_NAME` variable correctly
- Check that `APP_NAME` is set properly in the Makefile

Happy coding! 🚀
