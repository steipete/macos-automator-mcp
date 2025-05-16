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

function formatResultsToMarkdown(
    groupedResults: { category: KnowledgeCategory; tips: ScriptingTip[] }[],
    inputCategory?: KnowledgeCategory | string // Allow string for input.category
): string {
  if (groupedResults.length === 0) {
    return ""; // Caller will prepend a more specific message
  }
  return groupedResults
    .sort((a, b) => (a.category as string).localeCompare(b.category as string))
    .map(catResult => {
      const categoryTitle = formatCategoryTitle(catResult.category as string);
      // Only add category header if we are not already in a specific category view (i.e., input.category was not set)
      const categoryHeader = inputCategory ? '' : `## Tips: ${categoryTitle}\\n`;
      const tipMarkdown = catResult.tips.map(tip => `
### ${tip.title}
${tip.description ? `*${tip.description}*\\n` : ''}
\`\`\`${tip.language}
${tip.script.trim()}
\`\`\`
${tip.id ? `**Runnable ID:** \`${tip.id}\`\\n` : ''}
${tip.argumentsPrompt ? `**Inputs Needed (if run by ID):** ${tip.argumentsPrompt}\\n` : ''}
${tip.keywords && tip.keywords.length > 0 ? `**Keywords:** ${tip.keywords.join(', ')}\\n` : ''}
${tip.notes ? `**Note:**\\n${tip.notes.split('\\n').map(n => `> ${n}`).join('\\n')}\\n` : ''}
      `).join('\\n---\\n');
      return categoryHeader + tipMarkdown;
    }).join('\\n\\n');
}

// --- Helper Functions for getScriptingTipsService ---

function handleListCategories(kb: KnowledgeBaseIndex): string {
  if (kb.categories.length === 0) {
    return "No tip categories available. Knowledge base might be empty or failed to load.";
  }
  const categoryList = kb.categories
    .map(cat => `- **${cat.id}**: ${cat.description} (${cat.tipCount} tips)`)
    .join('\n');
  return `## Available AppleScript/JXA Tip Categories:\n${categoryList}\n\nUse \`category: "category_name"\` to get specific tips, or \`searchTerm: "keyword"\` to search. Tips with a runnable ID can be executed directly via the \`execute_script\` tool.`;
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
  serverInfo?: { startTime: string; mode: string }
): Promise<string> {
  if (input.refreshDatabase) {
    await forceReloadKnowledgeBase();
  }
  const kb: KnowledgeBaseIndex = await getKnowledgeBase();

  let serverInfoString = "";
  if (serverInfo) {
    serverInfoString = `\n\n---\nServer Started: ${serverInfo.startTime}\nExecution Mode: ${serverInfo.mode}`;
  }

  if (input.listCategories || (!input.category && !input.searchTerm)) {
    const listCategoriesMessage = handleListCategories(kb);
    return listCategoriesMessage + serverInfoString;
  }

  const searchResult = performSearch(kb, input.category, input.searchTerm);

  if (searchResult.tips.length === 0) {
    const noResultsMessage = generateNoResultsMessage(input.category, input.searchTerm);
    return noResultsMessage + serverInfoString;
  }

  const categorizedTips = groupTipsByCategory(searchResult.tips, input.category);
  const formattedTips = formatResultsToMarkdown(categorizedTips, input.category as KnowledgeCategory | undefined);

  let outputMessage: string;
  if (formattedTips.trim() === "") { // Should ideally not happen if searchResult.tips had items
      logger.warn('Formatted tips were empty despite having search results.', {input, searchResultTipsCount: searchResult.tips.length});
      outputMessage = generateNoResultsMessage(input.category, input.searchTerm);
  } else {
      outputMessage = searchResult.notice + formattedTips;
  }
  
  return outputMessage + serverInfoString;
}