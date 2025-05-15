#!/bin/bash
: "${LOG_LEVEL:=INFO}"
export LOG_LEVEL

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR" || exit

COMPILED_SERVER_JS="dist/server.js"
TYPESCRIPT_SERVER_TS="src/server.ts"

if [ -f "$COMPILED_SERVER_JS" ]; then
    echo "INFO: Running compiled server from $COMPILED_SERVER_JS (LOG_LEVEL: $LOG_LEVEL)..."
    node "$COMPILED_SERVER_JS"
else
    echo "INFO: Compiled server not found. Attempting to run TypeScript source using tsx (LOG_LEVEL: $LOG_LEVEL)..."
    echo "INFO: Make sure 'tsx' is installed (npm install -g tsx, or as a devDependency and use 'npx tsx')."
    npx tsx "$TYPESCRIPT_SERVER_TS"
fi 