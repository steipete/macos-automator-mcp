// src/services/knowledgeBaseService.ts
// Service for accessing and searching the scripting knowledge base.

import type { GetScriptingTipsInput } from '../schemas.js';
import { Logger } from '../logger.js';
import Fuse from 'fuse.js';
import {
  getKnowledgeBase,
  forceReloadKnowledgeBase,
  conditionallyInitializeKnowledgeBase
} from './KnowledgeBaseManager.js'; // Import from the new manager
import type { KnowledgeBaseIndex, ScriptingTip, KnowledgeCategory } from './scriptingKnowledge.types.js';

const logger = new Logger('KnowledgeBaseService');

// --- Constants ---
const PRIMARY_SEARCH_THRESHOLD = 0.4;
const BROAD_SEARCH_THRESHOLD = 0.7;
const MAX_OUTPUT_LINES = 500; // New constant for max output lines
const DEFAULT_TIP_LIMIT = 10; // Default limit for tips

const FUSE_OPTIONS_KEYS = [
  { name: 'title', weight: 0.4 },
  { name: 'id', weight: 0.3 },
  { name: 'keywords', weight: 0.2 },
  { name: 'description', weight: 0.1 },
  { name: 'script', weight: 0.05 }
];

// Re-export the core KB access functions for server.ts to use
export { getKnowledgeBase, forceReloadKnowledgeBase, conditionallyInitializeKnowledgeBase };

function searchTips(tipsToSearch: ScriptingTip[], searchTerm: string, customThreshold?: number): ScriptingTip[] {
  if (!searchTerm) {
    return [...tipsToSearch].sort((a, b) => a.title.localeCompare(b.title));
  }

  const fuseOptions = {
    isCaseSensitive: false,
    includeScore: false,
    shouldSort: true,
    threshold: customThreshold !== undefined ? customThreshold : PRIMARY_SEARCH_THRESHOLD, // Use custom or default
    keys: FUSE_OPTIONS_KEYS
  };
  const fuse = new Fuse(tipsToSearch, fuseOptions);
  return fuse.search(searchTerm).map(result => result.item);
}

function formatCategoryTitle(category: string): string {
  return category.replace(/_/g, ' ').replace(/\b\w/g, (l: string) => l.toUpperCase());
}

function generateNoResultsMessage(category?: string, searchTerm?: string): string {
  return `No tips found matching your criteria (Category: ${category || 'All Categories'}, SearchTerm: ${searchTerm || 'None'}). Try \`listCategories: true\` to see available categories.`;
}

// New helper function to format a single tip to its Markdown block
function formatSingleTipToMarkdownBlock(tip: ScriptingTip): string {
  return `
### ${tip.title}
${tip.description ? `*${tip.description}*\n` : ''}
\`\`\`${tip.language}
${tip.script.trim()}
\`\`\`
${tip.id ? `**Runnable ID:** \`${tip.id}\`\n` : ''}
${tip.argumentsPrompt ? `**Inputs Needed (if run by ID):** ${tip.argumentsPrompt}\n` : ''}
${tip.keywords && tip.keywords.length > 0 ? `**Keywords:** ${tip.keywords.join(', ')}\n` : ''}
${tip.notes ? `**Note:**\n${tip.notes.split('\n').map(n => `> ${n}`).join('\n')}\n` : ''}
`;
}

function formatResultsToMarkdown(
    groupedResults: { category: KnowledgeCategory; tips: ScriptingTip[] }[],
    inputCategory?: KnowledgeCategory | string // Allow string for input.category
): { markdownOutput: string; lineLimitNotice: string; tipsRenderedCount: number } { // Updated return type
  if (groupedResults.length === 0) {
    return { markdownOutput: "", lineLimitNotice: "", tipsRenderedCount: 0 };
  }

  let cumulativeLineCount = 0;
  let lineLimitNotice = "";
  const outputParts: string[] = [];
  let tipsRenderedCount = 0;
  let firstTipRendered = false;

  for (const catResult of groupedResults.sort((a, b) => (a.category as string).localeCompare(b.category as string))) {
    if (lineLimitNotice) break; // Stop if limit was already hit in a previous category

    const categoryTitle = formatCategoryTitle(catResult.category as string);
    const categoryHeader = inputCategory ? '' : `## Tips: ${categoryTitle}\n`;
    const categoryHeaderLines = categoryHeader.split('\n').length -1; // -1 because split creates one extra for trailing newline

    // Check if category header itself can be added (only if not the first tip overall or if it fits)
    if (firstTipRendered && cumulativeLineCount + categoryHeaderLines > MAX_OUTPUT_LINES) {
        lineLimitNotice = `\n--- Output truncated due to exceeding ~${MAX_OUTPUT_LINES} line limit. ---`;
        break;
    }
    if (categoryHeader) {
        outputParts.push(categoryHeader);
        cumulativeLineCount += categoryHeaderLines;
    }

    for (let i = 0; i < catResult.tips.length; i++) {
      const tip = catResult.tips[i];
      const tipMarkdown = formatSingleTipToMarkdownBlock(tip);
      const tipLines = tipMarkdown.split('\n').length - 1;
      const separator = (tipsRenderedCount > 0 || (tipsRenderedCount === 0 && categoryHeader)) ? '\n---\n' : ''; // Add separator if not the very first item
      const separatorLines = separator.split('\n').length -1;

      if (!firstTipRendered) {
        // Always render the first tip, regardless of its length
        if (separator) outputParts.push(separator);
        outputParts.push(tipMarkdown);
        cumulativeLineCount += separatorLines + tipLines;
        tipsRenderedCount++;
        firstTipRendered = true;
      } else if (cumulativeLineCount + separatorLines + tipLines <= MAX_OUTPUT_LINES) {
        if (separator) outputParts.push(separator);
        outputParts.push(tipMarkdown);
        cumulativeLineCount += separatorLines + tipLines;
        tipsRenderedCount++;
      } else {
        lineLimitNotice = `\n--- Output truncated due to exceeding ~${MAX_OUTPUT_LINES} line limit. Some tips may have been omitted. ---`;
        break; // Stop adding more tips from this category
      }
    }
  }
  return { markdownOutput: outputParts.join(''), lineLimitNotice, tipsRenderedCount };
}

// --- Helper Functions for getScriptingTipsService ---

function handleListCategories(kb: KnowledgeBaseIndex, version?: string): string {
  if (kb.categories.length === 0) {
    return "No tip categories available. Knowledge base might be empty or failed to load.";
  }
  const categoryList = kb.categories
    .map(cat => `- **${cat.id}**: ${cat.description} (${cat.tipCount} tips)`)
    .join('\n');

  const totalTipCount = kb.categories.reduce((sum, cat) => sum + (cat.tipCount || 0), 0);
  const versionString = version ? `\nmacos_automator version: ${version}` : "";

  return `## Available AppleScript/JXA Tip Categories:${versionString}\n${categoryList}\n\nTotal Scripts Available: ${totalTipCount}\nVisit https://github.com/steipete/macos-automator-mcp to contribute your AppleScripts\n\nUse \`category: "category_name"\` to get specific tips, or \`searchTerm: "keyword"\` to search. Tips with a runnable ID can be executed directly via the \`execute_script\` tool.`;
}

interface SearchResult {
  tips: ScriptingTip[];
  notice: string;
}

function performSearch(kb: KnowledgeBaseIndex, category?: string, searchTerm?: string): SearchResult {
  const searchTermLower = searchTerm?.toLowerCase() ?? '';
  const tipsToConsider: ScriptingTip[] = category
    ? kb.tips.filter((t: ScriptingTip) => t.category === category)
    : kb.tips;

  let filteredTips: ScriptingTip[] = searchTips(tipsToConsider, searchTermLower, PRIMARY_SEARCH_THRESHOLD);
  let broadSearchNotice = "";

  if (filteredTips.length === 0 && searchTermLower) {
    logger.debug('Primary search yielded no results, trying broader search.', { searchTerm: searchTermLower, category });
    filteredTips = searchTips(tipsToConsider, searchTermLower, BROAD_SEARCH_THRESHOLD);
    if (filteredTips.length > 0) {
      broadSearchNotice = `No direct matches found. The following tips are potentially relevant based on a broader search (threshold: ${BROAD_SEARCH_THRESHOLD}):\n\n`;
      logger.debug('Broad search yielded results.', { count: filteredTips.length });
    }
  }
  return { tips: filteredTips, notice: broadSearchNotice };
}

function groupTipsByCategory(tips: ScriptingTip[], specificCategory?: string): { category: KnowledgeCategory; tips: ScriptingTip[] }[] {
  const resultsToFormat: { category: KnowledgeCategory; tips: ScriptingTip[] }[] = [];
  if (specificCategory) {
    if (tips.length > 0) {
      resultsToFormat.push({ category: specificCategory as KnowledgeCategory, tips });
    }
  } else {
    const groupedByCat: Record<string, ScriptingTip[]> = tips.reduce((acc, tip) => {
      const catKey = tip.category as string;
      if (!acc[catKey]) acc[catKey] = [];
      acc[catKey].push(tip);
      return acc;
    }, {} as Record<string, ScriptingTip[]>);

    for (const catKey of Object.keys(groupedByCat)) {
      resultsToFormat.push({ category: catKey as KnowledgeCategory, tips: groupedByCat[catKey] });
    }
  }
  return resultsToFormat;
}

// --- Main Service Function (Refactored) --- 

export async function getScriptingTipsService(
  input: GetScriptingTipsInput,
  serverInfo?: { startTime: string; mode: string; version?: string }
): Promise<string> {
  if (input.refreshDatabase) {
    await forceReloadKnowledgeBase();
  }
  const kb: KnowledgeBaseIndex = await getKnowledgeBase();

  let serverDetailsString = "";
  if (serverInfo) {
    const versionInfo = serverInfo.version ? ` Version: ${serverInfo.version}` : "";
    serverDetailsString = `\n\n---\nServer Started: ${serverInfo.startTime}\nExecution Mode: ${serverInfo.mode}${versionInfo}`;
  }

  // Handle listCategories separately as it overrides other filters and limit
  if (input.listCategories || (!input.category && !input.searchTerm && !input.limit)) {
    if (input.listCategories || (!input.category && !input.searchTerm)) {
        const listCategoriesMessage = handleListCategories(kb, serverInfo?.version);
        return listCategoriesMessage + serverDetailsString;
    }
    if(input.limit && !input.category && !input.searchTerm){
        const listCategoriesMessage = handleListCategories(kb, serverInfo?.version);
        return `${listCategoriesMessage}\n\nNote: \`limit\` parameter is applied to search results or category browsing, not general listing.${serverDetailsString}`;
    }
  }

  const searchResult = performSearch(kb, input.category, input.searchTerm);
  let noticeAboutLimit = "";
  const actualLimit = input.limit || DEFAULT_TIP_LIMIT; 

  if (!input.listCategories && (input.searchTerm || input.category) && searchResult.tips.length > 0) {
    if (searchResult.tips.length > actualLimit) {
      noticeAboutLimit = `Showing the first ${actualLimit} of ${searchResult.tips.length} matching tips. Use the \`limit\` parameter to adjust this. (Default is 10).\n\n`;
      searchResult.tips = searchResult.tips.slice(0, actualLimit);
    }
  }

  if (searchResult.tips.length === 0 && !input.listCategories) { 
    const noResultsMessage = generateNoResultsMessage(input.category, input.searchTerm);
    return noResultsMessage + serverDetailsString;
  }

  const categorizedTips = groupTipsByCategory(searchResult.tips, input.category);
  const formattingResult = formatResultsToMarkdown(categorizedTips, input.category as KnowledgeCategory | undefined);
  const formattedTips = formattingResult.markdownOutput;
  const lineLimitNotice = formattingResult.lineLimitNotice;

  let outputMessage: string;
  if (formattedTips.trim() === "") { 
      if (input.listCategories || (!input.category && !input.searchTerm)) { // Avoid double no-results message if categories were shown
        outputMessage = ""; // Categories were already listed, or will be if no other criteria met
      } else {
        logger.warn('Formatted tips were empty despite having search results (after potential limit).',{input, searchResultTipsCount: searchResult.tips.length});
        outputMessage = generateNoResultsMessage(input.category, input.searchTerm) + serverDetailsString;
      }
  } else {
      outputMessage = searchResult.notice + noticeAboutLimit + lineLimitNotice + formattedTips;
  }
  
  // If we reached here and outputMessage is empty (e.g. only limit was specified), default to listCategories
  if (outputMessage.trim() === "" && !input.listCategories && !(input.searchTerm || input.category) ) {
    const listCategoriesMessage = handleListCategories(kb, serverInfo?.version);
    return `${listCategoriesMessage}\n\nNote: \`limit\` parameter applies to search results or category browsing.${serverDetailsString}`;
  }

  if (input.refreshDatabase) {
    outputMessage = `Knowledge base reloaded successfully.${serverDetailsString}\n\n${outputMessage}`;
  } else if (!outputMessage.includes(serverDetailsString) && outputMessage.trim() !== "" && !input.listCategories) {
    // If not refresh, details not already in message, message not empty, and not listCategories (which handles its own details)
    // This is to catch normal search results that didn't go through refresh/listCategories/noResults paths for serverDetailsString
    outputMessage += serverDetailsString;
  }

  return outputMessage;
}