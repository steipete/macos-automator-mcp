// src/ScriptExecutor.ts
import { execFile, type ExecFileException } from 'node:child_process';
import { promisify } from 'node:util';
import fs from 'node:fs/promises';
import os from 'node:os';
import { Logger } from './logger';
import type { ScriptExecutionOptions, ScriptExecutionResult, ScriptExecutionError } from './types';

const execFileAsync = promisify(execFile);
const logger = new Logger('ScriptExecutor');

export class ScriptExecutor {
  public async execute(
    scriptSource: { content?: string; path?: string },
    options: ScriptExecutionOptions = {}
  ): Promise<ScriptExecutionResult> {
    if (os.platform() !== 'darwin') {
      const platformError = new Error('AppleScript/JXA execution is only supported on macOS.') as ScriptExecutionError;
      platformError.name = "UnsupportedPlatformError";
      throw platformError;
    }

    const {
      language = 'applescript',
      timeoutMs = 30000, // Default 30 seconds
      useScriptFriendlyOutput = false,
      arguments: scriptArgs = [],
    } = options;

    const osaArgs: string[] = [];

    if (language === 'javascript') {
      osaArgs.push('-l', 'JavaScript');
    }

    if (useScriptFriendlyOutput) {
      osaArgs.push('-ss'); // Script-friendly output (structured)
    } else {
      osaArgs.push('-s', 'h'); // Human-readable output (default behavior if no -s flag)
    }

    let scriptToLog: string;

    if (scriptSource.content !== undefined) {
      osaArgs.push('-e', scriptSource.content);
      scriptToLog = scriptSource.content.length > 200 ? `${scriptSource.content.substring(0, 200)}...` : scriptSource.content;
    } else if (scriptSource.path) {
      try {
        await fs.access(scriptSource.path, fs.constants.R_OK);
      } catch (accessError) {
        logger.error('Script file access error', { path: scriptSource.path, error: (accessError as Error).message });
        const fileError = new Error(`Script file not found or not readable: ${scriptSource.path}`) as ScriptExecutionError;
        fileError.name = "ScriptFileAccessError";
        throw fileError;
      }
      osaArgs.push(scriptSource.path);
      scriptToLog = `File: ${scriptSource.path}`;
    } else {
      // This case should be prevented by Zod validation in server.ts
      const sourceError = new Error('Either scriptContent or scriptPath must be provided.') as ScriptExecutionError;
      sourceError.name = "InvalidScriptSourceError";
      throw sourceError;
    }

    // Add script arguments AFTER script path or -e flags
    osaArgs.push(...scriptArgs);

    logger.debug('Executing osascript', { command: 'osascript', args: osaArgs.map(arg => arg.length > 50 ? `${arg.substring(0,50)}...` : arg), scriptToLog });

    try {
      const { stdout, stderr } = await execFileAsync('osascript', osaArgs, { timeout: timeoutMs, windowsHide: true });

      const stdoutString = stdout.toString();
      const stderrString = stderr.toString();

      if (stderrString?.trim()) {
        logger.warn('osascript produced stderr output on successful execution', { stderr: stderrString.trim() });
      }
      return { stdout: stdoutString.trim(), stderr: stderrString.trim() };
    } catch (error: unknown) {
      const nodeError = error as ExecFileException; // Error from execFileAsync
      const executionError: ScriptExecutionError = new Error(nodeError.message) as ScriptExecutionError;

      executionError.name = nodeError.name; // Preserve original error name if meaningful
      executionError.stdout = nodeError.stdout?.toString();
      executionError.stderr = nodeError.stderr?.toString();
      executionError.exitCode = nodeError.code; // string or number
      executionError.signal = nodeError.signal;
      executionError.killed = !!nodeError.killed;
      executionError.isTimeout = !!nodeError.killed; // 'killed' is true if process was terminated by timeout
      executionError.originalError = nodeError; // Preserve original node error
      
      logger.error('osascript execution failed', {
        message: executionError.message,
        stdout: executionError.stdout?.trim(),
        stderr: executionError.stderr?.trim(),
        exitCode: executionError.exitCode,
        signal: executionError.signal,
        isTimeout: executionError.isTimeout,
        scriptToLog,
      });
      // Re-throw with enriched info; server.ts will wrap in McpError
      throw executionError;
    }
  }
} 