import * as sdkTypes from "@modelcontextprotocol/sdk/types.js";
import { ExecuteScriptInputSchema, type ExecuteScriptInput } from "./schemas.js";
import { ScriptExecutor } from "./ScriptExecutor.js";
import { Logger } from "./logger.js";
import { getKnowledgeBase } from "./services/KnowledgeBaseManager.js";
import { substitutePlaceholders } from "./placeholderSubstitutor.js";
import type { ScriptExecutionError, ExecuteScriptResponse } from "./types.js";

const logger = new Logger("macos_automator_server");
const scriptExecutor = new ScriptExecutor();

function formatDuration(seconds: number): string {
  const ms = seconds * 1000;
  if (ms < 1) return "<1 millisecond.";
  if (ms < 1000) return `${ms.toFixed(0)} milliseconds.`;
  if (ms < 60000) return `${(ms / 1000).toFixed(2)} seconds.`;
  const totalSeconds = Math.round(seconds);
  return `${Math.floor(totalSeconds / 60)} minute(s) and ${totalSeconds % 60} seconds.`;
}

interface ResolvedScript {
  source: { content: string } | { path: string };
  language: "applescript" | "javascript";
  arguments: string[];
  substitutionLogs: string[];
}

async function resolveScript(input: ExecuteScriptInput): Promise<ResolvedScript> {
  if (input.kb_script_id) {
    const kb = await getKnowledgeBase();
    const tip = kb.tips.find((tip) => tip.id === input.kb_script_id);
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
    const options = {
      scriptContent: tip.script,
      language: tip.language,
      inputData: input.input_data,
      args: input.arguments,
      includeSubstitutionLogs: input.include_substitution_logs,
    };
    const substitution = substitutePlaceholders(options);
    return {
      source: { content: substitution.substitutedScript },
      language: tip.language,
      arguments: [],
      substitutionLogs: substitution.logs,
    };
  }
  // The schema guarantees one nonempty source; empty optional fields cannot shadow it.
  const source = input.script_path
    ? { path: input.script_path }
    : { content: input.script_content! };
  return {
    source,
    language: input.language ?? "applescript",
    arguments: input.arguments ?? [],
    substitutionLogs: [],
  };
}

export async function executeScript(
  args: unknown,
  takeServerInfo: () => string | undefined,
): Promise<ExecuteScriptResponse> {
  const input = ExecuteScriptInputSchema.parse(args);
  logger.debug("execute_script called with input:", input);
  const {
    source,
    language,
    arguments: scriptArguments,
    substitutionLogs,
  } = await resolveScript(input);
  const sourceKind = "content" in source ? "Content" : "Path";
  const sourceText = "content" in source ? source.content : source.path;
  const mainOutputContent: { type: "text"; text: string }[] = [];

  try {
    const result = await scriptExecutor.execute(source, {
      language,
      timeoutMs: input.timeout_seconds * 1000,
      output_format_mode: input.output_format_mode,
      arguments: scriptArguments,
    });

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
      mainOutputContent.push({
        type: "text",
        text: `\n--- Executed Script ${sourceKind} ---\n${sourceText}`,
      });
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
        `Script execution timed out after ${input.timeout_seconds} seconds.`,
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

    finalErrorMessage += `\n\n--- Script Attempted (${sourceKind}) ---\n${sourceText}`;

    if (input.include_substitution_logs && substitutionLogs.length > 0) {
      finalErrorMessage += `\n\n--- Substitution Logs ---\n${substitutionLogs.join("\n")}`;
    }

    logger.error("execute_script handler error", {
      execution_time_seconds: execError.execution_time_seconds,
    });

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
