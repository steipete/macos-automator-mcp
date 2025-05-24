// AXQueryExecutor.ts - Execute commands against the AX accessibility utility

import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { Logger } from './logger.js';
import type { AXQueryInput } from './schemas.js'; // Import AXQueryInput type

// Get the directory of the current module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const logger = new Logger('AXQueryExecutor');

export interface AXQueryExecutionResult {
  result: Record<string, unknown>;
  execution_time_seconds: number;
  debug_logs?: string[];
}

export class AXQueryExecutor {
  private axUtilityPath: string;
  private scriptPath: string;

  constructor() {
    // Determine if running from source or dist to set the correct base path
    // __dirname will be like /path/to/project/src or /path/to/project/dist/src
    const isProdBuild = __dirname.includes(path.join(path.sep, 'dist', path.sep));

    if (isProdBuild) {
      // In production (dist), axorc_runner.sh and axorc binary are directly in dist/
      // So, utility path is one level up from dist/src (i.e., dist/)
      this.axUtilityPath = path.resolve(__dirname, '..'); 
    } else {
      // In development (src), axorc_runner.sh and axorc binary are in project_root/axorc/
      // So, utility path is one level up from src/ and then into axorc/
      this.axUtilityPath = path.resolve(__dirname, '..', 'axorc');
    }
    
    this.scriptPath = path.join(this.axUtilityPath, 'axorc_runner.sh');
    logger.debug('AXQueryExecutor initialized', { 
      isProdBuild, 
      axUtilityPath: this.axUtilityPath, 
      scriptPath: this.scriptPath 
    });
  }

  /**
   * Execute a query against the AX utility
   * @param queryData The query to execute
   * @returns The result of the query
   */
  async execute(queryData: AXQueryInput): Promise<AXQueryExecutionResult> {
    logger.debug('Executing AX query with input:', queryData);
    const startTime = Date.now();

    // Map to the keys expected by the Swift binary
    const mappedQueryData = {
      cmd: queryData.command,
      multi: queryData.return_all_matches,
      locator: {
        app: (queryData.locator as { app: string }).app,
        role: (queryData.locator as { role: string }).role,
        match: (queryData.locator as { match: Record<string, string> }).match,
        pathHint: (queryData.locator as { navigation_path_hint?: string[] }).navigation_path_hint,
      },
      attributes: queryData.attributes_to_query,
      requireAction: queryData.required_action_name,
      action: queryData.action_to_perform,
      // report_execution_time is not sent to the Swift binary
      debug_logging: queryData.debug_logging,
      max_elements: queryData.max_elements,
      output_format: queryData.output_format
    };
    logger.debug('Mapped AX query for Swift binary:', mappedQueryData);

    return new Promise((resolve, reject) => {
      try {
        // Get the query string from the mapped data
        const queryString = JSON.stringify(mappedQueryData) + '\n';

        logger.debug('Running AX utility through wrapper script', { path: this.scriptPath });
        logger.debug('Query to run: ', { query: queryString});
        
        // Run the script with wrapper that handles SIGTRAP
        const process = spawn(this.scriptPath, [], {
          cwd: this.axUtilityPath,
          stdio: ['pipe', 'pipe', 'pipe']
        });

        let stdoutData = '';
        let stderrData = '';
        
        // Listen for stdout
        process.stdout.on('data', (data) => {
          const str = data.toString();
          logger.debug('AX utility stdout:', { data: str });
          stdoutData += str;
        });
        
        // Listen for stderr
        process.stderr.on('data', (data) => {
          const str = data.toString();
          logger.debug('AX utility stderr:', { data: str });
          stderrData += str;
        });
        
        // Handle process errors
        process.on('error', (error) => {
          logger.error('Process error:', { error });
          const endTime = Date.now();
          const execution_time_seconds = parseFloat(((endTime - startTime) / 1000).toFixed(3));
          const errorToReject = new Error(`Process error: ${error.message}`) as Error & { execution_time_seconds?: number };
          errorToReject.execution_time_seconds = execution_time_seconds;
          reject(errorToReject);
        });
        
        // Handle process exit
        process.on('exit', (code, signal) => {
          logger.debug('Process exited:', { code, signal });
          const endTime = Date.now();
          const execution_time_seconds = parseFloat(((endTime - startTime) / 1000).toFixed(3));
          
          // Check for log file if we had issues
          if (code !== 0 || signal) {
            logger.debug('Checking log file for more information');
            try {
              // We won't actually read it here, but we'll mention it in the error
              const logPath = path.join(this.axUtilityPath, 'axorc_runner.log');
              stderrData += `\nCheck log file at ${logPath} for more details.`;
            } catch {
              // Ignore errors reading the log
            }
          }
          
          // If we got any JSON output, try to parse it
          if (stdoutData.trim()) {
            try {
              const parsedJson = JSON.parse(stdoutData) as (Record<string, unknown> & { debug_logs?: string[] });
              // Separate the core result from potential debug_logs
              const { debug_logs, ...coreResult } = parsedJson;
              return resolve({ result: coreResult, execution_time_seconds, debug_logs });
            } catch (error) {
              logger.error('Failed to parse JSON output', { error, stdout: stdoutData });
              // Fall through to error handling below if JSON parsing fails
            }
          }
          
          let errorMessage = '';
          if (signal) {
            errorMessage = `Process terminated by signal ${signal}: ${stderrData}`;
          } else if (code !== 0) {
            errorMessage = `Process exited with code ${code}: ${stderrData}`;
          } else {
            // Attempt to parse stderr as JSON ErrorResponse if stdout was empty but exit was 0
            try {
              const errorJson = JSON.parse(stderrData.split('\n').filter(line => line.startsWith("{\"error\":")).join('') || stderrData);
              if (errorJson.error) {
                errorMessage = `AX tool reported error: ${errorJson.error}`;
                const errorToReject = new Error(errorMessage) as Error & { execution_time_seconds?: number; debug_logs?: string[] };
                errorToReject.execution_time_seconds = execution_time_seconds;
                errorToReject.debug_logs = errorJson.debug_logs; // Capture debug logs from error JSON
                return reject(errorToReject);
              }
            } catch {
              // stderr was not a JSON error response, proceed with generic message
            }
            errorMessage = `Process completed but no valid JSON output on stdout. Stderr: ${stderrData}`;
          }
          const errorToReject = new Error(errorMessage) as Error & { execution_time_seconds?: number; debug_logs?: string[] };
          errorToReject.execution_time_seconds = execution_time_seconds;
          // If stderrData might contain our JSON error object with debug_logs, try to parse it
          try {
            const errorJson = JSON.parse(stderrData.split('\n').filter(line => line.startsWith("{\"error\":")).join('') || stderrData);
            if (errorJson.debug_logs) {
              errorToReject.debug_logs = errorJson.debug_logs;
            }
          } catch { /* ignore if stderr is not our JSON error */ }
          reject(errorToReject);
        });
        
        // Write the query to stdin and close
        logger.debug('Sending query to AX utility:', { query: queryString });
        process.stdin.write(queryString);
        process.stdin.end();
        
      } catch (error) {
        logger.error('Failed to execute AX utility:', { error });
        const endTime = Date.now();
        const execution_time_seconds = parseFloat(((endTime - startTime) / 1000).toFixed(3));
        const errorToReject = new Error(`Failed to execute AX utility: ${error instanceof Error ? error.message : String(error)}`) as Error & { execution_time_seconds?: number };
        errorToReject.execution_time_seconds = execution_time_seconds;
        reject(errorToReject);
      }
    });
  }
} 