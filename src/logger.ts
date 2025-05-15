// Logging utility 
import type { LogLevel } from './types';

const LOG_LEVELS: Record<LogLevel, number> = {
  DEBUG: 0,
  INFO: 1,
  WARN: 2,
  ERROR: 3,
};

export class Logger {
  private currentLogLevel; // Type is inferred from constructor assignment
  // private context: string; // Type is inferred from constructor

  constructor(private context: string = 'MCP_Server') { // Using private accessor in constructor to declare and assign
    const envLogLevel = process.env.LOG_LEVEL?.toUpperCase() as LogLevel | undefined;
    this.currentLogLevel = envLogLevel && LOG_LEVELS[envLogLevel] !== undefined
      ? LOG_LEVELS[envLogLevel]
      : LOG_LEVELS.INFO;
  }

  private log(level: LogLevel, message: string, data?: Record<string, unknown>): void {
    if (LOG_LEVELS[level] >= this.currentLogLevel) {
      const timestamp = new Date().toISOString();
      const dataString = data ? ` ${JSON.stringify(data)}` : '';
      console.error(`[${timestamp}] [${this.context}] [${level}] ${message}${dataString}`);
    }
  }

  debug(message: string, data?: Record<string, unknown>): void {
    this.log('DEBUG', message, data);
  }

  info(message: string, data?: Record<string, unknown>): void {
    this.log('INFO', message, data);
  }

  warn(message: string, data?: Record<string, unknown>): void {
    this.log('WARN', message, data);
  }

  error(message: string, data?: Record<string, unknown>): void {
    this.log('ERROR', message, data);
  }
} 