**Detailed Specification for `macos_automator` MCP Server (for AI Implementation)**

**Project Goal:** Create a robust Node.js-based MCP server, `macos_automator`, that exposes a single tool (`execute_script`) to run AppleScript and JavaScript for Automation (JXA) scripts on macOS. The server must handle inline scripts and script files, provide detailed error reporting, and be configurable for timeout and output style.

**I. Project Structure (Directory Layout):**

```
macos-automator-mcp/
├── src/
│   ├── server.ts             # Main MCP server logic, tool definition, entry point
│   ├── ScriptExecutor.ts     # Core logic for calling 'osascript'
│   ├── logger.ts             # Logging utility
│   ├── schemas.ts            # Zod schemas for MCP tool inputs/outputs
│   └── types.ts              # Shared TypeScript types
├── docs/                     # Placeholder for permission screenshots
│   ├── automation-permissions-example.png
│   └── accessibility-permissions-example.png
├── .gitignore
├── DEVELOPMENT.md            # Guide for local development setup
├── LICENSE                   # e.g., MIT
├── README.md                 # Main project documentation
├── package.json
├── start.sh                  # Script for local execution (using tsx or node)
└── tsconfig.json
```

**II. Core Components & TypeScript Implementation Details:**

**A. `src/types.ts` (Shared Types)**

```typescript
// src/types.ts
export type LogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';

export interface ScriptExecutionOptions {
  language?: 'applescript' | 'javascript';
  timeoutMs?: number;
  useScriptFriendlyOutput?: boolean;
  arguments?: string[]; // For script files
}

export interface ScriptExecutionResult {
  stdout: string;
  stderr: string; // To capture warnings even on success
}

// Error structure returned by ScriptExecutor on failure
export interface ScriptExecutionError extends Error {
  stdout?: string;
  stderr?: string;
  exitCode?: number | null;
  signal?: string | null;
  killed?: boolean; // Specifically for timeouts
  originalError?: any; // The raw error from child_process
  isTimeout?: boolean;
}
```

**B. `src/logger.ts` (Logging Utility)**

```typescript
// src/logger.ts
import { LogLevel } from './types';

const LOG_LEVELS: Record<LogLevel, number> = {
  DEBUG: 0,
  INFO: 1,
  WARN: 2,
  ERROR: 3,
};

export class Logger {
  private currentLogLevel: number;
  private context: string;

  constructor(context: string = 'MCP_Server') {
    this.context = context;
    const envLogLevel = process.env.LOG_LEVEL?.toUpperCase() as LogLevel | undefined;
    this.currentLogLevel = envLogLevel && LOG_LEVELS[envLogLevel] !== undefined
      ? LOG_LEVELS[envLogLevel]
      : LOG_LEVELS.INFO;
  }

  private log(level: LogLevel, message: string, data?: Record<string, any>): void {
    if (LOG_LEVELS[level] >= this.currentLogLevel) {
      const timestamp = new Date().toISOString();
      const dataString = data ? ` ${JSON.stringify(data)}` : '';
      console.error(`[${timestamp}] [${this.context}] [${level}] ${message}${dataString}`);
    }
  }

  debug(message: string, data?: Record<string, any>): void {
    this.log('DEBUG', message, data);
  }

  info(message: string, data?: Record<string, any>): void {
    this.log('INFO', message, data);
  }

  warn(message: string, data?: Record<string, any>): void {
    this.log('WARN', message, data);
  }

  error(message: string, data?: Record<string, any>): void {
    this.log('ERROR', message, data);
  }
}
```

**C. `src/schemas.ts` (Zod Schemas)**

```typescript
// src/schemas.ts
import { z } from 'zod';

export const ExecuteScriptInputSchema = z.object({
  scriptContent: z.string().optional()
    .describe("The raw AppleScript or JXA code to execute. Mutually exclusive with scriptPath."),
  scriptPath: z.string().optional()
    .describe("The absolute POSIX path to a script file (.scpt, .applescript, .js for JXA) on the server. Mutually exclusive with scriptContent."),
  language: z.enum(['applescript', 'javascript']).optional().default('applescript')
    .describe("The scripting language to use. Defaults to 'applescript'."),
  arguments: z.array(z.string()).optional().default([])
    .describe("An array of string arguments to pass to the script file (primarily for scripts run via scriptPath). These are available in the 'on run argv' handler in AppleScript or 'run(argv)' function in JXA."),
  timeoutSeconds: z.number().int().positive().optional().default(30)
    .describe("Maximum execution time for the script in seconds. Defaults to 30 seconds."),
  useScriptFriendlyOutput: z.boolean().optional().default(false)
    .describe("If true, instructs 'osascript' to use script-friendly output format (-ss flag). This can affect how lists and other data types are returned. Defaults to false (human-readable output).")
}).refine(data => {
    return (data.scriptContent !== undefined && data.scriptPath === undefined) ||
           (data.scriptContent === undefined && data.scriptPath !== undefined);
}, {
    message: "Exactly one of 'scriptContent' or 'scriptPath' must be provided.",
    path: ["scriptContent", "scriptPath"], // Indicate which fields are involved in the refinement
});

export type ExecuteScriptInput = z.infer<typeof ExecuteScriptInputSchema>;

// Output is always { content: [{ type: "text", text: "string_output" }] }
// No specific Zod schema needed for output beyond what MCP SDK handles.
```

**D. `src/ScriptExecutor.ts` (Core `osascript` Logic)**

```typescript
// src/ScriptExecutor.ts
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import fs from 'node:fs/promises';
import os from 'node:os';
import { Logger } from './logger';
import { ScriptExecutionOptions, ScriptExecutionResult, ScriptExecutionError } from './types';

const execFileAsync = promisify(execFile);
const logger = new Logger('ScriptExecutor');

export class ScriptExecutor {
  public async execute(
    scriptSource: { content?: string; path?: string },
    options: ScriptExecutionOptions = {}
  ): Promise<ScriptExecutionResult> {
    if (os.platform() !== 'darwin') {
      const platformError = new Error('AppleScript/JXA execution is only supported on macOS.') as ScriptExecutionError;
      platformError.name = "UnsupportedPlatformError";
      throw platformError;
    }

    const {
      language = 'applescript',
      timeoutMs = 30000, // Default 30 seconds
      useScriptFriendlyOutput = false,
      arguments: scriptArgs = [],
    } = options;

    const osaArgs: string[] = [];

    if (language === 'javascript') {
      osaArgs.push('-l', 'JavaScript');
    }

    if (useScriptFriendlyOutput) {
      osaArgs.push('-ss'); // Script-friendly output (structured)
    } else {
      osaArgs.push('-s', 'h'); // Human-readable output (default behavior if no -s flag)
    }

    let scriptToLog: string;

    if (scriptSource.content !== undefined) {
      osaArgs.push('-e', scriptSource.content);
      scriptToLog = scriptSource.content.length > 200 ? scriptSource.content.substring(0, 200) + '...' : scriptSource.content;
    } else if (scriptSource.path) {
      try {
        await fs.access(scriptSource.path, fs.constants.R_OK);
      } catch (accessError) {
        logger.error('Script file access error', { path: scriptSource.path, error: (accessError as Error).message });
        const fileError = new Error(`Script file not found or not readable: ${scriptSource.path}`) as ScriptExecutionError;
        fileError.name = "ScriptFileAccessError";
        throw fileError;
      }
      osaArgs.push(scriptSource.path);
      scriptToLog = `File: ${scriptSource.path}`;
    } else {
      // This case should be prevented by Zod validation in server.ts
      const sourceError = new Error('Either scriptContent or scriptPath must be provided.') as ScriptExecutionError;
      sourceError.name = "InvalidScriptSourceError";
      throw sourceError;
    }

    // Add script arguments AFTER script path or -e flags
    osaArgs.push(...scriptArgs);

    logger.debug('Executing osascript', { command: 'osascript', args: osaArgs.map(arg => arg.length > 50 ? arg.substring(0,50) + '...' : arg), scriptToLog });

    try {
      const { stdout, stderr } = await execFileAsync('osascript', osaArgs, { timeout: timeoutMs, windowsHide: true });
      if (stderr && stderr.trim()) {
        logger.warn('osascript produced stderr output on successful execution', { stderr: stderr.trim() });
      }
      return { stdout: stdout.trim(), stderr: stderr.trim() };
    } catch (error: any) {
      const execError = error as ScriptExecutionError;
      execError.isTimeout = !!error.killed; // 'killed' is true if process was terminated (e.g. by timeout)
      execError.originalError = error; // Preserve original error
      
      logger.error('osascript execution failed', {
        message: execError.message,
        stdout: execError.stdout?.trim(),
        stderr: execError.stderr?.trim(),
        exitCode: execError.code, // Note: 'code' is used by child_process, not 'exitCode' directly on error
        signal: execError.signal,
        isTimeout: execError.isTimeout,
        scriptToLog,
      });
      // Re-throw with enriched info; server.ts will wrap in McpError
      throw execError;
    }
  }
}
```

**E. `src/server.ts` (Main MCP Server Logic)**

```typescript
// src/server.ts
#!/usr/bin/env node
import { McpServer, McpError, ErrorCode } from '@modelcontextprotocol/sdk/server/mcp';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio';
import { ZodError } from 'zod';
import { Logger } from './logger';
import { ExecuteScriptInputSchema, ExecuteScriptInput } from './schemas';
import { ScriptExecutor } from './ScriptExecutor';
import { ScriptExecutionError }  from './types';

const logger = new Logger('macos_automator_server');
const scriptExecutor = new ScriptExecutor();

async function main() {
  logger.info('Starting macos_automator MCP Server...');
  logger.warn("CRITICAL: Ensure macOS Automation & Accessibility permissions are correctly configured for the application running this server (e.g., Terminal, Node). See README.md for details.");

  const server = new McpServer({
    name: 'macos_automator', // Matches the key in mcp.json
    version: '0.1.0', // TODO: Update with package.json version
    onLog: (level, message, data) => { // Optional: Hook MCP internal logs to our logger
      logger[level.toLowerCase() as 'debug' | 'info' | 'warn' | 'error']?.(`[MCP_SDK] ${message}`, data);
    }
  });

  server.tool(
    'execute_script',
    `Executes an AppleScript or JavaScript for Automation (JXA) script on macOS.
    The script can be provided as inline content or by specifying an absolute POSIX path to a script file on the server.
    Returns the standard output (stdout) of the script.

    SECURITY WARNING:
    - Executing arbitrary scripts carries inherent security risks. Ensure the source of scripts is trusted.
    - This tool can interact with ANY scriptable application, access the file system, and run shell commands via AppleScript's 'do shell script'.

    MACOS PERMISSIONS (CRITICAL - SEE README.MD FOR FULL DETAILS):
    - The application running THIS MCP server (e.g., Terminal, Node.js app) requires explicit user permission.
    - Set in: System Settings > Privacy & Security > Automation (to control other apps like Finder, Safari, Mail).
    - Set in: System Settings > Privacy & Security > Accessibility (for UI scripting via "System Events").
    - These permissions must be granted ON THE MACOS MACHINE WHERE THIS SERVER IS RUNNING.
    - First-time attempts to control a new app may still trigger a macOS confirmation prompt.

    LANGUAGE SUPPORT:
    - AppleScript (default): Powerful for controlling macOS applications and UI.
    - JavaScript for Automation (JXA): Use JavaScript syntax for macOS automation. Specify with 'language: "javascript"'.

    SCRIPT ARGUMENTS (for scriptPath):
    - Arguments passed in the 'arguments' array are available to the script.
    - AppleScript: 'on run argv ... end run' (argv is a list of strings).
    - JXA: 'function run(argv) { ... }' (argv is an array of strings).

    OUTPUT:
    - The result of the last evaluated expression in the script is returned as text.
    - Use 'useScriptFriendlyOutput: true' for '-ss' flag, which can provide more structured output for lists, etc.

    EXAMPLES (AppleScript):
    1. Get current Safari URL:
       { "scriptContent": "tell application \"Safari\" to get URL of front document" }
    2. Display a notification:
       { "scriptContent": "display notification \"Task complete!\" with title \"MCP\"" }
    3. Get files on Desktop:
       { "scriptContent": "tell application \"Finder\" to get name of every item of desktop" }
    4. Use script-friendly output for a list:
       { "scriptContent": "return {\"item a\", \"item b\"}", "useScriptFriendlyOutput": true }
    5. Run a shell command:
       { "scriptContent": "do shell script \"ls -la ~/Desktop\"" }
    6. Execute a script file with arguments:
       { "scriptPath": "/Users/Shared/myscripts/greet.applescript", "arguments": ["Alice"] }
       (greet.applescript: 'on run argv\n display dialog ("Hello " & item 1 of argv)\nend run')

    EXAMPLES (JXA - set 'language: "javascript"'):
    1. Get Finder version:
       { "scriptContent": "Application('Finder').version()", "language": "javascript" }
    2. Display a dialog:
       { "scriptContent": "Application.currentApplication().includeStandardAdditions = true; Application.currentApplication().displayDialog('Hello from JXA!')", "language": "javascript" }
    `,
    ExecuteScriptInputSchema,
    async (input: ExecuteScriptInput) => {
      logger.info('execute_script tool called', { 
        hasContent: !!input.scriptContent, 
        path: input.scriptPath,
        lang: input.language 
      });

      try {
        const result = await scriptExecutor.execute(
          { content: input.scriptContent, path: input.scriptPath },
          {
            language: input.language,
            timeoutMs: input.timeoutSeconds * 1000,
            useScriptFriendlyOutput: input.useScriptFriendlyOutput,
            arguments: input.arguments,
          }
        );
        logger.info('Script executed successfully', { stdoutLength: result.stdout.length, stderrLength: result.stderr.length });
        if (result.stderr) {
          // Log stderr as a warning even on success, as it might contain script warnings
           logger.warn('Script produced stderr output on success', { stderr: result.stderr });
        }
        return {
          content: [{ type: 'text', text: result.stdout }],
        };
      } catch (error: any) {
        const execError = error as ScriptExecutionError;
        logger.error('Error in execute_script tool handler', {
          message: execError.message,
          name: execError.name,
          isTimeout: execError.isTimeout,
          stderr: execError.stderr,
        });

        if (execError.name === "ZodError") { // Should be caught by SDK, but good practice
          throw new McpError(ErrorCode.InvalidParams, `Input validation failed: ${execError.message}`);
        }
        if (execError.name === "UnsupportedPlatformError") {
          throw new McpError(ErrorCode.NotSupported, execError.message);
        }
        if (execError.name === "ScriptFileAccessError") {
            // Distinguish between NotFound and Forbidden based on more specific checks if possible,
            // but fs.access error often doesn't give enough detail easily.
            // For simplicity, using NotFound, or could use a generic Forbidden/InternalError.
            throw new McpError(ErrorCode.NotFound, execError.message);
        }
        if (execError.isTimeout) {
          throw new McpError(ErrorCode.Timeout, `Script execution timed out after ${input.timeoutSeconds} seconds.`);
        }

        const errorMessage = `Script execution failed. ${execError.stderr?.trim() ? 'Error details: ' + execError.stderr.trim() : (execError.message || 'No specific error message from script.')}`;
        throw new McpError(ErrorCode.InternalError, errorMessage);
      }
    }
  );

  const transport = new StdioServerTransport();
  try {
    await server.connect(transport);
    logger.info(`macos_automator MCP Server v${server.info.version} connected via STDIO and ready.`);
  } catch (error: any) {
    logger.error('Failed to connect server to transport', { message: error.message, stack: error.stack });
    process.exit(1);
  }
}

// Graceful shutdown
const signals: NodeJS.Signals[] = ['SIGINT', 'SIGTERM', 'SIGQUIT'];
signals.forEach(signal => {
  process.on(signal, () => {
    logger.info(`Received ${signal}, shutting down server...`);
    // Perform any cleanup if necessary
    process.exit(0);
  });
});

// Global error handlers
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', { message: error.message, stack: error.stack });
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', { promise, reason: reason instanceof Error ? reason.message : reason });
  process.exit(1);
});


if (import.meta.url === `file://${process.argv[1]}`) {
    main().catch(error => {
        logger.error("Fatal error during server startup:", { message: error.message, stack: error.stack });
        process.exit(1);
    });
}
```

**III. `package.json` (Key Fields):**

```json
{
  "name": "@your-npm-username/macos-automator-mcp", // TODO: Change
  "version": "0.1.0",
  "description": "MCP Server to execute AppleScript and JXA on macOS.",
  "type": "module",
  "main": "dist/server.js",
  "bin": {
    "macos-automator-mcp": "dist/server.js" // Makes it runnable after global install or via npx
  },
  "scripts": {
    "build": "tsc",
    "start": "node dist/server.js",
    "dev": "tsx src/server.ts", // For use with start.sh or direct dev
    "lint": "eslint . --ext .ts",
    "format": "prettier --write \"src/**/*.ts\" \"*.md\"",
    "test": "echo \"Error: no test specified\" && exit 1" // TODO: Add tests
  },
  "keywords": [
    "mcp",
    "applescript",
    "jxa",
    "macos",
    "automation"
  ],
  "author": "Your Name", // TODO: Change
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/your-username/macos-automator-mcp.git" // TODO: Change
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.2.0", // Check for latest version
    "zod": "^3.22.0" // Check for latest version
  },
  "devDependencies": {
    "@types/node": "^18.0.0", // Or latest LTS
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.0.0",
    "eslint-config-prettier": "^9.0.0",
    "prettier": "^3.0.0",
    "tsx": "^4.0.0", // For start.sh and dev script
    "typescript": "^5.0.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

**IV. `README.md` (Skeleton - See previous response for full content)**

*   **Title:** macOS Automator MCP Server
*   **Overview:** Brief description.
*   **Benefits:** Why use this.
*   **Prerequisites:** Node.js, macOS, **CRITICAL PERMISSIONS SETUP (with links to screenshot placeholders in `docs/`)**.
*   **Installation & Usage:**
    *   Focus on `npx @your-npm-username/macos-automator-mcp@latest`
    *   Example `mcp.json` configuration.
*   **Tool Provided: `execute_script`**
    *   **Full Description (from `server.ts`'s tool description - this is key for the AI user).**
    *   Arguments (briefly list, link to schema for details if too long).
    *   Example MCP Requests (AppleScript & JXA, inline & file, with args).
*   **Key Use Cases & Examples (of scripts one might run):**
    *   Application control (Safari URL, Mail subjects).
    *   File system (List Desktop files).
    *   System interactions (Notifications, Volume).
*   **Troubleshooting:** Common errors (Permissions, Script syntax, Timeouts).
*   **Configuration via Environment Variables:** `LOG_LEVEL`.
*   **For Developers:** Link to `DEVELOPMENT.md`.
*   **Contributing & License.**

**V. `DEVELOPMENT.md` (Skeleton - See previous response)**

*   Covers cloning, `npm install`, using `start.sh` for local testing with MCP client, `npm link` (if making a distinct CLI), and general dev notes.

**VI. `start.sh` (for local execution)**

(Same as previously provided, ensuring it can run `tsx src/server.ts` or `node dist/server.js`).

```bash
#!/bin/bash
: "${LOG_LEVEL:=INFO}"
export LOG_LEVEL
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"
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
```

**VII. AI Implementation Notes:**

1.  **Permissions are Key:** The AI must understand that the server *itself* cannot grant macOS TCC permissions. The documentation produced must make this exceptionally clear to the human user setting up the server.
2.  **Error Propagation:** The chain of error handling (from `child_process` -> `ScriptExecutor` -> `server.ts` tool handler -> `McpError`) is crucial for good diagnostics.
3.  **Security:** While the tool description warns about security, the server itself should not attempt to sanitize script content. It executes what it's given. The trust boundary is at the client providing the script.
4.  **Statelessness:** The server is stateless between `execute_script` calls.
5.  **`osascript` Path:** Relies on `osascript` being in the system's default PATH for the Node.js process. This is standard on macOS.
6.  **Testing:** The AI should be prompted to consider how different error conditions from `osascript` (syntax errors, runtime AppleScript errors, file not found for `scriptPath`, timeouts) would be handled and reported.

This detailed specification should provide a solid blueprint for an AI to generate the `macos_automator` MCP server. The emphasis on clear documentation (especially permissions), robust error handling, and a flexible single tool will make it powerful and user-friendly.