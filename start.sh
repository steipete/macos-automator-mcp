#!/bin/bash
# start.sh

export LOG_LEVEL="${LOG_LEVEL:-INFO}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

DIST_SERVER_JS="$PROJECT_ROOT/dist/server.js"
SRC_SERVER_TS="$PROJECT_ROOT/src/server.ts"

if [ -f "$DIST_SERVER_JS" ]; then
  # echo "INFO: Compiled version found. Running from dist/server.js" >&2 # Silenced
  exec node "$DIST_SERVER_JS"
else
  # echo "INFO: Making sure tsx is available..." >&2 # Silenced
  if ! command -v tsx &> /dev/null && ! [ -f "$PROJECT_ROOT/node_modules/.bin/tsx" ]; then
    echo "WARN: tsx command not found locally or globally. Attempting to install via npm..." >&2
    (cd "$PROJECT_ROOT" && npm install tsx --no-save)
    if ! [ -f "$PROJECT_ROOT/node_modules/.bin/tsx" ]; then
        echo "ERROR: Failed to install tsx. Please install it manually or build the project." >&2
        exit 1
    fi
  fi
  
  TSX_PATH="$PROJECT_ROOT/node_modules/.bin/tsx"
  if ! command -v tsx &> /dev/null; then
      if [ ! -f "$TSX_PATH" ]; then
          echo "ERROR: tsx not found globally or locally at $TSX_PATH. Cannot run from source." >&2
          exit 1
      fi
      # echo "INFO: Running from src/server.ts using local tsx ($TSX_PATH)" >&2 # Silenced
      exec "$TSX_PATH" "$SRC_SERVER_TS"
  else
      # echo "INFO: Running from src/server.ts using global tsx" >&2 # Silenced
      exec tsx "$SRC_SERVER_TS"
  fi
fi 
