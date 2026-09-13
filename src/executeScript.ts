import * as sdkTypes from "@modelcontextprotocol/sdk/types.js";
import { ExecuteScriptInputSchema } from "./schemas.js";
import { ScriptExecutor } from "./ScriptExecutor.js";
import { Logger } from "./logger.js";
import { getKnowledgeBase } from "./services/KnowledgeBaseManager.js";
import { substitutePlaceholders } from "./placeholderSubstitutor.js";
import type { SubstitutionResult } from "./placeholderSubstitutor.js";
import type { ScriptExecutionError, ExecuteScriptResponse } from "./types.js";

const logger = new Logger("macos_automator_server");
const scriptExecutor = new ScriptExecutor();

function formatDuration(seconds: number): string {
  const ms = seconds * 1000;
  if (ms < 1) return "<1 millisecond.";
  if (ms < 1000) return `${ms.toFixed(0)} milliseconds.`;
  if (ms < 60000) return `${(ms / 1000).toFixed(2)} seconds.`;
  const totalSeconds = ms / 1000;
  return `${Math.floor(totalSeconds / 60)} minute(s) and ${Math.round(totalSeconds % 60)} seconds.`;
}

export async function executeScript(
  args: unknown,
  takeServerInfo: () => string | undefined,
): Promise<ExecuteScriptResponse> {
  const input = ExecuteScriptInputSchema.parse(args);
  let execution_time_seconds: number | undefined;
  let scriptContentToExecute: string | undefined = input.script_content;
  let scriptPathToExecute: string | undefined = input.script_path;
  let languageToUse: "applescript" | "javascript";
  let finalArgumentsForScriptFile = input.arguments || [];
  let substitutionLogs: string[] = [];

  logger.debug("execute_script called with input:", input);

  const mainOutputContent: { type: "text"; text: string }[] = [];

  if (input.kb_script_id) {
    const kb = await getKnowledgeBase();
    const tip = kb.tips.find((t: { id: string }) => t.id === input.kb_script_id);

    if (!tip) {
      throw new sdkTypes.McpError(
        sdkTypes.ErrorCode.InvalidParams,
        `Knowledge base script with ID '${input.kb_script_id}' not found.`,
      );
    }
    if (!tip.script) {
      throw new sdkTypes.McpError(
        sdkTypes.ErrorCode.InternalError,
        `Knowledge base script ID '${input.kb_script_id}' has no script content.`,
      );
    }

    languageToUse = tip.language;
    scriptPathToExecute = undefined;
    finalArgumentsForScriptFile = [];

    const substitutionResult: SubstitutionResult = substitutePlaceholders({
      scriptContent: tip.script,
      inputData: input.input_data,
      args: input.arguments,
      includeSubstitutionLogs: input.include_substitution_logs || false,
    });

    scriptContentToExecute = substitutionResult.substitutedScript;
    substitutionLogs = substitutionResult.logs;
    logger.info("Executing Knowledge Base script", {
      id: tip.id,
      finalLength: scriptContentToExecute?.length,
    });
  } else if (input.script_path || input.script_content) {
    languageToUse = input.language || "applescript";
    if (input.script_path) {
      logger.debug("Executing script from path", {
        scriptPath: input.script_path,
        language: languageToUse,
      });
    } else if (input.script_content) {
      logger.debug("Executing script from content", {
        language: languageToUse,
        initialLength: input.script_content.length,
      });
    }
  } else {
    throw new sdkTypes.McpError(
      sdkTypes.ErrorCode.InvalidParams,
      "No script source provided (content, path, or KB ID).",
    );
  }

  if (scriptContentToExecute) {
    logger.debug("Final script content to be executed:", {
      language: languageToUse,
      script: scriptContentToExecute,
    });
  } else if (scriptPathToExecute) {
    logger.debug("Executing script via path (content not logged here):", {
      scriptPath: scriptPathToExecute,
      language: languageToUse,
    });
  }

  try {
    const result = await scriptExecutor.execute(
      { content: scriptContentToExecute, path: scriptPathToExecute },
      {
        language: languageToUse,
        timeoutMs: (input.timeout_seconds || 60) * 1000,
        output_format_mode: input.output_format_mode || "auto",
        arguments: scriptPathToExecute ? finalArgumentsForScriptFile : [],
      },
    );
    execution_time_seconds = result.execution_time_seconds;

    if (result.stderr) {
      logger.warn("Script execution produced stderr (even on success)", {
        stderr: result.stderr,
      });
    }

    const isError = /^\s*error[:\s-]/i.test(result.stdout);

    if (input.include_substitution_logs && substitutionLogs.length > 0) {
      const logsHeader = "\n--- Substitution Logs ---\n";
      const logsString = substitutionLogs.join("\n");
      mainOutputContent.push({
        type: "text",
        text: `${logsHeader}${logsString}\n\n--- Original STDOUT ---\n${result.stdout}`,
      });
    }

    mainOutputContent.push({ type: "text", text: result.stdout });

    if (input.include_executed_script_in_output) {
      let scriptIdentifier = "Script source not determined (should not happen).";
      if (scriptContentToExecute) {
        scriptIdentifier = `\n--- Executed Script Content ---\n${scriptContentToExecute}`;
      } else if (scriptPathToExecute) {
        scriptIdentifier = `\n--- Executed Script Path ---\n${scriptPathToExecute}`;
      }
      mainOutputContent.push({ type: "text", text: scriptIdentifier });
    }

    const finalResponseContent = mainOutputContent;

    const serverInfo = takeServerInfo();
    if (serverInfo) finalResponseContent.push({ type: "text", text: serverInfo });

    const response: ExecuteScriptResponse = {
      content: finalResponseContent,
      isError,
    };

    if (input.report_execution_time) {
      response.content.push({
        type: "text",
        text: `Script executed in ${formatDuration(result.execution_time_seconds)}`,
      });
    }

    return response;
  } catch (error: unknown) {
    const execError = error as ScriptExecutionError;
    execution_time_seconds = execError.execution_time_seconds;

    let baseErrorMessage = "Script execution failed. ";

    if (execError.name === "UnsupportedPlatformError") {
      throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidRequest, execError.message);
    }
    if (execError.name === "ScriptFileAccessError") {
      throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, execError.message);
    }
    if (execError.isTimeout) {
      throw new sdkTypes.McpError(
        sdkTypes.ErrorCode.RequestTimeout,
        `Script execution timed out after ${input.timeout_seconds || 60} seconds.`,
      );
    }

    baseErrorMessage += execError.stderr?.trim()
      ? `Details: ${execError.stderr.trim()}`
      : execError.message || "No specific error message from script.";

    let finalErrorMessage = baseErrorMessage;
    const permissionErrorPattern =
      /Not authorized|access for assistive devices is disabled|errAEEventNotPermitted|errAEAccessDenied|-1743|-10004/i;
    const likelyPermissionError = execError.stderr && permissionErrorPattern.test(execError.stderr);
    const possibleSilentPermissionError = execError.exitCode === 1 && !execError.stderr?.trim();

    if (likelyPermissionError || possibleSilentPermissionError) {
      finalErrorMessage = `${baseErrorMessage}\n\nPOSSIBLE PERMISSION ISSUE: Ensure the application running this server (e.g., Terminal, Node) has required permissions in 'System Settings > Privacy & Security > Automation' and 'Accessibility'. See README.md. The target application for the script may also need specific permissions.`;
    }

    let scriptIdentifierForError = "Script source not determined (should not happen).";
    if (scriptContentToExecute) {
      scriptIdentifierForError = `\n\n--- Script Attempted (Content) ---\n${scriptContentToExecute}`;
    } else if (scriptPathToExecute) {
      scriptIdentifierForError = `\n\n--- Script Attempted (Path) ---\n${scriptPathToExecute}`;
    }
    finalErrorMessage += scriptIdentifierForError;

    if (input.include_substitution_logs && substitutionLogs.length > 0) {
      finalErrorMessage += `\n\n--- Substitution Logs ---\n${substitutionLogs.join("\n")}`;
    }

    logger.error("execute_script handler error", { execution_time_seconds });

    const errorOutputParts: string[] = [finalErrorMessage];
    const serverInfo = takeServerInfo();
    if (serverInfo) errorOutputParts.push(serverInfo);

    const errorResponse: ExecuteScriptResponse = {
      content: [{ type: "text", text: errorOutputParts.join("\n\n") }],
      isError: true,
    };

    if (input.report_execution_time && execError.execution_time_seconds !== undefined) {
      errorResponse.content.push({
        type: "text",
        text: `\nScript execution failed after ${formatDuration(execError.execution_time_seconds)}`,
      });
    }

    return errorResponse;
  }
}
