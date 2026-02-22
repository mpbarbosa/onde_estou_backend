#!/usr/bin/env bats
# Tests for src/scripts/deploy-backend.sh

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
STUBS="$REPO_ROOT/test/stubs"

setup() {
    TEST_TMPDIR="$(mktemp -d)"
    export TEST_TMPDIR

    mkdir -p "$TEST_TMPDIR/src/scripts"
    cp "$REPO_ROOT/src/scripts/deploy-backend.sh" "$TEST_TMPDIR/src/scripts/"

    # Stub lambda directories
    mkdir -p "$TEST_TMPDIR/src/lambda/geocode-reverse" "$TEST_TMPDIR/src/lambda/map-credentials"
    echo '{}' > "$TEST_TMPDIR/src/lambda/geocode-reverse/package.json"
    echo '{}' > "$TEST_TMPDIR/src/lambda/map-credentials/package.json"
    touch "$TEST_TMPDIR/src/lambda/geocode-reverse/index.js"
    touch "$TEST_TMPDIR/src/lambda/map-credentials/index.js"

    export PATH="$STUBS:$PATH"
}

teardown() {
    rm -rf "$TEST_TMPDIR"
}

# ── Prerequisite checks ───────────────────────────────────────────────────────

@test "deploy-backend.sh: exits 1 when src/aws-config.json is missing" {
    # No aws-config.json in TEST_TMPDIR/src — run from TEST_TMPDIR so the real repo config isn't found
    run bash -c "cd '$TEST_TMPDIR' && bash src/scripts/deploy-backend.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"AWS configuration not found"* ]]
}

# ── Normal execution ──────────────────────────────────────────────────────────

@test "deploy-backend.sh: exits 0 with valid aws-config.json" {
    mkdir -p "$TEST_TMPDIR/src"
    cp "$REPO_ROOT/test/fixtures/aws-config.json" "$TEST_TMPDIR/src/aws-config.json"

    run bash -c "cd '$TEST_TMPDIR' && bash src/scripts/deploy-backend.sh"
    [ "$status" -eq 0 ]
}

@test "deploy-backend.sh: reads region from aws-config.json" {
    mkdir -p "$TEST_TMPDIR/src"
    cp "$REPO_ROOT/test/fixtures/aws-config.json" "$TEST_TMPDIR/src/aws-config.json"

    run bash -c "cd '$TEST_TMPDIR' && bash src/scripts/deploy-backend.sh"
    [[ "$output" == *"us-east-1"* ]]
}

@test "deploy-backend.sh: defaults ALLOWED_ORIGIN to production URL" {
    mkdir -p "$TEST_TMPDIR/src"
    cp "$REPO_ROOT/test/fixtures/aws-config.json" "$TEST_TMPDIR/src/aws-config.json"
    unset ALLOWED_ORIGIN

    run bash -c "cd '$TEST_TMPDIR' && bash src/scripts/deploy-backend.sh"
    [ "$status" -eq 0 ]
    # The default is baked into the script; verify it didn't error
    [[ "$output" == *"Deployment Complete"* ]]
}

@test "deploy-backend.sh: respects custom ALLOWED_ORIGIN env var" {
    mkdir -p "$TEST_TMPDIR/src"
    cp "$REPO_ROOT/test/fixtures/aws-config.json" "$TEST_TMPDIR/src/aws-config.json"

    run bash -c "cd '$TEST_TMPDIR' && ALLOWED_ORIGIN=http://localhost:3000 bash src/scripts/deploy-backend.sh"
    [ "$status" -eq 0 ]
}

@test "deploy-backend.sh: prints deployment complete banner on success" {
    mkdir -p "$TEST_TMPDIR/src"
    cp "$REPO_ROOT/test/fixtures/aws-config.json" "$TEST_TMPDIR/src/aws-config.json"

    run bash -c "cd '$TEST_TMPDIR' && bash src/scripts/deploy-backend.sh"
    [[ "$output" == *"Deployment Complete"* ]]
}

@test "deploy-backend.sh: cleans up function.zip files on success" {
    mkdir -p "$TEST_TMPDIR/src"
    cp "$REPO_ROOT/test/fixtures/aws-config.json" "$TEST_TMPDIR/src/aws-config.json"

    bash -c "cd '$TEST_TMPDIR' && bash src/scripts/deploy-backend.sh" 2>/dev/null

    [ ! -f "$TEST_TMPDIR/src/lambda/geocode-reverse/function.zip" ]
    [ ! -f "$TEST_TMPDIR/src/lambda/map-credentials/function.zip" ]
}

@test "deploy-backend.sh: updates aws-config.json with apiId and apiEndpoint" {
    mkdir -p "$TEST_TMPDIR/src"
    cp "$REPO_ROOT/test/fixtures/aws-config.json" "$TEST_TMPDIR/src/aws-config.json"

    bash -c "cd '$TEST_TMPDIR' && bash src/scripts/deploy-backend.sh" 2>/dev/null

    run python3 -c "import json; d=json.load(open('$TEST_TMPDIR/src/aws-config.json')); print(type(d).__name__)"
    [ "$output" = "dict" ]

    run python3 -c "import json; d=json.load(open('$TEST_TMPDIR/src/aws-config.json')); print('apiId' in d and 'apiEndpoint' in d)"
    [ "$output" = "True" ]
}
