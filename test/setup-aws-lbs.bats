#!/usr/bin/env bats
# Tests for setup-aws-lbs.sh (wrapper script)

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
STUBS="$REPO_ROOT/test/stubs"

setup() {
    # Build a temporary working directory that mirrors the repo layout
    TEST_TMPDIR="$(mktemp -d)"
    export TEST_TMPDIR

    # Copy the wrapper script and sub-scripts into the temp dir
    cp "$REPO_ROOT/setup-aws-lbs.sh" "$TEST_TMPDIR/"
    mkdir -p "$TEST_TMPDIR/src/scripts"
    cp "$REPO_ROOT/src/scripts/setup-aws-infrastructure.sh" "$TEST_TMPDIR/src/scripts/"
    cp "$REPO_ROOT/src/scripts/deploy-backend.sh" "$TEST_TMPDIR/src/scripts/"

    # Provide a pre-existing aws-config.json so deploy-backend.sh doesn't fail on load
    mkdir -p "$TEST_TMPDIR/src"
    cp "$REPO_ROOT/test/fixtures/aws-config.json" "$TEST_TMPDIR/src/aws-config.json"

    # Create stub lambda directories so cd doesn't fail
    mkdir -p "$TEST_TMPDIR/src/lambda/geocode-reverse" "$TEST_TMPDIR/src/lambda/map-credentials"
    echo '{}' > "$TEST_TMPDIR/src/lambda/geocode-reverse/package.json"
    echo '{}' > "$TEST_TMPDIR/src/lambda/map-credentials/package.json"
    touch "$TEST_TMPDIR/src/lambda/geocode-reverse/index.js"
    touch "$TEST_TMPDIR/src/lambda/map-credentials/index.js"

    # Prepend stubs to PATH
    export PATH="$STUBS:$PATH"
}

teardown() {
    rm -rf "$TEST_TMPDIR"
}

@test "setup-aws-lbs.sh: exits 0 when both sub-scripts succeed" {
    run bash "$TEST_TMPDIR/setup-aws-lbs.sh"
    [ "$status" -eq 0 ]
}

@test "setup-aws-lbs.sh: prints step 1/2 and step 2/2 banners" {
    run bash "$TEST_TMPDIR/setup-aws-lbs.sh"
    [[ "$output" == *"Step 1/2"* ]]
    [[ "$output" == *"Step 2/2"* ]]
}

@test "setup-aws-lbs.sh: prints setup complete banner on success" {
    run bash "$TEST_TMPDIR/setup-aws-lbs.sh"
    [[ "$output" == *"Setup complete"* ]]
}

@test "setup-aws-lbs.sh: exits non-zero when sub-script fails" {
    # Make setup-aws-infrastructure.sh fail by removing AWS credentials stub response
    AWS_STUB_FAIL="sts" \
    run bash "$TEST_TMPDIR/setup-aws-lbs.sh"
    [ "$status" -ne 0 ]
}
