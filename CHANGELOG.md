# CHANGELOG

All notable changes to this project will be documented in this file.

## [Unreleased]

- Hardened all three shell scripts from `set -e` to `set -euo pipefail`; bumped script header versions to 1.0.2.
- Added BATS integration tests for `setup-aws-lbs.sh`, `deploy-backend.sh`, and `setup-aws-infrastructure.sh` with AWS/jq/npm/zip stubs.
- Added GitHub Actions CI workflow for automated markdown linting and BATS test execution.
- Added usage and environment variable documentation to `deploy-backend.sh` and `setup-aws-infrastructure.sh` script headers.
- Fixed `MD024` markdownlint rule to allow duplicate headings under different parent sections (API docs pattern).

## [1.0.1] - 2026-02-21

- Added `setup-aws-lbs.sh` convenience wrapper documented in README (runs setup + deploy in one command).
- Added `src/aws-config.example.json` template to document the generated config structure.
- Fixed `src/README.md` script paths to use repo-root-relative `./src/scripts/` prefix.
- Fixed 10 shellcheck SC2292 warnings: replaced `[ ]` with `[[ ]]` in all bash conditionals.
- Fixed shellcheck SC2312 warning: eliminated `echo | awk` pipe inside command substitution.
- Bumped Lambda package versions from 1.0.0 to 1.0.1.

## [1.0.0] - 2026-02-19

- Project initialized.
- AWS Location Service Place Index (`onde-estou-place-index`) provisioned.
- AWS Location Service Map (`onde-estou-map`, style `VectorEsriNavigation`) provisioned.
- Lambda functions added: `onde-estou-geocode-reverse`, `onde-estou-map-credentials`.
- API Gateway HTTP API (`onde-estou-api`) configured with CORS.
- IAM role and least-privilege policy created for Lambda execution.
- Infrastructure and deploy scripts added under `src/scripts/`.
