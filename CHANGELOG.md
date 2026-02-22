# CHANGELOG

All notable changes to this project will be documented in this file.

## [1.0.2] - 2026-02-22

### Fixed

- `geocode-reverse` Lambda: malformed JSON request body now returns 400 instead of 500.
- `geocode-reverse` Lambda: removed `raw: place` field from API response (leaked internal AWS Place object).
- `jq` test stub: repaired `. + {key: "value"}` merge form; URL-colon regex bug caused aws-config to be written as `null` in tests.
- `.gitignore`: anchored `package-lock.json` rule to `/package-lock.json` (root only) so Lambda lockfiles can be tracked.
- `.workflow-config.yaml`: corrected `test_dirs` from `tests` (nonexistent) to `test`; set `test_framework: bats` and `test_command: 'bats test/'`.
- `docs/API.md`: corrected response schema to match actual handler output (added `subRegion`, `interpolated`, `geometry`; removed undocumented `raw` field).

### Added

- `src/lambda/geocode-reverse/package-lock.json` committed for reproducible, auditable Lambda builds.
- `eslint.config.mjs`: ESLint v9+ flat config for Lambda functions; CI `lint-js` job added.
- `.editorconfig`: consistent indentation and whitespace rules across all file types; markdown keeps `trim_trailing_whitespace = false` to preserve intentional `<br>` line-breaks.
- `docs/ARCHITECTURE.md`: Security Model section documenting intentionally-public API, CORS boundary, rate limiting, and IAM wildcard rationale.
- `test/deploy-backend.bats`: added test asserting `aws-config.json` is updated with `apiId` and `apiEndpoint` after deploy.

### Changed

- `npm install --production` → `npm ci --omit=dev` in `deploy-backend.sh` and CI for deterministic, lockfile-pinned installs.
- GitHub Actions CI: added `permissions: contents: read` (least-privilege); added `lint-js` job.
- `docs/.gitkeep` removed (stale placeholder; `docs/` contains real files).

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
