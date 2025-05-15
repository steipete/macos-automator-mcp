import fs from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter'; // yarn add gray-matter @types/gray-matter or npm install ...
import os from 'node:os'; // Added for home directory resolution

const KNOWLEDGE_BASE_ROOT_DIR_NAME = 'knowledge_base';
const EMBEDDED_KNOWLEDGE_BASE_DIR = path.resolve(process.cwd(), KNOWLEDGE_BASE_ROOT_DIR_NAME);
const SHARED_HANDLERS_DIR_NAME = '_shared_handlers';

const LOCAL_KB_ENV_VAR = 'LOCAL_KB_PATH'; // Matching service
const DEFAULT_LOCAL_KB_PATH = path.join(os.homedir(), '.macos-automator', 'knowledge_base');

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
  categoriesFound: Set<string>; // Categories with at least one tip
  errors: string[];
  warnings: string[];
  fixesApplied: string[]; // Paths of files where fixes were logged (not necessarily applied)
  uniqueTipIds: Set<string>; // All unique IDs from both KBs
  duplicateTipIdsPrimary: string[]; // Duplicates found within the primary KB
  overriddenTipIdsLocal: string[]; // Tip IDs from primary KB that were overridden by local KB
  localOnlyNewTipIds: Set<string>; // New tip IDs found only in local KB
  sharedHandlerNames: Set<string>; // Unique shared handler names (name_language)
  duplicateSharedHandlersPrimary: string[]; // Duplicates in primary
  overriddenSharedHandlersLocal: string[]; // Overridden by local
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
  duplicateTipIdsPrimary: [],
  overriddenTipIdsLocal: [],
  localOnlyNewTipIds: new Set(),
  sharedHandlerNames: new Set(),
  duplicateSharedHandlersPrimary: [],
  overriddenSharedHandlersLocal: [],
};

function getLocalKnowledgeBasePath(cliArgPath?: string): string {
  if (cliArgPath) {
    console.info(`Using custom local knowledge base path from CLI argument: ${cliArgPath}`);
    return path.resolve(cliArgPath.startsWith('~') ? cliArgPath.replace('~', os.homedir()) : cliArgPath);
  }
  const envPath = process.env[LOCAL_KB_ENV_VAR];
  if (envPath) {
    console.info(`Using custom local knowledge base path from LOCAL_KB_PATH env var: ${envPath}`);
    return path.resolve(envPath.startsWith('~') ? envPath.replace('~', os.homedir()) : envPath);
  }
  console.info(`Using default local knowledge base path: ${DEFAULT_LOCAL_KB_PATH}`);
  return DEFAULT_LOCAL_KB_PATH;
}

function logError(filePath: string, message: string, isLocalKbIssue = false) {
  const prefix = isLocalKbIssue ? "LOCAL_KB " : "";
  report.errors.push(`ERROR: ${prefix}[${filePath}] ${message}`);
}

function logWarning(filePath: string, message: string, isLocalKbIssue = false) {
  const prefix = isLocalKbIssue ? "LOCAL_KB " : "";
  report.warnings.push(`WARN: ${prefix}[${filePath}] ${message}`);
}

// Function is currently unused
// function logFix(filePath: string, message: string) { // Fixes are not typically local-specific in logging
//   report.fixesApplied.push(`FIXED: [${filePath}] ${message}`);
// }

// Basic AppleScript auto-formatter/linter (can be significantly expanded)
// Function is currently unused
// function lintAndFixAppleScript(scriptContent: string, filePath: string): string {
//   let fixedContent = scriptContent;
//   const fixesMade = false;

  //   // 1. Consistent indentation (simple example: ensure lines in tell blocks are indented)
  //   // This is a naive approach and can be wrong for complex scripts.
  //   // A proper parser would be needed for robust indentation.
  //   const lines = fixedContent.split('\n');
  //   let indentLevel = 0;
  //   const indentSize = 2; // spaces
  //   fixedContent = lines.map(line => {
  //     const trimmedLine = line.trim();
  //     if (trimmedLine.startsWith('end tell') || trimmedLine.startsWith('end if') || trimmedLine.startsWith('end repeat') || trimmedLine.startsWith('else') || trimmedLine.startsWith('on error')) {
  //       indentLevel = Math.max(0, indentLevel - 1);
  //     }
  //     let currentIndent = ' '.repeat(indentLevel * indentSize);
  //     if (trimmedLine.startsWith('else') || trimmedLine.startsWith('on error')) { // these are at same level as `if` or `try`
  //         currentIndent = ' '.repeat(Math.max(0, indentLevel) * indentSize);
  //     }

  //     const reindentedLine = currentIndent + trimmedLine;
  //     if (reindentedLine !== line.trimEnd() && trimmedLine !== "") { // only log if changed and not an empty line after trim
  //       // This fix is too noisy and potentially incorrect for complex formatting
  //       // logFix(filePath, `Re-indented line: "${trimmedLine.substring(0,30)}..."}`);
  //       // fixesMade = true;
  //     }

  //     if ((trimmedLine.startsWith('tell application') && !trimmedLine.endsWith('to')) || trimmedLine.startsWith('if ') && trimmedLine.endsWith('then') && !trimmedLine.includes('end if') || trimmedLine.startsWith('repeat ') || trimmedLine.startsWith('try')) {
  //       if (!trimmedLine.includes('end tell') && !trimmedLine.includes('end if') && !trimmedLine.includes('end repeat') && !trimmedLine.includes('end try')) {
  //         indentLevel++;
  //       }
  //     }
  //     return reindentedLine;
  //   }).join('\n');


  //   // 2. Consistent keyword casing (example for 'tell application')
  //   const tellRegex = /\b(tell\s+application)\b/gi;
  //   if (tellRegex.test(fixedContent)) {
  //     const originalTellCount = (fixedContent.match(tellRegex) || []).length;
  //     const newContent = fixedContent.replace(tellRegex, 'tell application');
  //     if (newContent !== fixedContent && (newContent.match(/\btell application\b/g) || []).length === originalTellCount ) {
  //         // Only log if a real change happened
  //         // logFix(filePath, "Standardized 'tell application' casing.");
  //         // fixesMade = true;
  //         // fixedContent = newContent;
  //         // For now, disabling auto-fix for casing as it might be too aggressive without full parsing context.
  //     }
  //   }
  //   // Add more rules: e.g., 'end tell', 'set x to y', 'if...then...else...end if'

  //   // 3. Check for common issues like missing 'end tell' (hard to auto-fix reliably without full parser)
  //   const tellMatch = fixedContent.match(/\btell\b/g);
  //   const endTellMatch = fixedContent.match(/\bend tell\b/g);
  //   const tellCount = tellMatch ? tellMatch.length : 0;
  //   const endTellCount = endTellMatch ? endTellMatch.length : 0;
    
  //   // Skip tell count warning for code with commented sections that might contain tell blocks
  //   if (fixedContent.includes("(*") && fixedContent.includes("*)")) {
  //     // Only log warning for severe imbalance, as commented code can contain tell blocks
  //     if (Math.abs(tellCount - endTellCount) > 2) {
  //       logWarning(filePath, `Significant imbalance in 'tell'/'end tell' blocks (${tellCount}/${endTellCount}). File has comments that may contain code blocks. Please verify manually.`, false);
  //     }
  //   } else if (tellCount > endTellCount) {
  //     logWarning(filePath, `Potential missing 'end tell'. Found ${tellCount} 'tell' and ${endTellCount} 'end tell'.`, false);
  //   } else if (endTellCount > tellCount) {
  //     logWarning(filePath, `Potential extraneous 'end tell'. Found ${tellCount} 'tell' and ${endTellCount} 'end tell'.`, false);
  //   }

  //   // 4. Ensure POSIX path for shell scripts or POSIX file for AppleScript paths
  //   if (fixedContent.includes('do shell script') && fixedContent.match(/["""'][A-Za-z0-9\s]+:/)) { // Detects HFS paths in shell scripts
  //     logWarning(filePath, "Potential HFS path used in 'do shell script'. Should use POSIX path with 'quoted form of.'.", false);
  //   }

  //   if (fixesMade) {
  //     report.fixesApplied.push(filePath); // Add file path if any fix was made
  //   }
  //   return fixedContent;
// }

async function validateTipFile(filePath: string, categoryId: string, kbPath: string, isLocalKb: boolean): Promise<void> {
  report.totalFilesChecked++;
  const fileContent = await fs.readFile(filePath, 'utf-8');
  const { data, content: markdownBody } = matter(fileContent, { excerpt: true });
  const frontmatter = data as TipFrontmatter;

  // --- Frontmatter Checks ---
  if (!frontmatter.title || typeof frontmatter.title !== 'string' || frontmatter.title.trim() === "") {
    logError(filePath, "Missing or empty 'title' in frontmatter.", isLocalKb);
    return; // Critical error, stop processing this file
  }

  // Do not increment totalTipsParsed here, will do it after ID check for local
  // report.categoriesFound.add(categoryId); // Add category later based on actual tips

  const baseName = path.basename(filePath, '.md').replace(/^\d+[_.-]?\s*/, '').replace(/\s+/g, '_').toLowerCase();
  const relativeDirPath = path.dirname(path.relative(path.join(kbPath, categoryId), filePath));
  const pathPrefix = relativeDirPath && relativeDirPath !== '.' ? `${relativeDirPath.replace(/[\\/_]/g, '_')}_` : '';
  const generatedId = `${categoryId}_${pathPrefix}${baseName}`;
  const tipId = frontmatter.id || generatedId;


  if (isLocalKb) {
    if (report.uniqueTipIds.has(tipId)) {
      // This ID from local KB already exists (likely from primary KB) - it's an override
      if (!report.overriddenTipIdsLocal.includes(tipId)) {
        report.overriddenTipIdsLocal.push(tipId);
      }
      logWarning(filePath, `Local tip with ID '${tipId}' overrides an existing tip from primary KB.`, true);
    } else {
      // This ID from local KB is new
      report.localOnlyNewTipIds.add(tipId);
      report.uniqueTipIds.add(tipId); // Add to global unique set
    }
  } else { // Primary KB
    if (report.uniqueTipIds.has(tipId)) {
      logError(filePath, `Duplicate Tip ID detected or generated in primary KB: '${tipId}'. Explicitly set a unique 'id' in frontmatter or rename file.`, false);
      if (!report.duplicateTipIdsPrimary.includes(tipId)) {
        report.duplicateTipIdsPrimary.push(tipId);
      }
    } else {
      report.uniqueTipIds.add(tipId);
    }
  }
  
  report.totalTipsParsed++; // Count all successfully parsed tips (past title and ID check)
  report.categoriesFound.add(categoryId);


  if (frontmatter.category && frontmatter.category !== categoryId) {
    logWarning(filePath, `Frontmatter category '${frontmatter.category}' differs from directory category '${categoryId}'. Directory will be used.`, isLocalKb);
  }

  if (!frontmatter.description || typeof frontmatter.description !== 'string' || frontmatter.description.trim().length < 10) {
    logWarning(filePath, "Missing, empty, or very short 'description'.", isLocalKb);
  }

  if (!frontmatter.keywords || !Array.isArray(frontmatter.keywords) || frontmatter.keywords.length === 0) {
    logWarning(filePath, "Missing or empty 'keywords' array.", isLocalKb);
  } else if (frontmatter.keywords.some(kw => typeof kw !== 'string' || kw.trim() === "")) {
    logWarning(filePath, "One or more keywords are not strings or are empty.", isLocalKb);
  }

  const defaultLanguage = 'applescript';
  const lang = frontmatter.language || defaultLanguage;
  if (!['applescript', 'javascript'].includes(lang)) {
    logError(filePath, `Invalid language '${lang}' in frontmatter. Must be 'applescript' or 'javascript'.`, isLocalKb);
  }

  // --- Markdown Body & Script Block Checks ---
  const scriptBlockRegex = /```(applescript|javascript)\s*\n([\s\S]*?)\n```/i;
  const scriptMatch = markdownBody.match(scriptBlockRegex);
  let scriptContent: string | undefined;

  if (!scriptMatch || !scriptMatch[2] || scriptMatch[2].trim() === "") {
    // Allow conceptual tips without script blocks, but warn if language implies script
    if (lang === 'applescript' || lang === 'javascript') {
         logWarning(filePath, `No script block found or script block is empty, but language is '${lang}'. Is this a conceptual tip?`, isLocalKb);
    }
  } else {
    const scriptBlockLang = scriptMatch[1].toLowerCase();
    scriptContent = scriptMatch[2].trim(); // Assign to outer scope variable

    if (scriptBlockLang !== lang) {
      logWarning(filePath, `Frontmatter language ('${lang}') differs from script block language ('${scriptBlockLang}'). Code block language will be used.`, isLocalKb);
    }

    if (lang === 'applescript' || scriptBlockLang === 'applescript') {
      // const fixedScript = lintAndFixAppleScript(scriptContent, filePath); // LINTING DISABLED FOR NOW
      // if (fixedScript !== originalScript) {
        // logWarning(filePath, "AppleScript formatting differences found. Auto-fix available (currently disabled).", isLocalKb);
      // }
    }
    // Add JXA linting/fixing here if desired
  }

  if (frontmatter.isComplex && !frontmatter.argumentsPrompt && scriptContent?.includes('--MCP_')) {
      logWarning(filePath, "'isComplex: true' and script contains MCP placeholders, but 'argumentsPrompt' is missing in frontmatter.", isLocalKb);
  }
  if (frontmatter.argumentsPrompt && !scriptContent?.includes('--MCP_')) {
      logWarning(filePath, "'argumentsPrompt' is provided, but no --MCP_INPUT or --MCP_ARG_ placeholders found in script.", isLocalKb);
  }
}

async function validateSharedHandlerFile(filePath: string, isLocalKb: boolean): Promise<void> {
    report.totalFilesChecked++;
    const fileName = path.basename(filePath);
    const handlerName = path.basename(fileName, path.extname(fileName));
    const language = fileName.endsWith('.js') ? 'javascript' : 'applescript';
    const handlerIdentifier = `${handlerName}_${language}`;

    try {
        const content = await fs.readFile(filePath, 'utf-8');
        if (content.trim() === "") {
            logWarning(filePath, "Shared handler file is empty.", isLocalKb);
        }
        // Could add language-specific linting here too

        if (isLocalKb) {
            if (report.sharedHandlerNames.has(handlerIdentifier)) {
                // Overriding an existing handler
                if (!report.overriddenSharedHandlersLocal.includes(handlerIdentifier)) {
                    report.overriddenSharedHandlersLocal.push(handlerIdentifier);
                }
                logWarning(filePath, `Local shared handler '${handlerIdentifier}' overrides an existing one.`, true);
            } else {
                report.sharedHandlerNames.add(handlerIdentifier); // New local-only handler
            }
        } else { // Primary KB
            if (report.sharedHandlerNames.has(handlerIdentifier)) {
                logError(filePath, `Duplicate shared handler detected in primary KB: '${handlerIdentifier}'. Rename to ensure uniqueness.`, false);
                if (!report.duplicateSharedHandlersPrimary.includes(handlerIdentifier)) {
                    report.duplicateSharedHandlersPrimary.push(handlerIdentifier);
                }
            } else {
                report.sharedHandlerNames.add(handlerIdentifier);
            }
        }
        report.totalSharedHandlers++; // Count all successfully processed handlers
    } catch (error: unknown) {
        if (error instanceof Error) {
            logError(filePath, `Failed to read shared handler file: ${error.message}`, isLocalKb);
        } else {
            logError(filePath, `Failed to read shared handler file: Unknown error occurred`, isLocalKb);
        }
    }
}

// Helper function to recursively validate tip files in a directory
async function validateTipFilesRecursively(
  currentPath: string,
  categoryId: string,
  kbPathToUse: string, // root of current KB being scanned (embedded or local)
  isLocalKbScan: boolean, // flag if this scan is for local KB
  recursive: boolean = true
): Promise<void> {
  try {
    const entries = await fs.readdir(currentPath, { withFileTypes: true });
    
    for (const entry of entries) {
      const entryPath = path.join(currentPath, entry.name);
      
      if (entry.isDirectory() && recursive) {
        // Recursively validate files in subdirectory (skip _directories)
        if (!entry.name.startsWith('_')) {
          await validateTipFilesRecursively(entryPath, categoryId, kbPathToUse, isLocalKbScan);
        }
      } else if (entry.isFile() && entry.name.endsWith('.md') && !entry.name.startsWith('_')) {
        // Validate markdown file
        await validateTipFile(entryPath, categoryId, kbPathToUse, isLocalKbScan);
      }
    }
  } catch (error) {
    // If local KB path doesn't exist for a category, it's not an error for *that specific category scan*
    // but could be a warning if the root local KB path was expected but empty.
    // The root path existence is checked before calling this function.
    if (!isLocalKbScan || (error as NodeJS.ErrnoException)?.code !== 'ENOENT') {
        logError(currentPath, `Failed to read directory: ${(error as Error).message}`, isLocalKbScan);
    } else {
        // For local KB, if a specific category sub-directory is missing, it's fine.
        // console.debug(`Optional category directory not found in local KB: ${currentPath}`);
    }
  }
}

async function processKnowledgeBasePath(basePathToScan: string, isLocal: boolean): Promise<void> {
  console.info(`Validating knowledge base in: ${basePathToScan} ${isLocal ? '(Local)' : '(Embedded)'}`);
  try {
    const categoryDirEntries = await fs.readdir(basePathToScan, { withFileTypes: true });

    for (const categoryDirEntry of categoryDirEntries) {
      if (categoryDirEntry.isDirectory()) {
        const categoryId = categoryDirEntry.name;
        const categoryPath = path.join(basePathToScan, categoryId);

        if (categoryId === SHARED_HANDLERS_DIR_NAME) {
            try {
                const handlerFiles = await fs.readdir(categoryPath, { withFileTypes: true });
                for (const handlerFile of handlerFiles) {
                    if (handlerFile.isFile() && (handlerFile.name.endsWith('.applescript') || handlerFile.name.endsWith('.js'))) {
                        await validateSharedHandlerFile(path.join(categoryPath, handlerFile.name), isLocal);
                    }
                }
            } catch (error) { // Catch error if _shared_handlers dir doesn't exist in local KB
                if (!isLocal || (error as NodeJS.ErrnoException)?.code !== 'ENOENT') {
                    logError(categoryPath, `Failed to read _shared_handlers directory: ${(error as Error).message}`, isLocal);
                } else {
                    // console.debug(`Optional _shared_handlers directory not found in local KB: ${categoryPath}`);
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
                logWarning(catInfoPath, "Missing or empty 'description' in _category_info.md frontmatter.", isLocal);
            }
             // Add category to found set if its _category_info.md is present and valid,
             // even if it has no scriptable tips (might be conceptual)
            if (!report.categoriesFound.has(categoryId) && catFm.description) {
                 // report.categoriesFound.add(categoryId); // this is now handled in validateTipFile based on actual tips
            }
        } catch {
            // Only warn if not found for primary KB. For local, it's optional.
            if (!isLocal) {
                logWarning(categoryPath, "_category_info.md not found or not readable. Category description will be default.", false);
            }
        }

        // Validate tip files recursively
        await validateTipFilesRecursively(categoryPath, categoryId, basePathToScan, isLocal);
      }
    }
  } catch (error: unknown) {
    if (error instanceof Error && 'code' in error && (error as NodeJS.ErrnoException).code === 'ENOENT') {
        if (!isLocal) { // Only error out if the *embedded* KB is not found
            console.error(`Required knowledge base directory NOT FOUND at ${basePathToScan}.`);
            logError(basePathToScan, `Failed to read knowledge base structure: ${error.message}`, false);
        } else {
            console.warn(`Local knowledge base directory not found at ${basePathToScan}. Skipping.`);
            logWarning(basePathToScan, `Local KB directory not found. This is okay if not using one.`, true);
        }
    } else if (error instanceof Error) {
        logError(basePathToScan, `Failed to read knowledge base structure: ${error.message}`, isLocal);
    } else {
        logError(basePathToScan, `Failed to read knowledge base structure: Unknown error occurred`, isLocal);
    }
  }
}

async function validateKnowledgeBase(): Promise<void> {
  let localKbPathArg: string | undefined;
  const args = process.argv.slice(2);
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--local-kb-path' || args[i] === '-l') {
      if (i + 1 < args.length) {
        localKbPathArg = args[i+1];
        i++; // skip next arg as it's the value
      } else {
        console.error("Error: --local-kb-path requires a value.");
        process.exit(1);
      }
    }
  }

  // Validate Embedded KB first
  await processKnowledgeBasePath(EMBEDDED_KNOWLEDGE_BASE_DIR, false);

  // Validate Local KB
  const localKbPathToUse = getLocalKnowledgeBasePath(localKbPathArg);
  try {
      // Check if local KB path actually exists before attempting to read it
      await fs.access(localKbPathToUse);
      await processKnowledgeBasePath(localKbPathToUse, true);
  } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
          console.info(`Local knowledge base path ${localKbPathToUse} not found or not accessible. Skipping local KB validation. This is normal if you haven't set one up.`);
          // No need to log this as an error in the report itself, console.info is enough.
      } else {
          console.error(`Error accessing local knowledge base path ${localKbPathToUse}: ${(error as Error).message}`);
          logError(localKbPathToUse, `Error accessing local knowledge base: ${(error as Error).message}`, true);
      }
  }

  // Final Report
  console.log("\n--- Validation Report ---");
  console.log(`Total Files Checked: ${report.totalFilesChecked}`);
  console.log(`Total Scriptable Tips Parsed: ${report.totalTipsParsed}`);
  console.log(`Total Shared Handlers Parsed: ${report.totalSharedHandlers}`);
  console.log(`Categories Found: ${report.categoriesFound.size} (${Array.from(report.categoriesFound).sort().join(', ')})`);
  console.log(`Unique Tip IDs (total): ${report.uniqueTipIds.size}`);
  console.log(`  - From Local KB (new): ${report.localOnlyNewTipIds.size}`);
  console.log(`  - Overridden by Local KB: ${report.overriddenTipIdsLocal.length}`);
  console.log(`Unique Shared Handlers (total): ${report.sharedHandlerNames.size}`);
  console.log(`  - Overridden by Local KB: ${report.overriddenSharedHandlersLocal.length}`);

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

  if (report.duplicateTipIdsPrimary.length > 0) {
    console.warn(`\n--- DUPLICATE TIP IDs IN PRIMARY KB (${report.duplicateTipIdsPrimary.length}) ---`);
    console.warn("The following Tip IDs were duplicated in the primary KB. Ensure each explicit 'id' in frontmatter is unique, and filenames within categories also lead to unique generated IDs:");
    for (const id of report.duplicateTipIdsPrimary) {
        console.warn(`  - ${id}`);
    }
  }
  if (report.duplicateSharedHandlersPrimary.length > 0) {
    console.warn(`\n--- DUPLICATE SHARED HANDLERS IN PRIMARY KB (${report.duplicateSharedHandlersPrimary.length}) ---`);
    console.warn("The following Shared Handler names (name_language) were duplicated in the primary KB. Ensure unique names:");
    for (const id of report.duplicateSharedHandlersPrimary) {
        console.warn(`  - ${id}`);
    }
  }
  
  if (report.overriddenTipIdsLocal.length > 0) {
      console.info(`\n--- OVERRIDDEN TIPS BY LOCAL KB (${report.overriddenTipIdsLocal.length}) ---`);
      console.info("The following Tip IDs from the primary KB were overridden by a local version:");
      for (const id of report.overriddenTipIdsLocal.sort()) {
          console.info(`  - ${id}`);
      }
  }
   if (report.overriddenSharedHandlersLocal.length > 0) {
      console.info(`\n--- OVERRIDDEN SHARED HANDLERS BY LOCAL KB (${report.overriddenSharedHandlersLocal.length}) ---`);
      console.info("The following Shared Handlers from the primary KB were overridden by a local version:");
      for (const id of report.overriddenSharedHandlersLocal.sort()) {
          console.info(`  - ${id}`);
      }
  }

  console.log("\nValidation complete.");
  if (report.errors.length > 0 || report.duplicateTipIdsPrimary.length > 0 || report.duplicateSharedHandlersPrimary.length > 0) {
    process.exitCode = 1; // Indicate failure if primary KB has errors/duplicates
  }
}

// Run the validator
validateKnowledgeBase().catch(err => {
  console.error("Unhandled error during validation process:", err);
  process.exitCode = 1;
});