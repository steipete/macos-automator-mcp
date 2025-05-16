#!/bin/bash
# Simple wrapper script to catch signals and diagnose issues

exec ./.build/debug/x "$@"
