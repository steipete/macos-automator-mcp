#!/bin/bash
# This script ensures the correct working directory for server.js in CI

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT="$SCRIPT_DIR"/..

# Export the environment variable for E2E testing
export MCP_E2E_TESTING=true

# Don't show any debug output when MCP_E2E_TESTING is true (unless DEBUG is explicitly set)
if [ -n "$DEBUG" ]; then
  echo "[run-server-in-ci.sh] SCRIPT_DIR: $SCRIPT_DIR" >&2
  echo "[run-server-in-ci.sh] Calculated PROJECT_ROOT: $PROJECT_ROOT" >&2
fi

cd "$PROJECT_ROOT"

if [ -n "$DEBUG" ]; then
  echo "[run-server-in-ci.sh] Changed CWD to: $(pwd)" >&2
  echo "[run-server-in-ci.sh] Set MCP_E2E_TESTING to $MCP_E2E_TESTING" >&2
  echo "[run-server-in-ci.sh] Now executing: node dist/server.js" >&2
fi

exec node dist/server.js 