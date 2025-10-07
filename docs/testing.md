# Testing

## Running Tests Locally

```bash
./tests/test.sh
```

The test suite includes 28 tests across 4 categories:

- **Smoke Tests**: Quick sanity checks (Docker build, required components)
- **Unit Tests**: Configuration and environment variable handling
- **Integration Tests**: Container startup with various service combinations
- **Functional Tests**: End-to-end RTMP streaming, archiving, and authorization

## Running Individual Test Suites

Individual test suites can be run separately:

```bash
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

For more detailed testing documentation, see [tests/README.md](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/tests/README.md) in the repository.
