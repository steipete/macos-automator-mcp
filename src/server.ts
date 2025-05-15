#!/usr/bin/env node
// server.ts - MCP server entrypoint
// NOTE: SDK ESM/CJS hybrid: imports work at runtime, but types are mapped via tsconfig.json "paths". Suppress TS errors for imports.
// TODO: Replace 'unknown' with proper input types if/when SDK types are available.

// @ts-expect-error: SDK types are mapped via tsconfig.json paths
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
// @ts-expect-error: SDK types are mapped via tsconfig.json paths
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
// @ts-expect-error: SDK types are mapped via tsconfig.json paths
import * as sdkTypes from '@modelcontextprotocol/sdk/types.js';
// import { ZodError } from 'zod'; // ZodError is not directly used from here, handled by SDK or refined errors
import { Logger } from './logger.js';
import { ExecuteScriptInputSchema, GetScriptingTipsInputSchema } from './schemas.js';
import { ScriptExecutor } from './ScriptExecutor.js';
import type { ScriptExecutionError }  from './types.js';
import pkg from '../package.json' with { type: 'json' }; // Import package.json
import { getKnowledgeBase, getScriptingTipsService, conditionallyInitializeKnowledgeBase } from './services/knowledgeBaseService.js'; // Import KB functions
import { z } from 'zod';

const logger = new Logger('macos_automator_server');
const scriptExecutor = new ScriptExecutor();

// Helper function for KB script argument substitution
function escapeForAppleScriptStringLiteral(value: string): string {
    return `"${value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
}

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
    'Executes an AppleScript or JavaScript for Automation (JXA) script. ' +
    'Can use inline content, a file path, or a script from the knowledge base via knowledgeBaseScriptId. ' +
    'Use get_scripting_tips to discover available knowledge base scripts and their IDs. ' +
    'Input arguments can be passed via "arguments" (for files or simple KB scripts) or "inputData" (for KB scripts expecting named inputs).',
    ExecuteScriptInputShape,
    async (args: unknown) => {
      const input = ExecuteScriptInputSchema.parse(args);
      let scriptContentToExecute: string | undefined = input.scriptContent;
      let scriptPathToExecute: string | undefined = input.scriptPath;
      let languageToUse: 'applescript' | 'javascript' = input.language || 'applescript';
      let finalArgumentsForScriptFile = input.arguments || [];

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
            if (input.inputData) {
              for (const key in input.inputData) {
                // eslint-disable-next-line no-useless-escape
                const placeholder = new RegExp(`(?:\$\{inputData\.${key}\}|--MCP_INPUT:${key}\b)`, 'g');
                scriptContentToExecute = scriptContentToExecute.replace(placeholder, valueToAppleScriptLiteral(input.inputData[key]));
              }
            }
            if (input.arguments && input.arguments.length > 0) {
                for (let i = 0; i < input.arguments.length; i++) {
                    // eslint-disable-next-line no-useless-escape
                    const placeholder = new RegExp(`(?:\$\{arguments\[${i}\]\}|--MCP_ARG_${i+1}\b)`, 'g');
                    scriptContentToExecute = scriptContentToExecute.replace(placeholder, valueToAppleScriptLiteral(input.arguments[i]));
                }
            }
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
        
        const outputContent: { type: 'text'; text: string }[] = [{ type: 'text', text: result.stdout }];

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

        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, finalErrorMessage);
      }
    }
  );

  // ADD THE NEW TOOL get_scripting_tips HERE
  server.tool(
    'get_scripting_tips',
    'Retrieves AppleScript/JXA tips from the knowledge base. Can list categories, get tips by category, or search.',
    GetScriptingTipsInputShape,
    async (args: unknown) => {
      const input = GetScriptingTipsInputSchema.parse(args);
      logger.info('get_scripting_tips tool called', input);
      try {
        const tipsMarkdown = await getScriptingTipsService(input);
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