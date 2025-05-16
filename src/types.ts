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
  exitCode?: number | string | null; // Allow string for error codes like 'ENOENT'
  signal?: string | null;
  killed?: boolean; // Specifically for timeouts
  originalError?: unknown; // The raw error from child_process
  isTimeout?: boolean;
}

// MCP Tool Response Types
export interface ExecuteScriptResponse {
  content: Array<{
    type: 'text';
    text: string;
  }>;
  isError?: boolean;
} 