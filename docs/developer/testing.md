---
title: Run the Tests
description: Run the test suites locally, and how CI runs them
audience: developers
doc_type: howto
tags: [testing, quality, ci, development]
lastReviewed: 2026-09-29
version: 1.x
---

# Run the Tests

This page describes the test suites and how CI runs them. To add tests for a new service, see [Test a New Service](adding-services/testing.md).

## Run All Tests

```bash
./tests/test.sh
```

`test.sh` builds the `rtmp-multistream:test` image from your working tree, then runs every suite. It ends with `All tests passed!` and exits 0, or lists the failures and exits 1. Functional tests need `ffmpeg` on the host.

## Test Suites

| Suite | File | Covers |
|---|---|---|
| Validation | `tests/00_validation_tests.sh` | Each function in `validate_input.sh`, run inside the container |
| Smoke | `tests/01_smoke_tests.sh` | The image builds and contains nginx, FFmpeg and the RTMP module |
| Unit | `tests/02_unit_tests.sh` | Each startup script: enabling, skipping, substitution, rejecting bad values |
| Integration | `tests/03_integration_tests.sh` | The container starts with each service combination, and stops on an invalid value |
| Functional | `tests/04_functional_tests.sh` | End-to-end streaming, archiving and publish authorization |

## Run One Suite

Only `test.sh` and the smoke tests build the image. Build it before running any other suite on its own:

```bash
docker build -t rtmp-multistream:test .
bash tests/02_unit_tests.sh
```

A suite run on its own ends with `Tests run: <N>, passed: <N>, failed: <N>` and exits non-zero if any test failed.

## CI

`.github/workflows/ci.yml` runs on every push and pull request. Each suite is a separate job:

| Job | Runs after |
|---|---|
| Validation tests (builds the image) | Nothing |
| Smoke tests | Validation tests |
| Unit tests | Validation tests |
| Integration tests | Smoke and unit tests |
| Functional tests | Smoke and unit tests |
| Build and push images | All five test jobs |

For per-function test coverage, see [tests/README.md](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/tests/README.md){target="_blank"}.

## See Also

- [Test a New Service](adding-services/testing.md) - Tests to add for a new service
- [Input Validation Reference](validation.md) - Validation functions and what they reject
