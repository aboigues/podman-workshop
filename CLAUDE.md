# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Podman Workshop** is a comprehensive, hands-on training program teaching containerization with Podman from basics to AWS deployment. This is an educational repository organized as progressive workshops (TPs) with a "Learning by Doing" approach where learners write their own commands instead of copy-pasting solutions.

Total training duration: **21 hours** across 7 workshops (TP1-TP6 + TP5B)

## Repository Architecture

### Workshop Structure
Each TP follows a consistent pattern:
- **TP1-TP4**: Progressive learning (Beginners → Advanced)
- **TP5A/TP5B**: Parallel advanced topics (Security / AWS)
- **TP6**: Expert-level capstone project integrating all concepts

### Exercise Pattern
Every exercise directory contains:
- `README.md` - Detailed exercise statement with objectives
- `commandes.sh` - Template script with placeholders for learners to complete
- `validation.sh` - Automated validation script that checks learner's work
- `indices.md` - Progressive 3-level hints system
- Solution scripts in `../solutions/` directory

### Key Components

**Shared Libraries:**
- `lib/validation-utils.sh` - Reusable validation functions used by all exercise validation scripts
  - Color-coded output helpers (success, error, info, warning)
  - Container/image/network checking functions
  - Exercise cleanup utilities

**Utility Scripts:**
- `scripts/check-prerequisites.sh` - Verify Podman, Git, system requirements
- `scripts/test-all.sh` - Run all TP tests sequentially
- `scripts/cleanup-all.sh` - Clean all containers/images from exercises
- `scripts/test-tp.sh` - Test individual TP

## Testing & Validation

### Local Testing
```bash
# Check prerequisites
./scripts/check-prerequisites.sh

# Test all TPs
./scripts/test-all.sh

# Test specific TP (from exercise directory)
cd TP1-conteneurs-simples/exercices
bash quick-test.sh

# Validate individual exercise
cd exercice-01
./validation.sh

# Clean up after exercise
./validation.sh --cleanup
```

### GitHub Actions Workflows

The repository uses **intelligent path-based filtering** to optimize CI/CD:

**`.github/workflows/test-podman.yml`**
- Detects which TPs were modified
- Only runs relevant test jobs
- Jobs: `changes`, `test-tp1` through `test-tp6`, `test-security-scripts`

**`.github/workflows/trivy-scan.yml`**
- Scans Docker images for vulnerabilities (CRITICAL/HIGH severity)
- Path-filtered by TP directory
- Jobs: `scan-tp2-images`, `scan-tp3-images`, `scan-tp6-images`, `scan-tp5a-images`
- Uses `.trivyignore` to document acceptable vulnerabilities in educational context

**`.github/workflows/shellcheck.yml`**
- Static analysis of all `.sh` scripts
- Triggers on `.sh` file changes

**`.github/workflows/markdown-lint.yml`**
- Validates Markdown formatting
- Non-blocking (continue-on-error)
- Config: `.markdownlint.json`

### Running Trivy Locally
```bash
# Build and scan an image
cd TP6-projet-complet/app/backend
podman build -t backend:test .
trivy image --severity HIGH,CRITICAL --ignore-unfixed backend:test

# Use same settings as CI
trivy image --severity HIGH,CRITICAL --ignore-unfixed \
  --trivyignore ../../.trivyignore backend:test
```

## Important Files & Configurations

**`.trivyignore`**
- Documents CVEs accepted in educational context
- Example: CVE-2025-64756 (glob) - requires attacker file creation, not a real risk in workshop environment

**`.markdownlint.json`**
- 120 char line length
- Allows HTML (MD033)
- Allows multiple headings (MD024, MD025)

**`package.json` (TP6 backend)**
- Uses `overrides` to force secure package versions
- Example: `"glob": ">=10.5.0"` to fix CVE-2025-64756

## Working with Dockerfiles

When modifying Dockerfiles in this repository:

1. **Security First**: All images are scanned with Trivy for CRITICAL/HIGH vulnerabilities
2. **Use Stable Versions**: Prefer stable tags (e.g., `python:3.13-slim` over `python:3.14-slim`)
3. **Educational Context**: Security can be relaxed for learning purposes (document in `.trivyignore`)
4. **Test Locally**: Always build and test before pushing

### Key Dockerfiles
- `TP2-dockerfile/*/Dockerfile` - Educational examples (Python Flask, Go multi-stage, Nginx)
- `TP6-projet-complet/app/*/Dockerfile` - Production-like multi-stage builds
- `TP5A-securite/exemples/Dockerfile-*` - Security examples (rootless, secrets)

## TP6 Project Complete Architecture

The capstone project (`TP6-projet-complet/`) demonstrates a real microservices stack:

**Services:**
- Frontend: React application (port 3000)
- Backend: Node.js/Express API (port 4000)
- Database: PostgreSQL (port 5432)
- Cache: Redis (port 6379)
- Proxy: Nginx reverse proxy with SSL (ports 80/443)
- Monitoring: Prometheus (port 9090)
- Visualization: Grafana (port 3001)

**Key Files:**
- `docker-compose.yml` - Complete orchestration
- `app/backend/src/index.js` - API with Prometheus metrics
- `app/frontend/src/App.jsx` - React frontend
- `prometheus/prometheus.yml` - Metrics collection config
- `grafana/dashboards/` - Pre-configured dashboards

## Contribution Workflow

When making changes:

1. **Maintain Structure**: Keep the exercise pattern (README, commandes.sh, validation.sh, indices.md)
2. **Test Validation Scripts**: Source `lib/validation-utils.sh` for consistency
3. **Update GitHub Actions**: Add path filters if creating new TPs
4. **Document Security Decisions**: Add CVEs to `.trivyignore` with justification
5. **Test Locally First**: Run validation scripts before pushing

## Common Patterns

### Validation Script Template
```bash
#!/bin/bash
set -e

source ../../../lib/validation-utils.sh

CONTAINER_NAME="my-container"

if [ "$1" == "--cleanup" ]; then
    cleanup_exercise "$CONTAINER_NAME"
    exit 0
fi

exercice_header "Validation: Exercise Title"

# Test 1
if check_container_exists "$CONTAINER_NAME"; then
    success "Container exists"
    ((PASSED++))
else
    error "Container not found"
fi

# Display results
validation_summary $PASSED $TOTAL
```

### Exercise Command Script Template
```bash
#!/bin/bash
# Exercise: [Title]
# Complete the commands below

# TODO: Replace XXXXX with the correct command
podman XXXXX

# Check your work
echo "Verify with: podman ps -a"
```

## Educational Philosophy

This repository prioritizes **learning through practice**:
- Learners write commands themselves (no copy-paste)
- Progressive hints avoid giving direct answers
- Automated validation provides immediate feedback
- Solutions are available but discouraged
- Exercises build on previous knowledge

When modifying content, maintain this hands-on, progressive learning approach.
