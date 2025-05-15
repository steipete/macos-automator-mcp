import fs from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter'; // yarn add gray-matter @types/gray-matter or npm install ...

const KNOWLEDGE_BASE_ROOT_DIR_NAME = 'knowledge_base';
const KNOWLEDGE_BASE_DIR = path.resolve(process.cwd(), KNOWLEDGE_BASE_ROOT_DIR_NAME);
const SHARED_HANDLERS_DIR_NAME = '_shared_handlers';

interface TipFrontmatter {
  id?: string;
  title: string;
  category?: string; // Should be derived from dir, but good to check if present
  description?: string;
  keywords?: string[];
  language?: 'applescript' | 'javascript';
  isComplex?: boolean;
  argumentsPrompt?: string;
  notes?: string;
}

interface ValidationReport {
  totalFilesChecked: number;
  totalTipsParsed: number;
  totalSharedHandlers: number;
  categoriesFound: Set<string>;
  errors: string[];
  warnings: string[];
  fixesApplied: string[];
  uniqueTipIds: Set<string>;
  duplicateTipIds: string[];
}

const report: ValidationReport = {
  totalFilesChecked: 0,
  totalTipsParsed: 0,
  totalSharedHandlers: 0,
  categoriesFound: new Set(),
  errors: [],
  warnings: [],
  fixesApplied: [],
  uniqueTipIds: new Set(),
  duplicateTipIds: [],
};

function logError(filePath: string, message: string) {
  report.errors.push(`ERROR: [${filePath}] ${message}`);
}

function logWarning(filePath: string, message: string) {
  report.warnings.push(`WARN: [${filePath}] ${message}`);
}

function logFix(filePath: string, message: string) {
  report.fixesApplied.push(`FIXED: [${filePath}] ${message}`);
}

// Basic AppleScript auto-formatter/linter (can be significantly expanded)
function lintAndFixAppleScript(scriptContent: string, filePath: string): string {
  let fixedContent = scriptContent;
  let fixesMade = false;

  // 1. Consistent indentation (simple example: ensure lines in tell blocks are indented)
  // This is a naive approach and can be wrong for complex scripts.
  // A proper parser would be needed for robust indentation.
  const lines = fixedContent.split('\n');
  let indentLevel = 0;
  const indentSize = 2; // spaces
  fixedContent = lines.map(line => {
    const trimmedLine = line.trim();
    if (trimmedLine.startsWith('end tell') || trimmedLine.startsWith('end if') || trimmedLine.startsWith('end repeat') || trimmedLine.startsWith('else') || trimmedLine.startsWith('on error')) {
      indentLevel = Math.max(0, indentLevel - 1);
    }
    let currentIndent = ' '.repeat(indentLevel * indentSize);
    if (trimmedLine.startsWith('else') || trimmedLine.startsWith('on error')) { // these are at same level as `if` or `try`
        currentIndent = ' '.repeat(Math.max(0, indentLevel) * indentSize);
    }

    const reindentedLine = currentIndent + trimmedLine;
    if (reindentedLine !== line.trimEnd() && trimmedLine !== "") { // only log if changed and not an empty line after trim
      // This fix is too noisy and potentially incorrect for complex formatting
      // logFix(filePath, `Re-indented line: "${trimmedLine.substring(0,30)}..."}`);
      // fixesMade = true;
    }

    if ((trimmedLine.startsWith('tell application') && !trimmedLine.endsWith('to')) || trimmedLine.startsWith('if ') && trimmedLine.endsWith('then') && !trimmedLine.includes('end if') || trimmedLine.startsWith('repeat ') || trimmedLine.startsWith('try')) {
      if (!trimmedLine.includes('end tell') && !trimmedLine.includes('end if') && !trimmedLine.includes('end repeat') && !trimmedLine.includes('end try')) {
        indentLevel++;
      }
    }
    return reindentedLine;
  }).join('\n');


  // 2. Consistent keyword casing (example for 'tell application')
  const tellRegex = /\b(tell\s+application)\b/gi;
  if (tellRegex.test(fixedContent)) {
    const originalTellCount = (fixedContent.match(tellRegex) || []).length;
    const newContent = fixedContent.replace(tellRegex, 'tell application');
    if (newContent !== fixedContent && (newContent.match(/\btell application\b/g) || []).length === originalTellCount ) {
        // Only log if a real change happened
        // logFix(filePath, "Standardized 'tell application' casing.");
        // fixesMade = true;
        // fixedContent = newContent;
        // For now, disabling auto-fix for casing as it might be too aggressive without full parsing context.
    }
  }
  // Add more rules: e.g., 'end tell', 'set x to y', 'if...then...else...end if'

  // 3. Check for common issues like missing 'end tell' (hard to auto-fix reliably without full parser)
  const tellMatch = fixedContent.match(/\btell\b/g);
  const endTellMatch = fixedContent.match(/\bend tell\b/g);
  const tellCount = tellMatch ? tellMatch.length : 0;
  const endTellCount = endTellMatch ? endTellMatch.length : 0;
  
  // Skip tell count warning for code with commented sections that might contain tell blocks
  if (fixedContent.includes("(*") && fixedContent.includes("*)")) {
    // Only log warning for severe imbalance, as commented code can contain tell blocks
    if (Math.abs(tellCount - endTellCount) > 2) {
      logWarning(filePath, `Significant imbalance in 'tell'/'end tell' blocks (${tellCount}/${endTellCount}). File has comments that may contain code blocks. Please verify manually.`);
    }
  } else if (tellCount > endTellCount) {
    logWarning(filePath, `Potential missing 'end tell'. Found ${tellCount} 'tell' and ${endTellCount} 'end tell'.`);
  } else if (endTellCount > tellCount) {
    logWarning(filePath, `Potential extraneous 'end tell'. Found ${tellCount} 'tell' and ${endTellCount} 'end tell'.`);
  }

  // 4. Ensure POSIX path for shell scripts or POSIX file for AppleScript paths
  if (fixedContent.includes('do shell script') && fixedContent.match(/["""'][A-Za-z0-9\s]+:/)) { // Detects HFS paths in shell scripts
    logWarning(filePath, "Potential HFS path used in 'do shell script'. Should use POSIX path with 'quoted form of'.");
  }

  if (fixesMade) {
    report.fixesApplied.push(filePath); // Add file path if any fix was made
  }
  return fixedContent;
}

async function validateTipFile(filePath: string, categoryId: string): Promise<void> {
  report.totalFilesChecked++;
  const fileContent = await fs.readFile(filePath, 'utf-8');
  const { data, content: markdownBody, isEmpty, excerpt } = matter(fileContent, { excerpt: true });
  const frontmatter = data as TipFrontmatter;

  // --- Frontmatter Checks ---
  if (!frontmatter.title || typeof frontmatter.title !== 'string' || frontmatter.title.trim() === "") {
    logError(filePath, "Missing or empty 'title' in frontmatter.");
    return; // Critical error, stop processing this file
  }

  report.totalTipsParsed++;
  report.categoriesFound.add(categoryId);

  const expectedId = frontmatter.id || `${categoryId}_${path.basename(filePath, '.md').replace(/^\d+[_.-]?\s*/, '').replace(/\s+/g, '_').toLowerCase()}`;
  if (report.uniqueTipIds.has(expectedId)) {
    logError(filePath, `Duplicate Tip ID detected or generated: '${expectedId}'. Explicitly set a unique 'id' in frontmatter.`);
    report.duplicateTipIds.push(expectedId);
  } else {
    report.uniqueTipIds.add(expectedId);
  }

  if (frontmatter.category && frontmatter.category !== categoryId) {
    logWarning(filePath, `Frontmatter category '${frontmatter.category}' differs from directory category '${categoryId}'. Directory will be used.`);
  }

  if (!frontmatter.description || typeof frontmatter.description !== 'string' || frontmatter.description.trim().length < 10) {
    logWarning(filePath, "Missing, empty, or very short 'description'.");
  }

  if (!frontmatter.keywords || !Array.isArray(frontmatter.keywords) || frontmatter.keywords.length === 0) {
    logWarning(filePath, "Missing or empty 'keywords' array.");
  } else if (frontmatter.keywords.some(kw => typeof kw !== 'string' || kw.trim() === "")) {
    logWarning(filePath, "One or more keywords are not strings or are empty.");
  }

  const defaultLanguage = 'applescript';
  const lang = frontmatter.language || defaultLanguage;
  if (!['applescript', 'javascript'].includes(lang)) {
    logError(filePath, `Invalid language '${lang}' in frontmatter. Must be 'applescript' or 'javascript'.`);
  }

  // --- Markdown Body & Script Block Checks ---
  const scriptBlockRegex = /```(applescript|javascript)\s*\n([\s\S]*?)\n```/i;
  const scriptMatch = markdownBody.match(scriptBlockRegex);
  let scriptContent: string | undefined;

  if (!scriptMatch || !scriptMatch[2] || scriptMatch[2].trim() === "") {
    // Allow conceptual tips without script blocks, but warn if language implies script
    if (lang === 'applescript' || lang === 'javascript') {
         logWarning(filePath, `No script block found or script block is empty, but language is '${lang}'. Is this a conceptual tip?`);
    }
  } else {
    const scriptBlockLang = scriptMatch[1].toLowerCase();
    scriptContent = scriptMatch[2].trim(); // Assign to outer scope variable

    if (scriptBlockLang !== lang) {
      logWarning(filePath, `Frontmatter language ('${lang}') differs from script block language ('${scriptBlockLang}'). Code block language will be used.`);
    }

    if (lang === 'applescript' || scriptBlockLang === 'applescript') {
      const originalScript = scriptContent;
      const fixedScript = lintAndFixAppleScript(originalScript, filePath);
      if (fixedScript !== originalScript) {
        // Auto-fix: Overwrite the file with linted script
        // This is a simplified replacement. A more robust one would parse Markdown structure.
        // const newFileContent = matter.stringify(markdownBody.replace(originalScript, fixedScript), frontmatter);
        // await fs.writeFile(filePath, newFileContent, 'utf-8');
        // logFix(filePath, "Applied AppleScript auto-formatting.");
        // For now, just report what *would* be fixed, don't write to file to avoid accidental corruption.
        // If enabling write: make sure the replacement of script block is robust.
        logWarning(filePath, "AppleScript formatting differences found. Auto-fix available (currently disabled).");
      }
    }
    // Add JXA linting/fixing here if desired
  }

  if (frontmatter.isComplex && !frontmatter.argumentsPrompt && scriptContent?.includes('--MCP_')) {
      logWarning(filePath, `'isComplex: true' and script contains MCP placeholders, but 'argumentsPrompt' is missing in frontmatter.`);
  }
  if (frontmatter.argumentsPrompt && !scriptContent?.includes('--MCP_')) {
      logWarning(filePath, `'argumentsPrompt' is provided, but no --MCP_INPUT or --MCP_ARG_ placeholders found in script.`);
  }
}

async function validateSharedHandlerFile(filePath: string): Promise<void> {
    report.totalFilesChecked++;
    const fileName = path.basename(filePath);
    try {
        const content = await fs.readFile(filePath, 'utf-8');
        if (content.trim() === "") {
            logWarning(filePath, "Shared handler file is empty.");
        }
        // Could add language-specific linting here too
        report.totalSharedHandlers++;
        console.debug("Validated shared handler", {fileName});
    } catch (e: unknown) {
        if (e instanceof Error) {
            logError(filePath, `Failed to read shared handler file: ${e.message}`);
        } else {
            logError(filePath, `Failed to read shared handler file: Unknown error occurred`);
        }
    }
}

// Helper function to recursively validate tip files in a directory
async function validateTipFilesRecursively(
  currentPath: string,
  categoryId: string,
  recursive: boolean = true
): Promise<void> {
  try {
    const entries = await fs.readdir(currentPath, { withFileTypes: true });
    
    for (const entry of entries) {
      const entryPath = path.join(currentPath, entry.name);
      
      if (entry.isDirectory() && recursive) {
        // Recursively validate files in subdirectory (skip _directories)
        if (!entry.name.startsWith('_')) {
          await validateTipFilesRecursively(entryPath, categoryId);
        }
      } else if (entry.isFile() && entry.name.endsWith('.md') && !entry.name.startsWith('_')) {
        // Validate markdown file
        await validateTipFile(entryPath, categoryId);
      }
    }
  } catch (error) {
    logError(currentPath, `Failed to read directory: ${(error as Error).message}`);
  }
}

async function validateKnowledgeBase(): Promise<void> {
  console.info(`Validating knowledge base in: ${KNOWLEDGE_BASE_DIR}`);
  try {
    const categoryDirEntries = await fs.readdir(KNOWLEDGE_BASE_DIR, { withFileTypes: true });

    for (const categoryDirEntry of categoryDirEntries) {
      if (categoryDirEntry.isDirectory()) {
        const categoryId = categoryDirEntry.name;
        const categoryPath = path.join(KNOWLEDGE_BASE_DIR, categoryId);

        if (categoryId === SHARED_HANDLERS_DIR_NAME) {
            const handlerFiles = await fs.readdir(categoryPath, { withFileTypes: true });
            for (const handlerFile of handlerFiles) {
                if (handlerFile.isFile() && (handlerFile.name.endsWith('.applescript') || handlerFile.name.endsWith('.js'))) {
                    await validateSharedHandlerFile(path.join(categoryPath, handlerFile.name));
                }
            }
            continue;
        }

        // Validate _category_info.md if it exists
        const catInfoPath = path.join(categoryPath, '_category_info.md');
        try {
            await fs.access(catInfoPath, fs.constants.R_OK);
            report.totalFilesChecked++;
            const catInfoContent = await fs.readFile(catInfoPath, 'utf-8');
            const { data: catFm } = matter(catInfoContent);
            if (!catFm.description || typeof catFm.description !== 'string' || catFm.description.trim() === "") {
                logWarning(catInfoPath, "Missing or empty 'description' in _category_info.md frontmatter.");
            }
        } catch (e) {
            logWarning(categoryPath, "_category_info.md not found or not readable. Category description will be default.");
        }

        // Validate tip files recursively
        await validateTipFilesRecursively(categoryPath, categoryId);
      }
    }
  } catch (error: unknown) {
    if (error instanceof Error && 'code' in error && (error as NodeJS.ErrnoException).code === 'ENOENT') {
        console.error(`Knowledge base directory NOT FOUND at ${KNOWLEDGE_BASE_DIR}. Please create it or run script from project root.`);
        logError(KNOWLEDGE_BASE_DIR, `Failed to read knowledge base structure: ${error.message}`);
    } else if (error instanceof Error) {
        logError(KNOWLEDGE_BASE_DIR, `Failed to read knowledge base structure: ${error.message}`);
    } else {
        logError(KNOWLEDGE_BASE_DIR, `Failed to read knowledge base structure: Unknown error occurred`);
    }
  }

  // Final Report
  console.log("\n--- Validation Report ---");
  console.log(`Total Files Checked: ${report.totalFilesChecked}`);
  console.log(`Total Scriptable Tips Parsed: ${report.totalTipsParsed}`);
  console.log(`Total Shared Handlers Parsed: ${report.totalSharedHandlers}`);
  console.log(`Categories Found: ${report.categoriesFound.size} (${Array.from(report.categoriesFound).join(', ')})`);

  if (report.errors.length > 0) {
    console.log(`\n--- ERRORS (${report.errors.length}) ---`);
    for (const err of report.errors) {
        console.error(err);
    }
  } else {
    console.log("\n--- ERRORS (0) ---");
    console.log("No critical errors found. Great job!");
  }

  if (report.warnings.length > 0) {
    console.log(`\n--- WARNINGS (${report.warnings.length}) ---`);
    for (const warn of report.warnings) {
        console.warn(warn);
    }
  } else {
    console.log("\n--- WARNINGS (0) ---");
  }

  if (report.fixesApplied.length > 0) {
    console.log(`\n--- AUTO-FIXES APPLIED (${new Set(report.fixesApplied).size} files) ---`); // Use Set to count unique files fixed
    // report.fixesApplied.forEach(fix => console.log(fix)); // This logs individual fix messages
    console.log("Specific auto-fixes were logged during processing (currently disabled for file writes).");
  } else {
    console.log("\n--- AUTO-FIXES APPLIED (0) ---");
  }

  if (report.duplicateTipIds.length > 0) {
      console.warn(`\n--- DUPLICATE TIP IDs (${report.duplicateTipIds.length}) ---`);
      console.warn("The following Tip IDs were duplicated. Ensure each explicit 'id' in frontmatter is unique, and filenames within categories also lead to unique generated IDs:");
      for (const id of report.duplicateTipIds) {
          console.warn(`  - ${id}`);
      }
  }

  console.log("\nValidation complete.");
  if (report.errors.length > 0) {
    process.exitCode = 1; // Indicate failure
  }
}

// Run the validator
validateKnowledgeBase().catch(err => {
  console.error("Unhandled error during validation process:", err);
  process.exitCode = 1;
});