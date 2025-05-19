// src/types.ts
export type LogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';

export interface ScriptExecutionOptions {
  language?: 'applescript' | 'javascript';
  timeoutMs?: number;
  output_format_mode?: 'auto' | 'human_readable' | 'structured_error' | 'structured_output_and_error' | 'direct';
  arguments?: string[]; // For script files executed via path
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
  execution_time_seconds: number; // Changed from optional to required
}

// MCP Error structure
export interface McpError extends Error {
  details?: string;
  stdout?: string;
  stderr?: string;
  exitCode?: number | string | null;
  signal?: string | null;
  killed?: boolean;
  originalError?: unknown;
  isTimeout?: boolean;
  execution_time_seconds?: number;
}

export interface ExecuteScriptInput {
  /**
   * The content of the script to execute. Either this or script_path must be provided.
   */
  script_content?: string;
  /**
   * The path to the script file to execute. Either this or script_content must be provided.
   */
  script_path?: string;
  /**
   * Optional arguments to pass to the script. For AppleScript, these are passed to the main `run` handler.
   * For JXA, these are passed to the `run` function.
   */
  arguments?: string[];
  /**
   * Optional JSON object to provide named inputs for --MCP_INPUT placeholders in knowledge base scripts.
   */
  input_data?: Record<string, unknown>;
  /**
   * The timeout for the script execution in seconds. Defaults to 60.
   * @default 60
   */
  timeout_seconds?: number;
  /**
   * If true, the tool will return an additional message containing the formatted script execution time.
   * @default false
   */
  report_execution_time?: boolean;
  /**
   * Controls the output formatting flags for osascript. 
   * 'auto': (Default) Uses human-readable for AppleScript, direct for JXA.
   * 'human_readable': Uses -s h.
   * 'structured_error': Uses -s s.
   * 'structured_output_and_error': Uses -s ss.
   * 'direct': No -s flags.
   * @default auto
   */
  output_format_mode?: 'auto' | 'human_readable' | 'structured_error' | 'structured_output_and_error' | 'direct';
}

/**
 * Represents the output of the script_executor.
 */
export interface ScriptExecutorResult {
  /** The stdout from the script. */
  stdout: string;
  /** The stderr from the script. */
  stderr: string;
  /** The error object if the script failed. */
  error?: Error | McpError;
  /** The execution time in milliseconds. */
  executionTimeMs: number;
  /** Indicates if the script timed out. */
  timedOut: boolean;
}

/**
 * Defines the overall response structure for the execute_script tool.
 */
export interface ExecuteScriptResponse {
  content: Array<{
    type: 'text';
    text: string;
  }>;
  isError?: boolean;
  [key: string]: unknown; // Required by MCP SDK for tool responses
} 