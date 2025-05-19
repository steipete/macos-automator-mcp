// AXQueryExecutor.ts - Execute commands against the AX accessibility utility

import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { Logger } from './logger.js';

// Get the directory of the current module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const logger = new Logger('AXQueryExecutor');

export class AXQueryExecutor {
  private axUtilityPath: string;
  private scriptPath: string;

  constructor() {
    // Calculate the path to the AX utility relative to this file
    this.axUtilityPath = path.resolve(__dirname, '..', 'ax');
    // Path to the wrapper script
    this.scriptPath = path.join(this.axUtilityPath, 'ax_runner.sh');
  }

  /**
   * Execute a query against the AX utility
   * @param queryData The query to execute
   * @returns The result of the query
   */
  async execute(queryData: Record<string, unknown>): Promise<Record<string, unknown>> {
    logger.debug('Executing AX query', queryData);

    return new Promise((resolve, reject) => {
      try {
        // Get the query string
        const queryString = JSON.stringify(queryData) + '\n';

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
          reject(new Error(`Process error: ${error.message}`));
        });
        
        // Handle process exit
        process.on('exit', (code, signal) => {
          logger.debug('Process exited:', { code, signal });
          
          // Check for log file if we had issues
          if (code !== 0 || signal) {
            logger.debug('Checking log file for more information');
            try {
              // We won't actually read it here, but we'll mention it in the error
              const logPath = path.join(this.axUtilityPath, 'ax_runner.log');
              stderrData += `\nCheck log file at ${logPath} for more details.`;
            } catch {
              // Ignore errors reading the log
            }
          }
          
          // If we got any JSON output, try to parse it
          if (stdoutData.trim()) {
            try {
              const result = JSON.parse(stdoutData) as Record<string, unknown>;
              return resolve(result);
            } catch (error) {
              logger.error('Failed to parse JSON output', { error, stdout: stdoutData });
            }
          }
          
          // If we didn't return a result above, handle as error
          if (signal) {
            reject(new Error(`Process terminated by signal ${signal}: ${stderrData}`));
          } else if (code !== 0) {
            reject(new Error(`Process exited with code ${code}: ${stderrData}`));
          } else {
            reject(new Error(`Process completed but no valid output: ${stderrData}`));
          }
        });
        
        // Write the query to stdin and close
        logger.debug('Sending query to AX utility:', { query: queryString });
        process.stdin.write(queryString);
        process.stdin.end();
        
      } catch (error) {
        logger.error('Failed to execute AX utility:', { error });
        reject(new Error(`Failed to execute AX utility: ${error}`));
      }
    });
  }
} 