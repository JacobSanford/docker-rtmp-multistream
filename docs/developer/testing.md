---
title: Testing
description: Overview of the test suite and how to run tests
audience: developers
doc_type: howto
tags: [testing, quality, ci, development]
lastReviewed: 2025-10-21
version: 1.x
---

# Testing

!!! info "Developer Guide"
    This page provides a high-level overview. For detailed guidance on adding tests for new services, see [Adding Service Tests](adding-services/testing.md).

## Running Tests Locally

```bash
./tests/test.sh
```

The test suite includes tests across five categories:

- **Validation Tests**: Input validation and security testing
- **Smoke Tests**: Quick sanity checks (Docker build, required components)
- **Unit Tests**: Configuration and environment variable handling (including security validation)
- **Integration Tests**: Container startup with various service combinations
- **Functional Tests**: End-to-end RTMP streaming, archiving, and authorization

## Test Philosophy

All tests follow fail-fast principles with automatic cleanup. Tests are designed to:

1. **Validate security**: Reject malicious inputs (command injection, path traversal)
2. **Verify configuration**: Ensure services enable/disable correctly
3. **Check integration**: Confirm container startup with various combinations
4. **Test functionality**: Validate end-to-end streaming workflows

## Running Individual Test Suites

Individual test suites can be run separately:

```bash
bash tests/00_validation_tests.sh  # Validation tests
bash tests/01_smoke_tests.sh      # Smoke tests
bash tests/02_unit_tests.sh       # Unit tests
bash tests/03_integration_tests.sh # Integration tests
bash tests/04_functional_tests.sh  # Functional tests (requires ffmpeg)
```

Tests automatically clean up containers and temporary files. Exit code 0 = all passed, 1 = failures.

## CI/CD

GitHub Actions automatically runs all test suites on every push and PR via `.github/workflows/ci.yml`. Each test type runs as a separate job:

- Smoke Tests (runs first)
- Unit Tests (after smoke tests pass)
- Integration Tests (after smoke tests pass)
- Functional Tests (after smoke tests pass)

For more detailed testing documentation, see [tests/README.md](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/tests/README.md){target="_blank"} in the repository.
