#!/usr/bin/env node
// server.ts - MCP server entrypoint
// NOTE: SDK ESM/CJS hybrid: imports work at runtime, but types are mapped via tsconfig.json "paths". Suppress TS errors for imports.
// TODO: Replace 'unknown' with proper input types if/when SDK types are available.

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import * as sdkTypes from '@modelcontextprotocol/sdk/types.js';
// import { ZodError } from 'zod'; // ZodError is not directly used from here, handled by SDK or refined errors
import { Logger } from './logger.js';
import { ExecuteScriptInputSchema, GetScriptingTipsInputSchema, AXQueryInputSchema, type AXQueryInput } from './schemas.js';
import { ScriptExecutor } from './ScriptExecutor.js';
import { AXQueryExecutor } from './AXQueryExecutor.js';
import type { ScriptExecutionError, ExecuteScriptResponse }  from './types.js';
// import pkg from '../package.json' with { type: 'json' }; // Import package.json // REMOVED
import { getKnowledgeBase, getScriptingTipsService, conditionallyInitializeKnowledgeBase } from './services/knowledgeBaseService.js'; // Import KB functions
import { substitutePlaceholders } from './placeholderSubstitutor.js'; // Value import
import type { SubstitutionResult } from './placeholderSubstitutor.js'; // Type import
import { z } from 'zod';

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
const axQueryExecutor = new AXQueryExecutor();

// Define raw shapes for tool registration (required by newer SDK versions)
const ExecuteScriptInputShape = {
  script_content: z.string().optional(),
  script_path: z.string().optional(),
  kb_script_id: z.string().optional(),
  language: z.enum(['applescript', 'javascript']).optional(),
  arguments: z.array(z.string()).optional(),
  input_data: z.record(z.any()).optional(),
  timeout_seconds: z.number().optional(),
  include_executed_script_in_output: z.boolean().optional(),
  include_substitution_logs: z.boolean().optional(),
  report_execution_time: z.boolean().optional(),
  output_format_mode: z.enum(['auto', 'human_readable', 'structured_error', 'structured_output_and_error', 'direct']).optional(),
} as const;

const GetScriptingTipsInputShape = {
  category: z.string().optional(),
  search_term: z.string().optional(),
  list_categories: z.boolean().optional(),
  refresh_database: z.boolean().optional(),
  limit: z.number().int().positive().optional(),
} as const;

const AXQueryInputShape = {
  command: z.enum(['query', 'perform']),
  // Top-level fields for lenient parsing
  app: z.string().optional(),
  role: z.string().optional(),
  match: z.record(z.string()).optional(),

  locator: z.union([
      z.object({
          app: z.string(),
          role: z.string(),
          match: z.record(z.string()),
          navigation_path_hint: z.array(z.string()).optional(),
      }),
      z.string()
  ]),
  return_all_matches: z.boolean().optional(),
  attributes_to_query: z.array(z.string()).optional(),
  required_action_name: z.string().optional(),
  action_to_perform: z.string().optional(),
  report_execution_time: z.boolean().optional().default(false),
  limit: z.number().int().positive().optional().default(500),
  debug_logging: z.boolean().optional().default(false),
  output_format: z.enum(['smart', 'verbose', 'text_content']).optional().default('smart'),
} as const;

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
    onLog: (level: "DEBUG" | "INFO" | "WARN" | "ERROR", message: string, data?: Record<string, unknown>) => {
      logger[level.toLowerCase() as 'debug' | 'info' | 'warn' | 'error']?.(`[MCP_SDK] ${message}`, data);
    }
  });

  server.tool(
    'execute_script',
    `Automate macOS tasks using AppleScript or JXA (JavaScript for Automation) to control applications like Terminal, Chrome, Safari, Finder, etc.

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
    ExecuteScriptInputShape,
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
  server.tool(
    'get_scripting_tips',
    `Discover how to automate any app on your Mac with this comprehensive knowledge base of AppleScript/JXA tips and runnable scripts. This tool is essential for discovery and should be the FIRST CHOICE when aiming to automate macOS tasks, especially those involving common applications or system functions, before attempting to write scripts from scratch. It helps identify pre-built, tested solutions, effectively teaching you how to control virtually any aspect of your macOS experience.

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
    GetScriptingTipsInputShape,
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

  // ADD THE NEW accessibility_query TOOL HERE
  server.tool(
    'accessibility_query',
    `Query and interact with the macOS accessibility interface to inspect UI elements of applications. This tool provides a powerful way to explore and manipulate the user interface elements of any application using the native macOS accessibility framework.

This tool exposes the complete macOS accessibility API capabilities, allowing detailed inspection of UI elements and their properties. It's particularly useful for automating interactions with applications that don't have robust AppleScript support or when you need to inspect the UI structure in detail.

**Input Parameters:**

*   \`command\` (enum: 'query' | 'perform', required): The operation to perform.
    *   \`query\`: Retrieves information about UI elements.
    *   \`perform\`: Executes an action on a UI element (like clicking a button).

*   \`locator\` (object, required): Specifications to find the target element(s).
    *   \`app\` (string, required): The application to target, specified by either bundle ID or display name (e.g., "Safari", "com.apple.Safari").
    *   \`role\` (string, required): The accessibility role of the target element (e.g., "AXButton", "AXStaticText").
    *   \`match\` (object, required): Key-value pairs of attributes to match. Can be empty (\`{}\`) if not needed.
    *   \`navigation_path_hint\` (array of strings, optional): Path to navigate within the application hierarchy (e.g., \`["window[1]", "toolbar[1]"]\`).

*   \`return_all_matches\` (boolean, optional): When \`true\`, returns all matching elements rather than just the first match. Default is \`false\`.

*   \`attributes_to_query\` (array of strings, optional): Specific attributes to query for matched elements. If not provided, common attributes will be included. Examples: \`["AXRole", "AXTitle", "AXValue"]\`

*   \`required_action_name\` (string, optional): Filter elements to only those supporting a specific action (e.g., "AXPress" for clickable elements).

*   \`action_to_perform\` (string, optional, required when \`command="perform"\`): The accessibility action to perform on the matched element (e.g., "AXPress" to click a button).

*   \`report_execution_time\` (boolean, optional): If true, the tool will return an additional message containing the formatted script execution time. Defaults to false.

*   \`limit\` (integer, optional): Maximum number of lines to return in the output. Defaults to 500. Output will be truncated if it exceeds this limit.

*   \`max_elements\` (integer, optional): For \`return_all_matches: true\` queries, this specifies the maximum number of UI elements the \`ax\` binary will fully process and return attributes for. If omitted, an internal default (e.g., 200) is used. This helps manage performance when querying UIs with a very large number of matching elements (like numerous text fields on a complex web page). This is different from \`limit\`, which truncates the final text output based on lines.

*   \`debug_logging\` (boolean, optional): If true, enables detailed debug logging from the underlying \`ax\` binary. This diagnostic information will be included in the response, which can be helpful for troubleshooting complex queries or unexpected behavior. Defaults to false.

*   \`output_format\` (enum: 'smart' | 'verbose' | 'text_content', optional, default: 'smart'): Controls the format and verbosity of the attribute output from the \`ax\` binary.
    *   \`'smart'\`: (Default) Optimized for readability. Omits attributes with empty or placeholder values. Returns key-value pairs.
    *   \`'verbose'\`: Maximum detail. Includes all attributes, even empty/placeholders. Key-value pairs. Best for debugging element properties.
    *   \`'text_content'\`: Highly compact for text extraction. Returns only concatenated text values of common textual attributes (e.g., AXValue, AXTitle). No keys are returned. Ideal for quickly getting all text from elements; the \`attributes_to_query\` parameter is ignored in this mode.

**Example Queries (Note: key names have changed to snake_case):**

1.  **Find all text elements in the front Safari window:**
    \`\`\`json
    {
      "command": "query",
      "return_all_matches": true,
      "locator": {
        "app": "Safari",
        "role": "AXStaticText",
        "match": {},
        "navigation_path_hint": ["window[1]"]
      }
    }
    \`\`\`

2.  **Find and click a button with a specific title:**
    \`\`\`json
    {
      "command": "perform",
      "locator": {
        "app": "System Settings",
        "role": "AXButton",
        "match": {"AXTitle": "General"}
      },
      "action_to_perform": "AXPress"
    }
    \`\`\`

3.  **Get detailed information about the focused UI element:**
    \`\`\`json
    {
      "command": "query",
      "locator": {
        "app": "Mail",
        "role": "AXTextField",
        "match": {"AXFocused": "true"}
      },
      "attributes_to_query": ["AXRole", "AXTitle", "AXValue", "AXDescription", "AXHelp", "AXPosition", "AXSize"]
    }
    \`\`\`

**Note:** Using this tool requires that the application running this server has the necessary Accessibility permissions in macOS System Settings > Privacy & Security > Accessibility.`,
    AXQueryInputShape,
    async (args: unknown) => {
      let inputFromZod: AXQueryInput; 
      try {
        inputFromZod = AXQueryInputSchema.parse(args);
        logger.info('accessibility_query called with raw Zod-parsed input:', inputFromZod);

        // Normalize the input to the canonical structure AXQueryExecutor expects
        let canonicalInput: AXQueryInput;

        if (typeof inputFromZod.locator === 'string') {
            logger.debug('Normalizing malformed input (locator is string). Top-level data:', { appLocatorString: inputFromZod.locator, role: inputFromZod.role, match: inputFromZod.match });
            // Zod superRefine should have already ensured inputFromZod.role is defined.
            // The top-level inputFromZod.app is ignored here because inputFromZod.locator (the string) is the app.
            canonicalInput = {
                // Spread all other fields from inputFromZod first
                ...inputFromZod,
                // Then explicitly define the locator object
                locator: {
                    app: inputFromZod.locator, // The string locator is the app name
                    role: inputFromZod.role!,   // Role from top level (assert non-null due to Zod refine)
                    match: inputFromZod.match || {}, // Match from top level, or default to empty
                    navigation_path_hint: undefined // No path hint in this malformed case typically
                },
                // Nullify the top-level fields that are now part of the canonical locator
                // to avoid confusion if they were passed, though AXQueryExecutor won't use them.
                app: undefined,
                role: undefined,
                match: undefined
            };
        } else {
            // Well-formed case: locator is an object. Zod superRefine ensures top-level app/role/match are undefined.
            logger.debug('Input is well-formed (locator is object).');
            canonicalInput = inputFromZod;
        }

        // logger.info('accessibility_query using canonical input for executor:', JSON.parse(JSON.stringify(canonicalInput))); // Commented out due to persistent linter issue
        
        const result = await axQueryExecutor.execute(canonicalInput);
        
        // For cleaner output, especially for multi-element queries, format the response
        let formattedOutput: string;
        
        if (inputFromZod.command === 'query' && inputFromZod.return_all_matches === true) {
          // For multi-element queries, format the results more readably
          if ('elements' in result) {
            formattedOutput = JSON.stringify(result, null, 2);
          } else {
            formattedOutput = JSON.stringify(result, null, 2);
          }
        } else {
          // For single element queries or perform actions
          formattedOutput = JSON.stringify(result, null, 2);
        }
        
        // Apply line limit
        let finalOutputText = formattedOutput;
        const lines = finalOutputText.split('\n');
        if (inputFromZod.limit !== undefined && lines.length > inputFromZod.limit) {
          finalOutputText = lines.slice(0, inputFromZod.limit).join('\n');
          const truncationNotice = `\n\n--- Output truncated to ${inputFromZod.limit} lines. Original length was ${lines.length} lines. ---`;
          finalOutputText += truncationNotice;
        }

        const responseContent: Array<{ type: 'text'; text: string }> = [{ type: 'text', text: finalOutputText }];

        // Add debug logs if they exist in the result
        if (result.debug_logs && Array.isArray(result.debug_logs) && result.debug_logs.length > 0) {
          const debugHeader = "\n\n--- AX Binary Debug Logs ---";
          const logsString = result.debug_logs.join('\n');
          responseContent.push({ type: 'text', text: `${debugHeader}\n${logsString}` });
        }

        if (inputFromZod.report_execution_time) {
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
          responseContent.push({ type: 'text', text: `${timeMessage}` });
        }

        return { content: responseContent };
      } catch (error: unknown) {
        const err = error as Error;
        logger.error('Error in accessibility_query tool handler', { message: err.message });
        // If the error object from AXQueryExecutor contains debug_logs, include them
        let errorMessage = `Failed to execute accessibility query: ${err.message}`;
        const errorWithLogs = err as (Error & { debug_logs?: string[] }); // Cast here
        if (errorWithLogs.debug_logs && Array.isArray(errorWithLogs.debug_logs) && errorWithLogs.debug_logs.length > 0) {
          const debugHeader = "\n\n--- AX Binary Debug Logs (from error) ---";
          const logsString = errorWithLogs.debug_logs.join('\n');
          errorMessage += `\n${debugHeader}\n${logsString}`;
        }
        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, errorMessage);
      }
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