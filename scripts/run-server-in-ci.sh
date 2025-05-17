#!/bin/bash
# This script ensures the correct working directory for server.js in CI

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT="$SCRIPT_DIR"/..

echo "[run-server-in-ci.sh] SCRIPT_DIR: $SCRIPT_DIR"
echo "[run-server-in-ci.sh] Calculated PROJECT_ROOT: $PROJECT_ROOT"

cd "$PROJECT_ROOT"

echo "[run-server-in-ci.sh] Changed CWD to: $(pwd)"
echo "[run-server-in-ci.sh] Now executing: node dist/server.js"

exec node dist/server.js 