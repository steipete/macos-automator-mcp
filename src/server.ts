#!/usr/bin/env node
import { McpServer, McpError, ErrorCode } from '@modelcontextprotocol/sdk/server/mcp';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio';
// import { ZodError } from 'zod'; // ZodError is not directly used from here, handled by SDK or refined errors
import { Logger } from './logger';
import { ExecuteScriptInputSchema, type ExecuteScriptInput } from './schemas';
import { ScriptExecutor } from './ScriptExecutor';
import type { ScriptExecutionError }  from './types';
import pkg from '../package.json' assert { type: 'json' }; // Import package.json

const logger = new Logger('macos_automator_server');
const scriptExecutor = new ScriptExecutor();

async function main() {
  logger.info('Starting macos_automator MCP Server...');
  logger.warn("CRITICAL: Ensure macOS Automation & Accessibility permissions are correctly configured for the application running this server (e.g., Terminal, Node). See README.md for details.");

  const server = new McpServer({
    name: 'macos_automator', // Matches the key in mcp.json
    version: pkg.version, // Dynamically use version from package.json
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
       { "scriptContent": "tell application "Safari" to get URL of front document" }
    2. Display a notification:
       { "scriptContent": "display notification "Task complete!" with title "MCP"" }
    3. Get files on Desktop:
       { "scriptContent": "tell application "Finder" to get name of every item of desktop" }
    4. Use script-friendly output for a list:
       { "scriptContent": "return {"item a", "item b"}", "useScriptFriendlyOutput": true }
    5. Run a shell command:
       { "scriptContent": "do shell script "ls -la ~/Desktop"" }
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
      } catch (error: unknown) { // Changed from any to unknown
        const execError = error as ScriptExecutionError;
        logger.error('Error in execute_script tool handler', {
          message: execError.message,
          name: execError.name,
          isTimeout: execError.isTimeout,
          stdout: execError.stdout, // Keep stdout for potential debugging info
          stderr: execError.stderr,
        });

        // ZodErrors are typically caught by the MCP SDK layer if schema validation fails before tool execution.
        // This check is more for internal robustness if a ZodError instance were to be thrown from ScriptExecutor for some reason.
        if (execError.name === "ZodError") { 
          throw new McpError(ErrorCode.InvalidParams, `Input validation error: ${execError.message}`);
        }
        if (execError.name === "UnsupportedPlatformError") {
          throw new McpError(ErrorCode.NotSupported, execError.message);
        }
        if (execError.name === "ScriptFileAccessError") {
            throw new McpError(ErrorCode.NotFound, execError.message);
        }
        if (execError.isTimeout) {
          throw new McpError(ErrorCode.Timeout, `Script execution timed out after ${input.timeoutSeconds} seconds.`);
        }

        const stderrMessage = execError.stderr?.trim();
        const execErrorMessage = execError.message || 'No specific error message from script.';
        const errorMessage = `Script execution failed. ${stderrMessage ? `Error details: ${stderrMessage}` : execErrorMessage}`;
        throw new McpError(ErrorCode.InternalError, errorMessage);
      }
    }
  );

  const transport = new StdioServerTransport();
  try {
    await server.connect(transport);
    logger.info(`macos_automator MCP Server v${server.info.version} connected via STDIO and ready.`);
  } catch (error: unknown) { // Changed from any to unknown
    const connectError = error as Error;
    logger.error('Failed to connect server to transport', { message: connectError.message, stack: connectError.stack });
    process.exit(1);
  }
}

// Graceful shutdown
const signals: NodeJS.Signals[] = ['SIGINT', 'SIGTERM', 'SIGQUIT'];
for (const signal of signals) {
  process.on(signal, () => {
    logger.info(`Received ${signal}, shutting down server...`);
    // Perform any cleanup if necessary
    process.exit(0);
  });
}

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
        const mainError = error as Error;
        logger.error("Fatal error during server startup:", { message: mainError.message, stack: mainError.stack });
        process.exit(1);
    });
} 