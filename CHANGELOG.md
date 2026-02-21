# CHANGELOG

All notable changes to this project will be documented in this file.

## [Unreleased]

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
