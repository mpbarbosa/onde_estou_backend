# Contributing Guide

Thank you for your interest in contributing!

## Development Setup

1. Clone the repository and navigate into it.
2. Install prerequisites: AWS CLI 2.x+, Node.js 20.x, `jq`, `zip`.
3. Configure AWS credentials: `aws configure`.
4. Review `docs/GETTING_STARTED.md` for full setup instructions.

## Code Style

- Lambda handlers use **CommonJS** (`exports.handler`, `require()`).
- Use clear, descriptive variable names in both shell scripts and JavaScript.
- Comment complex logic — especially AWS coordinate-order quirks.
- Follow existing patterns in `src/lambda/` and `src/scripts/`.

## Pull Requests

- Fork the repository and create a feature branch from `main`.
- Write clear commit messages describing *what* and *why*.
- Ensure shell scripts are executable (`chmod +x`) and tested in a real AWS environment.
- Open a pull request with a description of your changes and any new env vars or resources introduced.

## Reporting Issues

- Use GitHub Issues for bugs or feature requests.
- Include: steps to reproduce, relevant Lambda logs (`aws logs tail ...`), and AWS region.

## Testing

- Manually test Lambda changes by re-running `./src/scripts/deploy-backend.sh` and calling the API.
- Test infrastructure changes in a separate AWS account or with a distinct resource prefix to avoid disrupting production.
- Document any new environment variables in both the script and `docs/API.md`.

Thank you for helping improve this project!
