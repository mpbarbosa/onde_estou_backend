# CHANGELOG

All notable changes to this project will be documented in this file.

## [Unreleased]
- Initial documentation files created: API, Architecture, Getting Started, Contributing.

## [1.0.0] - 2026-02-19
- Project initialized.
- AWS Location Service Place Index (`onde-estou-place-index`) provisioned.
- AWS Location Service Map (`onde-estou-map`, style `VectorEsriNavigation`) provisioned.
- Lambda functions added: `onde-estou-geocode-reverse`, `onde-estou-map-credentials`.
- API Gateway HTTP API (`onde-estou-api`) configured with CORS.
- IAM role and least-privilege policy created for Lambda execution.
- Infrastructure and deploy scripts added under `src/scripts/`.
