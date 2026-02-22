#!/usr/bin/env bats
# Tests for src/scripts/setup-aws-infrastructure.sh

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
STUBS="$REPO_ROOT/test/stubs"

setup() {
    TEST_TMPDIR="$(mktemp -d)"
    export TEST_TMPDIR

    mkdir -p "$TEST_TMPDIR/src/scripts"
    cp "$REPO_ROOT/src/scripts/setup-aws-infrastructure.sh" "$TEST_TMPDIR/src/scripts/"
    mkdir -p "$TEST_TMPDIR/src"

    export PATH="$STUBS:$PATH"
}

teardown() {
    rm -rf "$TEST_TMPDIR"
}

# ── Prerequisite checks ───────────────────────────────────────────────────────

@test "setup-aws-infrastructure.sh: exits 1 when aws CLI is not found" {
    # Shadow the aws stub with a nonexistent path so 'command -v aws' fails
    run bash -c "PATH=/usr/bin:/bin bash '$TEST_TMPDIR/src/scripts/setup-aws-infrastructure.sh'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"AWS CLI is not installed"* ]]
}

@test "setup-aws-infrastructure.sh: exits 1 when AWS credentials are not configured" {
    AWS_STUB_FAIL="sts" \
    run bash -c "cd '$TEST_TMPDIR' && bash src/scripts/setup-aws-infrastructure.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"credentials not configured"* ]]
}

# ── Environment variable handling ─────────────────────────────────────────────

@test "setup-aws-infrastructure.sh: defaults AWS_REGION to us-east-1" {
    unset AWS_REGION
    run bash -c "cd '$TEST_TMPDIR' && bash src/scripts/setup-aws-infrastructure.sh"
    [[ "$output" == *"us-east-1"* ]]
}

@test "setup-aws-infrastructure.sh: respects custom AWS_REGION env var" {
    run bash -c "cd '$TEST_TMPDIR' && AWS_REGION=sa-east-1 bash src/scripts/setup-aws-infrastructure.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"sa-east-1"* ]]
}

# ── Normal execution ──────────────────────────────────────────────────────────

@test "setup-aws-infrastructure.sh: exits 0 with all stubs present" {
    run bash -c "cd '$TEST_TMPDIR' && bash src/scripts/setup-aws-infrastructure.sh"
    [ "$status" -eq 0 ]
}

@test "setup-aws-infrastructure.sh: writes src/aws-config.json on success" {
    bash -c "cd '$TEST_TMPDIR' && bash src/scripts/setup-aws-infrastructure.sh" 2>/dev/null

    [ -f "$TEST_TMPDIR/src/aws-config.json" ]
}

@test "setup-aws-infrastructure.sh: aws-config.json contains expected region field" {
    bash -c "cd '$TEST_TMPDIR' && AWS_REGION=eu-west-1 bash src/scripts/setup-aws-infrastructure.sh" 2>/dev/null

    run grep '"region"' "$TEST_TMPDIR/src/aws-config.json"
    [[ "$output" == *"eu-west-1"* ]]
}

@test "setup-aws-infrastructure.sh: prints setup complete banner on success" {
    run bash -c "cd '$TEST_TMPDIR' && bash src/scripts/setup-aws-infrastructure.sh"
    [[ "$output" == *"Infrastructure Setup Complete"* ]]
}

@test "setup-aws-infrastructure.sh: cleans up temp policy files on success" {
    bash -c "cd '$TEST_TMPDIR' && bash src/scripts/setup-aws-infrastructure.sh" 2>/dev/null

    [ ! -f /tmp/lambda-trust-policy.json ]
    [ ! -f /tmp/location-policy.json ]
}
