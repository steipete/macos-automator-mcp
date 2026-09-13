export type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR";

export interface ScriptExecutionOptions {
  language?: "applescript" | "javascript";
  timeoutMs?: number;
  output_format_mode?:
    | "auto"
    | "human_readable"
    | "structured_error"
    | "structured_output_and_error"
    | "direct";
  arguments?: string[]; // Passed to the script's run handler
}

export interface ScriptExecutionResult {
  stdout: string;
  stderr: string; // To capture warnings even on success
  execution_time_seconds: number;
}

// Error structure returned by ScriptExecutor on failure
export interface ScriptExecutionError extends Error {
  stdout?: string;
  stderr?: string;
  exitCode?: number | string | null; // Allow string for error codes like 'ENOENT'
  signal?: string | null;
  killed?: boolean; // Specifically for timeouts
  originalError?: unknown; // The raw error from child_process
  isTimeout?: boolean;
  execution_time_seconds?: number;
}

export interface ExecuteScriptResponse {
  content: Array<{
    type: "text";
    text: string;
  }>;
  isError?: boolean;
  [key: string]: unknown; // Required by MCP SDK for tool responses
}
