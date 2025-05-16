// src/services/knowledgeBaseService.ts
// Old content is largely removed and replaced.
// We now import KB management from KnowledgeBaseManager.ts
// and getScriptingTipsService is refactored with internal helpers.

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

// Re-export the core KB access functions for server.ts to use
export { getKnowledgeBase, forceReloadKnowledgeBase, conditionallyInitializeKnowledgeBase };

// --- Helper functions for getScriptingTipsService --- 

function searchTips(tipsToSearch: ScriptingTip[], searchTerm: string): ScriptingTip[] {
  if (!searchTerm) {
    // If no search term, return all tips, sorted by title for consistency
    return [...tipsToSearch].sort((a, b) => a.title.localeCompare(b.title));
  }

  const fuseOptions = {
    isCaseSensitive: false,
    includeScore: false,
    shouldSort: true, // Fuse.js will sort by relevance
    threshold: 0.4,
    keys: [
      { name: 'title', weight: 0.4 },
      { name: 'id', weight: 0.3 },
      { name: 'keywords', weight: 0.2 },
      { name: 'description', weight: 0.1 },
      { name: 'script', weight: 0.05 }
    ]
  };
  const fuse = new Fuse(tipsToSearch, fuseOptions);
  return fuse.search(searchTerm).map(result => result.item);
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
      const categoryTitle = (catResult.category as string).replace(/_/g, ' ').replace(/\b\w/g, (l: string) => l.toUpperCase());
      // Only add category header if we are not already in a specific category view (i.e., input.category was not set)
      const categoryHeader = inputCategory ? '' : `## Tips: ${categoryTitle}\n`; 
      const tipMarkdown = catResult.tips.map(tip => `
### ${tip.title}
${tip.description ? `*${tip.description}*\n` : ''}
\`\`\`${tip.language}
${tip.script.trim()}
\`\`\`
${tip.id ? `**Runnable ID:** \`${tip.id}\`\n` : ''}
${tip.argumentsPrompt ? `**Inputs Needed (if run by ID):** ${tip.argumentsPrompt}\n` : ''}
${tip.keywords && tip.keywords.length > 0 ? `**Keywords:** ${tip.keywords.join(', ')}\n` : ''}
${tip.notes ? `**Note:**\n${tip.notes.split('\n').map(n => `> ${n}`).join('\n')}\n` : ''}
      `).join('\n---\n');
      return categoryHeader + tipMarkdown;
    }).join('\n\n');
}

// --- Main Service Function --- 

export async function getScriptingTipsService(
  input: GetScriptingTipsInput,
  serverInfo?: { startTime: string; mode: string }
): Promise<string> {
  if (input.refreshDatabase) {
    await forceReloadKnowledgeBase(); // Uses imported function
  }
  const kb: KnowledgeBaseIndex = await getKnowledgeBase(); // Uses imported function

  let serverInfoString = "";
  if (serverInfo) {
    serverInfoString = `\n\n---\nServer Started: ${serverInfo.startTime}\nExecution Mode: ${serverInfo.mode}`;
  }

  if (input.listCategories || (!input.category && !input.searchTerm)) {
    let message: string;
    if (kb.categories.length === 0) {
      message = "No tip categories available. Knowledge base might be empty or failed to load.";
    } else {
      const categoryList = kb.categories
        .map(cat => `- **${cat.id}**: ${cat.description} (${cat.tipCount} tips)`)
        .join('\n');
      message = `## Available AppleScript/JXA Tip Categories:\n${categoryList}\n\nUse \`category: "category_name"\` to get specific tips, or \`searchTerm: "keyword"\` to search. Tips with a runnable ID can be executed directly via the \`execute_script\` tool.`;
    }
    return message + serverInfoString;
  }

  const searchTermLower = input.searchTerm?.toLowerCase() ?? '';
  
  // Determine the initial set of tips to consider (either all tips or tips from a specific category)
  const tipsToConsider: ScriptingTip[] = input.category
    ? kb.tips.filter((t: ScriptingTip) => t.category === input.category)
    : kb.tips;

  // Filter tips using the search term (if provided)
  const filteredTips: ScriptingTip[] = searchTips(tipsToConsider, searchTermLower);

  let outputMessage: string;
  if (filteredTips.length === 0) {
    outputMessage = `No tips found matching your criteria (Category: ${input.category || 'All Categories'}, SearchTerm: ${input.searchTerm || 'None'}). Try \`listCategories: true\` to see available categories.`;
  } else {
    const resultsToFormat: { category: KnowledgeCategory; tips: ScriptingTip[] }[] = [];
    if (input.category) {
      // If already filtered by a category, all filteredTips belong to this single category
      if (filteredTips.length > 0) {
         resultsToFormat.push({ category: input.category as KnowledgeCategory, tips: filteredTips });
      }
    } else {
      // If not pre-filtered by category, group the search results by their respective categories
      const groupedByCat: Record<string, ScriptingTip[]> = filteredTips.reduce((acc, tip) => {
        const catKey = tip.category as string;
        if (!acc[catKey]) acc[catKey] = [];
        acc[catKey].push(tip);
        return acc;
      }, {} as Record<string, ScriptingTip[]>);

      for (const catKey of Object.keys(groupedByCat)) {
        resultsToFormat.push({ category: catKey as KnowledgeCategory, tips: groupedByCat[catKey] });
      }
    }
    // Format the results into markdown. Pass input.category to conditionally hide category headers.
    const formattedTips = formatResultsToMarkdown(resultsToFormat, input.category as KnowledgeCategory | undefined);
    if (formattedTips === "") { // Should only happen if resultsToFormat was empty but filteredTips was not (edge case)
        outputMessage = `No tips found matching your criteria (Category: ${input.category || 'All Categories'}, SearchTerm: ${input.searchTerm || 'None'}). Try \`listCategories: true\` to see available categories.`;
    } else {
        outputMessage = formattedTips;
    }
  }
  return outputMessage + serverInfoString;
}

// Ensure all old function definitions (parseMarkdownTipFile, getLocalKnowledgeBasePath, loadKnowledgeBaseFromPath, 
// findTipsRecursively, actualLoadAndIndexKnowledgeBase, and the old versions of getKnowledgeBase, 
// forceReloadKnowledgeBase, conditionallyInitializeKnowledgeBase) are GONE from this file.
