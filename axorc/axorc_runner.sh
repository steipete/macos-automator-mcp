#!/bin/bash
# Simple wrapper script to catch signals and diagnose issues

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

exec "$SCRIPT_DIR/AXorcist/.build/debug/axorc" "$@" 2>/dev/null || exec "$SCRIPT_DIR/AXorcist/.build/release/axorc" "$@" 2>/dev/null || exec "$SCRIPT_DIR/axorc" "$@"
