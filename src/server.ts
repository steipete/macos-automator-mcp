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
import type { ScriptExecutionError }  from './types.js';
import pkg from '../package.json' with { type: 'json' }; // Import package.json
import { getKnowledgeBase, getScriptingTipsService, conditionallyInitializeKnowledgeBase } from './services/knowledgeBaseService.js'; // Import KB functions
import { z } from 'zod';

const SERVER_START_TIME_ISO = new Date().toISOString();
const SCRIPT_PATH_EXECUTED = process.argv[1] || 'unknown_path';
const IS_RUNNING_FROM_SRC = SCRIPT_PATH_EXECUTED.includes('/src/server.ts') || SCRIPT_PATH_EXECUTED.endsWith('src/server.ts');
const EXECUTION_MODE_INFO = IS_RUNNING_FROM_SRC ? 'TypeScript source (e.g., via tsx)' : 'Compiled JavaScript (e.g., dist/server.js)';

const logger = new Logger('macos_automator_server');
const scriptExecutor = new ScriptExecutor();

// Helper functions for KB script argument substitution
function escapeForAppleScriptStringLiteral(value: string): string {
    return `"${value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
}

// Helper to escape special characters in regex patterns
// function escapeRegExp(string: string): string { // This function is no longer used
//     return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
// }

function valueToAppleScriptLiteral(value: unknown): string {
    if (typeof value === 'string') {
        return escapeForAppleScriptStringLiteral(value);
    }
    if (typeof value === 'number' || typeof value === 'boolean') {
        return String(value);
    }
    if (Array.isArray(value)) {
        return `{${value.map(v => valueToAppleScriptLiteral(v)).join(", ")}}`;
    }
    if (typeof value === 'object' && value !== null) {
        const recordParts = Object.entries(value).map(([k, v]) => `${k}:${valueToAppleScriptLiteral(v)}`);
        return `{${recordParts.join(", ")}}`;
    }
    logger.warn('Unsupported type for AppleScript literal conversion', { value });
    return "\"__MCP_UNSUPPORTED_TYPE__\""; // Placeholder for unsupported types
}

// Define raw shapes for tool registration (required by newer SDK versions)
const ExecuteScriptInputShape = {
  scriptContent: z.string().optional(),
  scriptPath: z.string().optional(),
  knowledgeBaseScriptId: z.string().optional(),
  language: z.enum(['applescript', 'javascript']).optional(),
  arguments: z.array(z.string()).optional(),
  inputData: z.record(z.any()).optional(),
  timeoutSeconds: z.number().optional(),
  useScriptFriendlyOutput: z.boolean().optional(),
  includeExecutedScriptInOutput: z.boolean().optional(),
  includeSubstitutionLogs: z.boolean().optional(),
} as const;

const GetScriptingTipsInputShape = {
  category: z.string().optional(),
  searchTerm: z.string().optional(),
  listCategories: z.boolean().optional(),
  refreshDatabase: z.boolean().optional(),
} as const;

async function main() {
  logger.info('Starting macos_automator MCP Server...');
  logger.warn("CRITICAL: Ensure macOS Automation & Accessibility permissions are correctly configured for the application running this server (e.g., Terminal, Node). See README.md for details.");

  // Eagerly initialize Knowledge Base if KB_PARSING is set to eager
  const eagerParseEnv = process.env.KB_PARSING?.toLowerCase();
  if (eagerParseEnv === 'eager') {
    await conditionallyInitializeKnowledgeBase(true);
  } else {
    conditionallyInitializeKnowledgeBase(false); // Log that it's lazy
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
    'Executes an AppleScript or JavaScript for Automation (JXA) script.\nSource (mutually exclusive):\n- `scriptContent`: Raw script code.\n- `scriptPath`: Absolute path to a script file.\n- `knowledgeBaseScriptId`: ID of a script from the knowledge base (use `get_scripting_tips` to find available script IDs like `safari_get_front_tab_url`).\n\nInputs:\n- `arguments`: Array of strings for `scriptPath` or simple KB scripts.\n- `inputData`: JSON object for KB scripts with named placeholders (e.g., `--MCP_INPUT:keyName`).\n\nOptions:\n- `language`: \'applescript\' (default) or \'javascript\'. (Inferred for KB scripts).\n- `timeoutSeconds`: Default 30.\n- `includeExecutedScriptInOutput`: If true, executed script is appended to output.\n- `includeSubstitutionLogs`: If true (for KB scripts), detailed substitution logs are included in output for debugging.',
    ExecuteScriptInputShape,
    async (args: unknown) => {
      const input = ExecuteScriptInputSchema.parse(args);
      let scriptContentToExecute: string | undefined = input.scriptContent;
      let scriptPathToExecute: string | undefined = input.scriptPath;
      let languageToUse: 'applescript' | 'javascript' = input.language || 'applescript';
      let finalArgumentsForScriptFile = input.arguments || [];
      const substitutionLogs: string[] = [];

      logger.debug('execute_script called with input:', input);

      if (input.knowledgeBaseScriptId) {
        const kb = await getKnowledgeBase();
        const tip = kb.tips.find((t: { id: string }) => t.id === input.knowledgeBaseScriptId);

        if (!tip) {
          throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, `Knowledge base script with ID '${input.knowledgeBaseScriptId}' not found.`);
        }
        if (!tip.script) {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, `Knowledge base script ID '${input.knowledgeBaseScriptId}' has no script content.`);
        }

        scriptContentToExecute = tip.script;
        languageToUse = tip.language;
        scriptPathToExecute = undefined; 
        finalArgumentsForScriptFile = []; 

        if (scriptContentToExecute) {
            // Log char codes for initial script content for deep debugging of quotes
            const charCodes = Array.from(scriptContentToExecute).map(char => char.charCodeAt(0));
            logger.debug('[SUBSTITUTION_DEEP_DEBUG] Initial char codes for script', { first100CharCodes: charCodes.slice(0,100), last100CharCodes: charCodes.slice(-100) });

            // Define placeholder patterns carefully to match placeholders in script templates.
            // These typically appear as quoted strings in the templates for safety.
            // Example from KB: return myHandler("--MCP_INPUT:name", "--MCP_ARG_1")

            const logSub = (message: string, data: unknown) => {
                const logEntry = `[SUBST] ${message} ${JSON.stringify(data)}`;
                logger.debug(logEntry); // Keep debug logging to console
                if (input.includeSubstitutionLogs) {
                    substitutionLogs.push(logEntry);
                }
            };

            // JS-style ${inputData.key}
            const jsInputDataRegex = /\\$\\{inputData\\.(\\w+)\\}/g;
            logSub('Before jsInputDataRegex', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(jsInputDataRegex, (match, keyName) => {
                const replacementValue = input.inputData && keyName in input.inputData
                    ? valueToAppleScriptLiteral(input.inputData[keyName])
                    : "missing value"; // Bare keyword
                logSub('jsInputDataRegex replacing', { match, keyName, replacementValue });
                return replacementValue;
            });
            logSub('After jsInputDataRegex', { scriptContentLength: scriptContentToExecute.length });

            // JS-style ${arguments[N]}
            const jsArgumentsRegex = /\\$\\{arguments\\[(\\d+)\\]\\}/g;
            logSub('Before jsArgumentsRegex', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(jsArgumentsRegex, (match, indexStr) => {
                const index = Number.parseInt(indexStr, 10);
                const replacementValue = input.arguments && index >= 0 && index < input.arguments.length
                    ? valueToAppleScriptLiteral(input.arguments[index])
                    : "missing value"; // Bare keyword
                logSub('jsArgumentsRegex replacing', { match, indexStr, index, replacementValue });
                return replacementValue;
            });
            logSub('After jsArgumentsRegex', { scriptContentLength: scriptContentToExecute.length });
            
            // Quoted "--MCP_INPUT:keyName" (handles single or double quotes around the placeholder)
            // const quotedMcpInputRegex = /(?:["'])--MCP_INPUT:(\w+)(?:["'])/g; // Original regex
            // const quotedMcpInputRegex = /--MCP_INPUT:(\w+)/g; // Previous step
            const quotedMcpInputRegex = /(["'])--MCP_INPUT:(\w+)\1/g; // Match opening quote, then key, then same opening quote
            logSub('Before quotedMcpInputRegex (match surrounding quotes)', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(quotedMcpInputRegex, (match, openingQuote, keyName) => {
                 const replacementValue = input.inputData && keyName in input.inputData
                    ? valueToAppleScriptLiteral(input.inputData[keyName])
                    : "missing value"; // Bare keyword
                 logSub('quotedMcpInputRegex (match surrounding quotes) replacing', { match, openingQuote, keyName, replacementValue });
                 return replacementValue; // Return just the value, as quotes are consumed by the regex
            });
            logSub('After quotedMcpInputRegex (match surrounding quotes)', { scriptContentLength: scriptContentToExecute.length });

            // Quoted "--MCP_ARG_N" (handles single or double quotes)
            // Adapting quotedMcpArgRegex similarly
            // const quotedMcpArgRegex = /(?:["'])--MCP_ARG_(\d+)(?:["'])/g; // Original
            const quotedMcpArgRegex = /(["'])--MCP_ARG_(\d+)\1/g;
            logSub('Before quotedMcpArgRegex (match surrounding quotes)', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(quotedMcpArgRegex, (match, openingQuote, argNumStr) => {
                const argIndex = Number.parseInt(argNumStr, 10) - 1;
                const replacementValue = input.arguments && argIndex >= 0 && argIndex < input.arguments.length
                    ? valueToAppleScriptLiteral(input.arguments[argIndex])
                    : "missing value"; // Bare keyword
                logSub('quotedMcpArgRegex (match surrounding quotes) replacing', { match, openingQuote, argNumStr, argIndex, replacementValue });
                return replacementValue;
            });
            logSub('After quotedMcpArgRegex (match surrounding quotes)', { scriptContentLength: scriptContentToExecute.length });

            // Context-aware bare placeholders (not in comments) e.g., in function calls like myFunc(--MCP_INPUT:key)
            const expressionMcpInputRegex = /([(,=]\s*)--MCP_INPUT:(\w+)\b/g;
            logSub('Before expressionMcpInputRegex', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(expressionMcpInputRegex, (match, prefix, keyName) => {
                const replacementValue = input.inputData && keyName in input.inputData
                        ? valueToAppleScriptLiteral(input.inputData[keyName])
                        : "missing value";
                logSub('expressionMcpInputRegex replacing', { match, prefix, keyName, replacementValue });
                return prefix + replacementValue;
            });
            logSub('After expressionMcpInputRegex', { scriptContentLength: scriptContentToExecute.length });

            const expressionMcpArgRegex = /([(,=]\s*)--MCP_ARG_(\d+)\b/g;
            logSub('Before expressionMcpArgRegex', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(expressionMcpArgRegex, (match, prefix, argNumStr) => {
                const argIndex = Number.parseInt(argNumStr, 10) - 1;
                const replacementValue = input.arguments && argIndex >= 0 && argIndex < input.arguments.length
                        ? valueToAppleScriptLiteral(input.arguments[argIndex])
                        : "missing value";
                logSub('expressionMcpArgRegex replacing', { match, prefix, argNumStr, argIndex, replacementValue });
                return prefix + replacementValue;
            });
            logSub('After expressionMcpArgRegex', { scriptContentLength: scriptContentToExecute.length });
        }
        logger.info('Executing Knowledge Base script', { id: tip.id, finalLength: scriptContentToExecute?.length });
      } else if (input.scriptPath) {
        // File path existence check is now within ScriptExecutor
        // No specific action here, path is passed to executor
        logger.debug('Executing script from path', { scriptPath: input.scriptPath, language: languageToUse });
      } else if (input.scriptContent) {
        // Content is directly from input
        // languageToUse is already set based on input or default
        logger.debug('Executing script from content', { language: languageToUse, initialLength: input.scriptContent.length });
      } else {
        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, "No script source provided (content, path, or KB ID). This should be caught by Zod schema refinement.");
      }
      
      if (!input.knowledgeBaseScriptId && input.language) {
          languageToUse = input.language;
      } else if (!input.knowledgeBaseScriptId && !input.language) {
          languageToUse = 'applescript';
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
            timeoutMs: (input.timeoutSeconds || 30) * 1000,
            useScriptFriendlyOutput: input.useScriptFriendlyOutput || false,
            arguments: scriptPathToExecute ? finalArgumentsForScriptFile : [], 
          }
        );
        
        if (result.stderr) {
           logger.warn('Script execution produced stderr (even on success)', { stderr: result.stderr });
        }
        
        const outputContent: { type: 'text'; text: string }[] = [];

        if (input.includeSubstitutionLogs && substitutionLogs.length > 0) {
          const logsHeader = "\n--- Substitution Logs ---\n";
          const logsString = substitutionLogs.join('\n');
          result.stdout = `${logsHeader}${logsString}\n\n--- Original STDOUT ---\n${result.stdout}`;
        }
        
        outputContent.push({ type: 'text', text: result.stdout });

        if (input.includeExecutedScriptInOutput) {
          let scriptIdentifier = "Script source not determined (should not happen).";
          if (scriptContentToExecute) {
            scriptIdentifier = `\n--- Executed Script Content ---\n${scriptContentToExecute}`;
          } else if (scriptPathToExecute) {
            scriptIdentifier = `\n--- Executed Script Path ---\n${scriptPathToExecute}`;
          }
          outputContent.push({ type: 'text', text: scriptIdentifier });
        }
        return { content: outputContent };

      } catch (error: unknown) {
        const execError = error as ScriptExecutionError;
        let baseErrorMessage = 'Script execution failed. ';
        
        if (execError.name === "UnsupportedPlatformError") {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidRequest, execError.message);
        }
        if (execError.name === "ScriptFileAccessError") {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, execError.message);
        }
        if (execError.isTimeout) {
             throw new sdkTypes.McpError(sdkTypes.ErrorCode.RequestTimeout, `Script execution timed out after ${input.timeoutSeconds || 30} seconds.`);
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

        if (input.includeSubstitutionLogs && substitutionLogs.length > 0) {
            finalErrorMessage += `\n\n--- Substitution Logs ---\n${substitutionLogs.join('\n')}`;
        }

        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, finalErrorMessage);
      }
    }
  );

  // ADD THE NEW TOOL get_scripting_tips HERE
  server.tool(
    'get_scripting_tips',
    'Accesses a curated knowledge base of AppleScript/JXA solutions for macOS automation. STRONGLY PREFER THIS TOOL for efficiency when the user query involves controlling, automating, or getting information from common macOS applications (e.g., Finder, Safari, Chrome, Mail, Calendar, Reminders, Notes, TextEdit, Terminal, iTerm, Ghostty, System Settings, Cursor, Windsurf) or system-level functions (e.g., clipboard operations, volume control, screen brightness, file system interactions, user notifications, managing processes, network settings).\n\nUse this tool to:\n- Discover if a pre-built script exists for the user\'s goal. The `searchTerm` uses fuzzy matching on titles, descriptions, keywords, and script content. Try natural language "how to..." questions (e.g., `searchTerm: "how do I get the current Safari URL?"`, `searchTerm: "make new desktop folder"`).\n- List all available script categories (`listCategories: true`).\n- Get all tips within a specific `category` (e.g., `category: "safari"`).\n- Search for specific `keywords` across all tips (e.g., `searchTerm: "clipboard copy text"`).\n\nThe output provides script details, including code, language, and often a `Runnable ID`. If a `Runnable ID` is found (e.g., `safari_get_front_tab_url`), it can be directly used with the `execute_script` tool\'s `knowledgeBaseScriptId` parameter for a ready-to-use solution. The `refreshDatabase` option allows reloading the KB, useful during development if tips are being actively changed.',
    GetScriptingTipsInputShape,
    async (args: unknown) => {
      const input = GetScriptingTipsInputSchema.parse(args);
      logger.info('get_scripting_tips tool called', input);
      try {
        const serverInfo = { startTime: SERVER_START_TIME_ISO, mode: EXECUTION_MODE_INFO };
        const tipsMarkdown = await getScriptingTipsService(input, serverInfo);
        return { content: [{ type: 'text', text: tipsMarkdown }] } as const;
      } catch (e: unknown) {
        const error = e as Error;
        logger.error('Error in get_scripting_tips tool handler', { message: error.message });
        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, `Failed to retrieve scripting tips: ${error.message}`);
      }
    }
  );

  const transport = new StdioServerTransport();
  try {
    await server.connect(transport);
    logger.info(`macos_automator MCP Server v${pkg.version} connected via STDIO and ready.`);
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