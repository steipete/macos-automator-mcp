import fs from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter';
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import { report, logErrorToReport, logWarningToReport, type _ValidationReport } from './kbReport.js';
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import type { _ScriptingTip, _KnowledgeBaseIndex } from '../src/services/scriptingKnowledge.types.js';
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import type { _Logger } from '../src/logger.js';

export interface TipFrontmatter {
  id?: string;
  title: string;
  category?: string;
  description?: string;
  keywords?: string[];
  language?: 'applescript' | 'javascript';
  isComplex?: boolean;
  argumentsPrompt?: string;
  notes?: string;
}

// The lintAndFixAppleScript function was commented out in the original validate-kb.ts.
// It's removed here for cleanliness. If needed, it can be added back from history.

/**
 * Helper function to validate the title in frontmatter
 */
function _validateTitle(frontmatter: TipFrontmatter, filePath: string, isLocalKb: boolean): boolean {
  if (!frontmatter.title || typeof frontmatter.title !== 'string' || frontmatter.title.trim() === "") {
    logErrorToReport(filePath, "Missing or empty 'title' in frontmatter.", isLocalKb);
    return false;
  }
  return true;
}

/**
 * Helper function to validate and register the tip ID
 */
function _validateAndRegisterTipId(
  frontmatterId: string | undefined, 
  filePath: string,
  categoryId: string,
  kbPath: string,
  isLocalKb: boolean
): string {
  const baseName = path.basename(filePath, '.md').replace(/^\d+[_.-]?\s*/, '').replace(/\s+/g, '_').toLowerCase();
  const relativeDirPath = path.dirname(path.relative(path.join(kbPath, categoryId), filePath));
  const pathPrefix = relativeDirPath && relativeDirPath !== '.' ? `${relativeDirPath.replace(/[\\/_]/g, '_')}_` : '';
  const generatedId = `${categoryId}_${pathPrefix}${baseName}`;
  const tipId = frontmatterId || generatedId;

  if (isLocalKb) {
    if (report.uniqueTipIds.has(tipId)) {
      if (!report.overriddenTipIdsLocal.includes(tipId)) {
        report.overriddenTipIdsLocal.push(tipId);
      }
      logWarningToReport(filePath, `Local tip with ID '${tipId}' overrides an existing tip from primary KB.`, true);
    } else {
      report.localOnlyNewTipIds.add(tipId);
      report.uniqueTipIds.add(tipId);
    }
  } else {
    if (report.uniqueTipIds.has(tipId)) {
      logErrorToReport(filePath, `Duplicate Tip ID detected or generated in primary KB: '${tipId}'. Explicitly set a unique 'id' in frontmatter or rename file.`, false);
      if (!report.duplicateTipIdsPrimary.includes(tipId)) {
        report.duplicateTipIdsPrimary.push(tipId);
      }
    } else {
      report.uniqueTipIds.add(tipId);
    }
  }
  
  return tipId;
}

/**
 * Helper function to validate the category in frontmatter
 */
function _validateCategory(frontmatter: TipFrontmatter, categoryId: string, filePath: string, isLocalKb: boolean): void {
  if (frontmatter.category && frontmatter.category !== categoryId) {
    logWarningToReport(filePath, `Frontmatter category '${frontmatter.category}' differs from directory category '${categoryId}'. Directory will be used.`, isLocalKb);
  }
}

/**
 * Helper function to validate the description in frontmatter
 */
function _validateDescription(frontmatter: TipFrontmatter, filePath: string, isLocalKb: boolean): void {
  if (!frontmatter.description || typeof frontmatter.description !== 'string' || frontmatter.description.trim().length < 10) {
    logWarningToReport(filePath, "Missing, empty, or very short 'description'.", isLocalKb);
  }
}

/**
 * Helper function to validate keywords in frontmatter
 */
function _validateKeywords(frontmatter: TipFrontmatter, filePath: string, isLocalKb: boolean): void {
  if (!frontmatter.keywords || !Array.isArray(frontmatter.keywords) || frontmatter.keywords.length === 0) {
    logWarningToReport(filePath, "Missing or empty 'keywords' array.", isLocalKb);
  } else if (frontmatter.keywords.some(kw => typeof kw !== 'string' || kw.trim() === "")) {
    logWarningToReport(filePath, "One or more keywords are not strings or are empty.", isLocalKb);
  }
}

/**
 * Helper function to validate language in frontmatter
 */
function _validateLanguage(frontmatter: TipFrontmatter, filePath: string, isLocalKb: boolean): 'applescript' | 'javascript' | null {
  const defaultLanguage = 'applescript';
  const lang = frontmatter.language || defaultLanguage;
  
  if (!['applescript', 'javascript'].includes(lang)) {
    logErrorToReport(filePath, `Invalid language '${lang}' in frontmatter. Must be 'applescript' or 'javascript'.`, isLocalKb);
    return null;
  }
  
  return lang as 'applescript' | 'javascript';
}

/**
 * Helper function to validate script block in markdown body
 */
function _validateScriptBlock(
  markdownBody: string, 
  expectedLanguage: string, 
  filePath: string, 
  isLocalKb: boolean
): { scriptContent?: string, scriptBlockLanguage?: string } {
  const scriptBlockRegex = /```(applescript|javascript)\s*\n([\s\S]*?)\n```/i;
  const scriptMatch = markdownBody.match(scriptBlockRegex);
  let scriptContent: string | undefined;
  let scriptBlockLanguage: string | undefined;

  if (!scriptMatch || !scriptMatch[2] || scriptMatch[2].trim() === "") {
    if (expectedLanguage === 'applescript' || expectedLanguage === 'javascript') {
      logWarningToReport(filePath, `No script block found or script block is empty, but language is '${expectedLanguage}'. Is this a conceptual tip?`, isLocalKb);
    }
  } else {
    scriptBlockLanguage = scriptMatch[1].toLowerCase();
    scriptContent = scriptMatch[2].trim();

    if (scriptBlockLanguage !== expectedLanguage) {
      logWarningToReport(filePath, `Frontmatter language ('${expectedLanguage}') differs from script block language ('${scriptBlockLanguage}'). Code block language will be used.`, isLocalKb);
    }
  }

  return { scriptContent, scriptBlockLanguage };
}

/**
 * Helper function to validate complex arguments settings vs script content
 */
function _validateComplexArguments(frontmatter: TipFrontmatter, scriptContent: string | undefined, filePath: string, isLocalKb: boolean): void {
  if (frontmatter.isComplex && !frontmatter.argumentsPrompt && scriptContent?.includes('--MCP_')) {
    logWarningToReport(filePath, "'isComplex: true' and script contains MCP placeholders, but 'argumentsPrompt' is missing in frontmatter.", isLocalKb);
  }
  
  if (frontmatter.argumentsPrompt && !scriptContent?.includes('--MCP_')) {
    logWarningToReport(filePath, "'argumentsPrompt' is provided, but no --MCP_INPUT or --MCP_ARG_ placeholders found in script.", isLocalKb);
  }
}

export async function validateTipFile(filePath: string, categoryId: string, kbPath: string, isLocalKb: boolean): Promise<void> {
  report.totalFilesChecked++;
  const fileContent = await fs.readFile(filePath, 'utf-8');
  const { data, content: markdownBody } = matter(fileContent, { excerpt: true });
  const frontmatter = data as TipFrontmatter;

  // Validate title - exit early if invalid
  if (!_validateTitle(frontmatter, filePath, isLocalKb)) {
    return;
  }

  // Validate and register tip ID
  _validateAndRegisterTipId(frontmatter.id, filePath, categoryId, kbPath, isLocalKb);
  
  // Record the successful parse in the report
  report.totalTipsParsed++;
  report.categoriesFound.add(categoryId);

  // Validate remaining frontmatter fields
  _validateCategory(frontmatter, categoryId, filePath, isLocalKb);
  _validateDescription(frontmatter, filePath, isLocalKb);
  _validateKeywords(frontmatter, filePath, isLocalKb);
  
  // Validate language
  const validatedLanguage = _validateLanguage(frontmatter, filePath, isLocalKb);
  if (!validatedLanguage) {
    return; // Exit if language is invalid
  }
  
  // Validate script block
  const { scriptContent } = _validateScriptBlock(markdownBody, validatedLanguage, filePath, isLocalKb);
  
  // Validate complex arguments and placeholders
  _validateComplexArguments(frontmatter, scriptContent, filePath, isLocalKb);
}

export async function validateSharedHandlerFile(filePath: string, isLocalKb: boolean): Promise<void> {
    report.totalFilesChecked++;
    const fileName = path.basename(filePath);
    const handlerName = path.basename(fileName, path.extname(fileName));
    const language = fileName.endsWith('.js') ? 'javascript' : 'applescript';
    const handlerIdentifier = `${handlerName}_${language}`;

    try {
        const content = await fs.readFile(filePath, 'utf-8');
        if (content.trim() === "") {
            logWarningToReport(filePath, "Shared handler file is empty.", isLocalKb);
        }

        if (isLocalKb) {
            if (report.sharedHandlerNames.has(handlerIdentifier)) {
                if (!report.overriddenSharedHandlersLocal.includes(handlerIdentifier)) {
                    report.overriddenSharedHandlersLocal.push(handlerIdentifier);
                }
                logWarningToReport(filePath, `Local shared handler '${handlerIdentifier}' overrides an existing one.`, true);
            } else {
                report.sharedHandlerNames.add(handlerIdentifier);
            }
        } else { 
            if (report.sharedHandlerNames.has(handlerIdentifier)) {
                logErrorToReport(filePath, `Duplicate shared handler detected in primary KB: '${handlerIdentifier}'. Rename to ensure uniqueness.`, false);
                if (!report.duplicateSharedHandlersPrimary.includes(handlerIdentifier)) {
                    report.duplicateSharedHandlersPrimary.push(handlerIdentifier);
                }
            } else {
                report.sharedHandlerNames.add(handlerIdentifier);
            }
        }
        report.totalSharedHandlers++;
    } catch (error: unknown) {
        if (error instanceof Error) {
            logErrorToReport(filePath, `Failed to read shared handler file: ${error.message}`, isLocalKb);
        } else {
            logErrorToReport(filePath, "Failed to read shared handler file: Unknown error occurred", isLocalKb);
        }
    }
}