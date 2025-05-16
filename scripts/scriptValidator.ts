import fs from 'node:fs/promises';
import path from 'node:path';
import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import matter from 'gray-matter';
import { logErrorToReport, logWarningToReport, report } from './kbReport.js';

const execPromise = promisify(exec);

/**
 * Validates script syntax WITHOUT executing the script
 * @param scriptContent The script content to validate
 * @param language The script language ('applescript' or 'javascript')
 * @returns A promise that resolves with validation result
 */
async function validateScriptSyntax(
  scriptContent: string,
  language: 'applescript' | 'javascript'
): Promise<{ isValid: boolean; error?: string }> {
  if (!scriptContent || scriptContent.trim() === '') {
    return { isValid: false, error: 'Empty script content' };
  }

  try {
    // Escape single quotes in script content for shell execution
    const escapedScript = scriptContent.replace(/'/g, "'\\''")
    
    try {
      if (language === 'applescript') {
        // Fast inline method for AppleScript
        await execPromise(`osacompile -e '${escapedScript}' -o /dev/null`);
      } else {
        // For JXA
        await execPromise(`osacompile -l JavaScript -e '${escapedScript}' -o /dev/null`);
      }
      return { isValid: true };
    } catch (error: any) {
      return { 
        isValid: false, 
        error: error.stderr || error.stdout || error.message || 'Unknown error during syntax validation'
      };
    }
  } catch (error: any) {
    return { 
      isValid: false, 
      error: `Failed to validate script: ${error.message}` 
    };
  }
}

/**
 * Extracts script content from a markdown file
 */
function extractScriptFromMarkdown(markdownContent: string): string | null {
  const scriptBlockRegex = /```(?:applescript|javascript)\s*\n([\s\S]*?)\n```/i;
  const scriptMatch = markdownContent.match(scriptBlockRegex);
  
  return scriptMatch && scriptMatch[1] ? scriptMatch[1].trim() : null;
}

/**
 * Validates AppleScript or JXA syntax in a knowledge base tip file
 */
export async function validateTipScriptSyntax(
  filePath: string,
  isLocalKb: boolean
): Promise<boolean> {
  try {
    const fileContent = await fs.readFile(filePath, 'utf-8');
    const { data: frontmatter, content: markdownBody } = matter(fileContent);
    
    // Check if this is an AppleScript or JXA file
    const language = frontmatter.language as 'applescript' | 'javascript';
    if (!language || !['applescript', 'javascript'].includes(language)) {
      // Not a script file or missing language specification
      return true;
    }

    // Extract the script content from markdown
    const scriptContent = extractScriptFromMarkdown(markdownBody);
    if (!scriptContent) {
      // No script content found, which is already checked by the main validator
      return true;
    }

    // Increment the count of scripts being validated
    report.scriptSyntaxValidated++;

    // Validate the script syntax
    const result = await validateScriptSyntax(scriptContent, language);
    if (!result.isValid && result.error) {
      // Increment the count of scripts with syntax errors
      report.scriptSyntaxErrors++;
      
      logErrorToReport(
        filePath,
        `${language.toUpperCase()} syntax error: ${result.error}`,
        isLocalKb
      );
      return false;
    }

    return true;
  } catch (error: any) {
    // Count validation failures as syntax errors for reporting
    report.scriptSyntaxErrors++;
    
    logErrorToReport(
      filePath,
      `Failed to validate script syntax: ${error.message}`,
      isLocalKb
    );
    return false;
  }
}

/**
 * Batch validates multiple files
 * @param filePaths Array of file paths to validate
 * @param isLocalKb Whether these files are from the local knowledge base
 * @returns Object with validation statistics
 */
export async function validateScriptFiles(
  filePaths: string[],
  isLocalKb: boolean
): Promise<{ total: number; valid: number; invalid: number }> {
  let valid = 0;
  let invalid = 0;

  for (const filePath of filePaths) {
    const isValid = await validateTipScriptSyntax(filePath, isLocalKb);
    if (isValid) {
      valid++;
    } else {
      invalid++;
    }
  }

  return {
    total: filePaths.length,
    valid,
    invalid
  };
}