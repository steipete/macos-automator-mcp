#!/bin/bash
# Simple wrapper script to catch signals and diagnose issues

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

exec "$SCRIPT_DIR/ax" "$@"
