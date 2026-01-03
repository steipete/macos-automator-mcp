#!/usr/bin/env node
// server.ts - MCP server entrypoint
// NOTE: SDK ESM/CJS hybrid: imports work at runtime, but types are mapped via tsconfig.json "paths". Suppress TS errors for imports.
// TODO: Replace 'unknown' with proper input types if/when SDK types are available.

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import * as sdkTypes from '@modelcontextprotocol/sdk/types.js';
// import { ZodError } from 'zod'; // ZodError is not directly used from here, handled by SDK or refined errors
import { Logger } from './logger.js';
import { ExecuteScriptInputSchema, GetScriptingTipsInputSchema } from './schemas.js';
import { ScriptExecutor } from './ScriptExecutor.js';
import type { ScriptExecutionError, ExecuteScriptResponse }  from './types.js';
// import pkg from '../package.json' with { type: 'json' }; // Import package.json // REMOVED
import { getKnowledgeBase, getScriptingTipsService, conditionallyInitializeKnowledgeBase } from './services/knowledgeBaseService.js'; // Import KB functions
import { substitutePlaceholders } from './placeholderSubstitutor.js'; // Value import
import type { SubstitutionResult } from './placeholderSubstitutor.js'; // Type import

// Added imports for robust package.json loading
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Robustly load package.json
const __filenameServer = fileURLToPath(import.meta.url);
const packageRootServer = path.resolve(path.dirname(__filenameServer), '..'); // from dist/server.js to package root
const packageJsonPathServer = path.join(packageRootServer, 'package.json');
let pkg: { version: string }; // Define type for pkg
try {
  pkg = JSON.parse(await fs.readFile(packageJsonPathServer, 'utf-8'));
} catch (error) {
  // Fallback or error handling if package.json cannot be read
  // This is critical for npx environments if pathing is an issue
  // Don't log in E2E tests to avoid interfering with MCP protocol
  if (process.env.MCP_E2E_TESTING !== 'true' && process.env.VITEST !== 'true') {
    console.error("Failed to load package.json:", error);
  }
  pkg = { version: "0.0.0-error" }; // Provide a fallback
}

const SERVER_START_TIME_ISO = new Date().toISOString();

const IS_E2E_TESTING = process.env.MCP_E2E_TESTING === 'true' || process.env.VITEST === 'true';
let hasEmittedFirstCallInfo = false; // Flag for first tool call
const serverInfoMessage = `MacOS Automator MCP v${pkg.version}, started at ${SERVER_START_TIME_ISO}`;

const logger = new Logger('macos_automator_server');
const scriptExecutor = new ScriptExecutor();

async function main() {
  if (!IS_E2E_TESTING) {
    logger.info("[Server Startup] Current working directory", { cwd: process.cwd() });
    // console.log("[Server Startup] Environment:", JSON.stringify(process.env, null, 2)); // Potentially too verbose, log specific vars if needed
    // console.log("[Server Startup] PATH:", process.env.PATH);
    // console.log("[Server Startup] HOME:", process.env.HOME);
    // console.log("[Server Startup] USER:", process.env.USER);

    logger.info('Starting macos_automator MCP Server...');
    logger.warn("CRITICAL: Ensure macOS Automation & Accessibility permissions are correctly configured for the application running this server (e.g., Terminal, Node). See README.md for details.");

    // Eagerly initialize Knowledge Base if KB_PARSING is set to eager
    const eagerParseEnv = process.env.KB_PARSING?.toLowerCase();
    if (eagerParseEnv === 'eager') {
      await conditionallyInitializeKnowledgeBase(true);
    } else {
      conditionallyInitializeKnowledgeBase(false); // Log that it's lazy
    }
  }

  const server = new McpServer({
    name: 'macos_automator', // Matches the key in mcp.json
    version: pkg.version, // Dynamically use version from package.json
  });

  server.registerTool(
    'execute_script',
    {
      annotations: {
        title: 'Execute Script',
        destructiveHint: true,
      },
      description: `Automate macOS tasks using AppleScript or JXA (JavaScript for Automation) to control applications like Terminal, Chrome, Safari, Finder, etc.

**1. Script Source (Choose one):**
*   \`kb_script_id\` (string): **Preferred.** Executes a pre-defined script from the knowledge base by its ID. Use \`get_scripting_tips\` to find IDs and inputs. Supports placeholder substitution via \`input_data\` or \`arguments\`. Ex: \`kb_script_id: "safari_get_front_tab_url"\`.
*   \`script_content\` (string): Executes raw AppleScript/JXA code. Good for simple or dynamic scripts. Ex: \`script_content: "tell application \\"Finder\\" to empty trash"\`.
*   \`script_path\` (string): Executes a script from an absolute POSIX path on the server. Ex: \`/Users/user/myscripts/myscript.applescript\`.

**2. Script Inputs (Optional):**
*   \`input_data\` (JSON object): For \`kb_script_id\`, provides named inputs (e.g., \`--MCP_INPUT:keyName\`). Values (string, number, boolean, simple array/object) are auto-converted. Ex: \`input_data: { "folder_name": "New Docs" }\`.
*   \`arguments\` (array of strings): For \`script_path\` (passes to \`on run argv\` / \`run(argv)\`). For \`kb_script_id\`, used for positional args (e.g., \`--MCP_ARG_1\`).

**3. Execution Options (Optional):**
*   \`language\` ('applescript' | 'javascript'): Specify for \`script_content\`/\`script_path\` (default: 'applescript'). Inferred for \`kb_script_id\`.
*   \`timeout_seconds\` (integer, optional, default: 60): Sets the maximum time (in seconds) the script is allowed to run. Increase for potentially long-running operations.
*   \`output_format_mode\` (enum, optional, default: 'auto'): Controls \`osascript\` output formatting.
    *   \`'auto'\`: Smart default - resolves to \`'human_readable'\` for AppleScript and \`'direct'\` for JXA.
    *   \`'human_readable'\`: For AppleScript, uses \`-s h\` flag.
    *   \`'structured_error'\`: For AppleScript, uses \`-s s\` flag (structured errors).
    *   \`'structured_output_and_error'\`: For AppleScript, uses \`-s ss\` flag (structured output & errors).
    *   \`'direct'\`: No special output flags (recommended for JXA).
*   \`include_executed_script_in_output\` (boolean, optional, default: false): If \`true\`, the final script content (after any placeholder substitutions) or script path that was executed will be included in the response. This is useful for debugging and understanding exactly what was run. Defaults to false.
*   \`include_substitution_logs\` (boolean, default: false): For \`kb_script_id\`, includes detailed placeholder substitution logs.
*   \`report_execution_time\` (boolean, optional, default: false): If \`true\`, an additional message with the formatted script execution time will be included in the response. Defaults to false.
`,
      inputSchema: ExecuteScriptInputSchema,
    },
    async (args: unknown) => {
      const input = ExecuteScriptInputSchema.parse(args);
      let execution_time_seconds: number | undefined;
      let scriptContentToExecute: string | undefined = input.script_content;
      let scriptPathToExecute: string | undefined = input.script_path;
      let languageToUse: 'applescript' | 'javascript';
      let finalArgumentsForScriptFile = input.arguments || [];
      let substitutionLogs: string[] = [];

      logger.debug('execute_script called with input:', input);

      // Construct the main part of the response first
      const mainOutputContent: { type: 'text'; text: string }[] = [];

      if (input.kb_script_id) {
        const kb = await getKnowledgeBase();
        const tip = kb.tips.find((t: { id: string }) => t.id === input.kb_script_id);

        if (!tip) {
          throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, `Knowledge base script with ID '${input.kb_script_id}' not found.`);
        }
        if (!tip.script) {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, `Knowledge base script ID '${input.kb_script_id}' has no script content.`);
        }

        languageToUse = tip.language;
        scriptPathToExecute = undefined; 
        finalArgumentsForScriptFile = []; 

        if (tip.script) { // Check if tip.script exists before substitution
            const substitutionResult: SubstitutionResult = substitutePlaceholders({
                scriptContent: tip.script, // Use tip.script directly
                inputData: input.input_data,
                args: input.arguments, // Pass input.arguments which might be undefined
                includeSubstitutionLogs: input.include_substitution_logs || false,
            });

            scriptContentToExecute = substitutionResult.substitutedScript;
            substitutionLogs = substitutionResult.logs;
        }
        logger.info('Executing Knowledge Base script', { id: tip.id, finalLength: scriptContentToExecute?.length });
      } else if (input.script_path || input.script_content) {
        languageToUse = input.language || 'applescript';
        if (input.script_path) {
            logger.debug('Executing script from path', { scriptPath: input.script_path, language: languageToUse });
        } else if (input.script_content) {
            logger.debug('Executing script from content', { language: languageToUse, initialLength: input.script_content.length });
        }
      } else {
        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, "No script source provided (content, path, or KB ID).");
      }
      
      // Log the actual script to be executed (especially useful for KB scripts after substitution)
      if (scriptContentToExecute) {
        logger.debug('Final script content to be executed:', { language: languageToUse, script: scriptContentToExecute });
      } else if (scriptPathToExecute) {
        // For scriptPath, we don't log content here, just that it's a path-based execution
        logger.debug('Executing script via path (content not logged here):', { scriptPath: scriptPathToExecute, language: languageToUse });
      }

      try {
        const result = await scriptExecutor.execute(
          { content: scriptContentToExecute, path: scriptPathToExecute },
          {
            language: languageToUse,
            timeoutMs: (input.timeout_seconds || 60) * 1000,
            output_format_mode: input.output_format_mode || 'auto',
            arguments: scriptPathToExecute ? finalArgumentsForScriptFile : [], 
          }
        );
        execution_time_seconds = result.execution_time_seconds;
        
        if (result.stderr) {
           logger.warn('Script execution produced stderr (even on success)', { stderr: result.stderr });
        }
        
        let isError = false;
        const errorPattern = /^\s*error[:\s-]/i;
        if (errorPattern.test(result.stdout)) {
          isError = true;
        }

        if (input.include_substitution_logs && substitutionLogs.length > 0) {
          const logsHeader = "\n--- Substitution Logs ---\n";
          const logsString = substitutionLogs.join('\n');
          // Prepend to main result, not just stdout string if other parts exist
          mainOutputContent.push({ type: 'text', text: `${logsHeader}${logsString}\n\n--- Original STDOUT ---\n${result.stdout}` });
        }

        mainOutputContent.push({ type: 'text', text: result.stdout });

        if (input.include_executed_script_in_output) {
          let scriptIdentifier = "Script source not determined (should not happen).";
          if (scriptContentToExecute) {
            scriptIdentifier = `\n--- Executed Script Content ---\n${scriptContentToExecute}`;
          } else if (scriptPathToExecute) {
            scriptIdentifier = `\n--- Executed Script Path ---\n${scriptPathToExecute}`;
          }
          mainOutputContent.push({ type: 'text', text: scriptIdentifier });
        }

        // Now, construct the final response with potential first-call info
        const finalResponseContent: { type: 'text'; text: string }[] = [];
        finalResponseContent.push(...mainOutputContent); // Add the actual script output

        if (!IS_E2E_TESTING && !hasEmittedFirstCallInfo) {
          finalResponseContent.push({ type: 'text', text: serverInfoMessage });
          hasEmittedFirstCallInfo = true;
        }

        const response: ExecuteScriptResponse = {
          content: finalResponseContent,
          isError,
        };

        if (input.report_execution_time) {
          const ms = result.execution_time_seconds * 1000;
          let timeMessage = "Script executed in ";
          if (ms < 1) { // Less than 1 millisecond
            timeMessage += "<1 millisecond.";
          } else if (ms < 1000) { // 1ms up to 999ms
            timeMessage += `${ms.toFixed(0)} milliseconds.`;
          } else if (ms < 60000) { // 1 second up to 59.999 seconds
            timeMessage += `${(ms / 1000).toFixed(2)} seconds.`;
          } else {
            const totalSeconds = ms / 1000;
            const minutes = Math.floor(totalSeconds / 60);
            const remainingSeconds = Math.round(totalSeconds % 60);
            timeMessage += `${minutes} minute(s) and ${remainingSeconds} seconds.`;
          }
          response.content.push({ type: 'text', text: `${timeMessage}` });
        }

        return response;

      } catch (error: unknown) {
        const typedError = error as ScriptExecutionError;
        const execError = error as ScriptExecutionError;
        execution_time_seconds = execError.execution_time_seconds;

        let baseErrorMessage = 'Script execution failed. ';
        
        if (execError.name === "UnsupportedPlatformError") {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidRequest, execError.message);
        }
        if (execError.name === "ScriptFileAccessError") {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, execError.message);
        }
        if (execError.isTimeout) {
             throw new sdkTypes.McpError(sdkTypes.ErrorCode.RequestTimeout, `Script execution timed out after ${input.timeout_seconds || 60} seconds.`);
        }

        baseErrorMessage += execError.stderr?.trim() ? `Details: ${execError.stderr.trim()}` : (execError.message || 'No specific error message from script.');
        
        let finalErrorMessage = baseErrorMessage;
        const permissionErrorPattern = /Not authorized|access for assistive devices is disabled|errAEEventNotPermitted|errAEAccessDenied|-1743|-10004/i;
        const likelyPermissionError = execError.stderr && permissionErrorPattern.test(execError.stderr);
        // Sometimes exit code 1 with no stderr can also be a silent permission issue
        const possibleSilentPermissionError = execError.exitCode === 1 && !execError.stderr?.trim(); 

        if (likelyPermissionError || possibleSilentPermissionError) {
            finalErrorMessage = `${baseErrorMessage}\n\nPOSSIBLE PERMISSION ISSUE: Ensure the application running this server (e.g., Terminal, Node) has required permissions in 'System Settings > Privacy & Security > Automation' and 'Accessibility'. See README.md. The target application for the script may also need specific permissions.`;
        }

        // Append the attempted script to the error message
        let scriptIdentifierForError = "Script source not determined (should not happen).";
        if (scriptContentToExecute) {
          scriptIdentifierForError = `\n\n--- Script Attempted (Content) ---\n${scriptContentToExecute}`;
        } else if (scriptPathToExecute) {
          scriptIdentifierForError = `\n\n--- Script Attempted (Path) ---\n${scriptPathToExecute}`;
        }
        finalErrorMessage += scriptIdentifierForError;

        if (input.include_substitution_logs && substitutionLogs.length > 0) {
            finalErrorMessage += `\n\n--- Substitution Logs ---\n${substitutionLogs.join('\n')}`;
        }

        logger.error('execute_script handler error', { execution_time_seconds });

        // Construct a complete error response, with potential first-call info
        const errorOutputParts: string[] = [finalErrorMessage];
        if (!IS_E2E_TESTING && !hasEmittedFirstCallInfo) {
          errorOutputParts.push(serverInfoMessage);
          hasEmittedFirstCallInfo = true;
        }
        
        const errorResponse: ExecuteScriptResponse = {
          content: [{ type: 'text', text: errorOutputParts.join('\n\n') }],
          isError: true,
        };
        
        if (input.report_execution_time && typedError.execution_time_seconds !== undefined) {
          const ms = typedError.execution_time_seconds * 1000;
          let timeMessage = "Script execution failed after ";
          if (ms < 1) { // Less than 1 millisecond
            timeMessage += "<1 millisecond.";
          } else if (ms < 1000) { // 1ms up to 999ms
            timeMessage += `${ms.toFixed(0)} milliseconds.`;
          } else if (ms < 60000) { // 1 second up to 59.999 seconds
            timeMessage += `${(ms / 1000).toFixed(2)} seconds.`;
          } else {
            const totalSeconds = ms / 1000;
            const minutes = Math.floor(totalSeconds / 60);
            const remainingSeconds = Math.round(totalSeconds % 60);
            timeMessage += `${minutes} minute(s) and ${remainingSeconds} seconds.`;
          }
          errorResponse.content.push({ type: 'text', text: `\n${timeMessage}` });
        }
        
        return errorResponse;
      }
    }
  );

  // ADD THE NEW TOOL get_scripting_tips HERE
  server.registerTool(
    'get_scripting_tips',
    {
      annotations: {
        title: 'Get Scripting Tips',
        readOnlyHint: true,
      },
      description: `Discover how to automate any app on your Mac with this comprehensive knowledge base of AppleScript/JXA tips and runnable scripts. This tool is essential for discovery and should be the FIRST CHOICE when aiming to automate macOS tasks, especially those involving common applications or system functions, before attempting to write scripts from scratch. It helps identify pre-built, tested solutions, effectively teaching you how to control virtually any aspect of your macOS experience.

**Primary Use Cases & Parameters:**

*   **Discovering Solutions (Use \`search_term\`):**
    *   Parameter: \`search_term\` (string, optional).
    *   Functionality: Performs a fuzzy search across all tip titles, descriptions, keywords, script content, and IDs. Ideal for natural language queries like "how to..." (e.g., \`search_term: "how do I get the current Safari URL and title?"\`). This is the most common way to find relevant tips.
    *   Output: Returns a list of matching tips in Markdown format.

*   **Limiting Search Results (Use \`limit\`):**
    *   Parameter: \`limit\` (integer, optional, default: 10).
    *   Functionality: Specifies the maximum number of script tips to return when using \`search_term\` or browsing a specific \`category\` (without \`list_categories: true\`). Does not apply if \`list_categories\` is true.

*   **Browsing by Category (Use \`category\`):**
    *   Parameter: \`category\` (string, optional).
    *   Functionality: Shows tips from a specific category. Combine with \`limit\` to control result count.
    *   Example: \`category: "01_intro"\` or \`category: "07_browsers/chrome"\`.

*   **Listing All Categories (Use \`list_categories: true\`):**
    *   Parameter: \`list_categories\` (boolean, optional).
    *   Functionality: Returns a structured list of all available categories with their descriptions. This helps you understand what automation areas are covered.
    *   Output: Category tree in Markdown format.

*   **Refreshing Database (Use \`refresh_database: true\`):**
    *   Parameter: \`refresh_database\` (boolean, optional).
    *   Functionality: Forces a reload of the knowledge base if new scripts have been added. Typically not needed as the database refreshes automatically.

**Best Practices:**
1. **Always start with search**: Use natural language queries to find solutions (e.g., "send email from Mail app").
2. **Browse categories when exploring**: Use \`list_categories: true\` to see available automation areas.
3. **Use specific IDs for execution**: Once you find a script, use its ID with \`execute_script\` tool for precise execution.`,
      inputSchema: GetScriptingTipsInputSchema,
    },
    async (args: unknown) => {
      const input = GetScriptingTipsInputSchema.parse(args);
      
      // Call getScriptingTipsService directly with the input parameters
      let content = await getScriptingTipsService(input);

      // Append first-call info if applicable
      if (!IS_E2E_TESTING && !hasEmittedFirstCallInfo) {
        content += '\n\n' + serverInfoMessage;
        hasEmittedFirstCallInfo = true;
      }

      return {
        content: [{
          type: 'text',
          text: content
        }]
      };
    }
  );

  const transport = new StdioServerTransport();
  await server.connect(transport);

  // Graceful shutdown
  process.on('SIGINT', async () => {
    logger.info('Shutting down macos_automator MCP Server...');
    await server.close();
    process.exit(0);
  });
}

main().catch((error) => {
  logger.error('Fatal error in server', error);
  process.exit(1);
});
