import fs from 'node:fs/promises';
import path from 'node:path';
import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import matter from 'gray-matter';

const execPromise = promisify(exec);

/**
 * Simple test script to validate AppleScript and JXA syntax
 */
async function validateScript(
  scriptContent: string,
  language: 'applescript' | 'javascript'
): Promise<{ isValid: boolean; error?: string }> {
  if (!scriptContent || scriptContent.trim() === '') {
    return { isValid: false, error: 'Empty script content' };
  }

  try {
    // Escape single quotes in the script content for safe shell execution
    const escapedScript = scriptContent.replace(/'/g, "'\\''")
    
    if (language === 'applescript') {
      // Directly validate AppleScript syntax with osascript -e
      await execPromise(`osascript -l AppleScript -e '${escapedScript}' > /dev/null 2>&1`);
    } else {
      // For JXA, use osascript with JavaScript language flag
      await execPromise(`osascript -l JavaScript -e '${escapedScript}' > /dev/null 2>&1`);
    }
    return { isValid: true };
  } catch (error: any) {
    return { 
      isValid: false, 
      error: error.stderr || error.stdout || error.message || 'Unknown error during syntax validation'
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
async function validateTipFile(filePath: string): Promise<boolean> {
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
      // No script content found
      return true;
    }

    // Validate the script syntax
    const result = await validateScript(scriptContent, language);
    
    console.log(`  Syntax: ${result.isValid ? 'Valid' : 'Invalid'}`);
    if (!result.isValid && result.error) {
      console.log(`  Error: ${result.error}`);
      return false;
    }

    return true;
  } catch (error: any) {
    console.error(`  Error: ${error.message}`);
    return false;
  }
}

async function runTests() {
  const testFiles = [
    'test_valid_applescript.md',
    'test_invalid_applescript.md',
    'test_valid_jxa.md',
    'test_invalid_jxa.md'
  ];
  
  const testDir = path.join(process.cwd(), 'knowledge_base/test_syntax_validation');
  
  console.log('Testing Script Validator on Test Files:');
  console.log('=======================================');
  
  for (const file of testFiles) {
    const filePath = path.join(testDir, file);
    
    try {
      console.log(`\nTesting ${file}:`);
      const result = await validateTipFile(filePath);
      console.log(`Result: ${result ? 'Valid' : 'Invalid'}`);
    } catch (error) {
      console.error(`Error testing ${file}:`, error);
    }
  }
}

runTests().catch(console.error);