import type { GetScriptingTipsInput } from "../schemas.js";
import { Logger } from "../logger.js";
import Fuse from "fuse.js";
import {
  getKnowledgeBase,
  forceReloadKnowledgeBase,
  conditionallyInitializeKnowledgeBase,
} from "./KnowledgeBaseManager.js";
import type {
  KnowledgeBaseIndex,
  ScriptingTip,
  KnowledgeCategory,
} from "./scriptingKnowledge.types.js";

const logger = new Logger("KnowledgeBaseService");

const PRIMARY_SEARCH_THRESHOLD = 0.4;
const BROAD_SEARCH_THRESHOLD = 0.7;
const MAX_OUTPUT_LINES = 500;
const DEFAULT_TIP_LIMIT = 10;

const FUSE_OPTIONS_KEYS = [
  { name: "title", weight: 0.4 },
  { name: "id", weight: 0.3 },
  { name: "keywords", weight: 0.2 },
  { name: "description", weight: 0.1 },
  { name: "script", weight: 0.05 },
];

export { getKnowledgeBase, forceReloadKnowledgeBase, conditionallyInitializeKnowledgeBase };

function searchTips(
  tipsToSearch: ScriptingTip[],
  searchTerm: string,
  customThreshold?: number,
): ScriptingTip[] {
  if (!searchTerm) {
    return [...tipsToSearch].sort((a, b) => a.title.localeCompare(b.title));
  }

  const fuseOptions = {
    isCaseSensitive: false,
    includeScore: false,
    shouldSort: true,
    threshold: customThreshold ?? PRIMARY_SEARCH_THRESHOLD,
    keys: FUSE_OPTIONS_KEYS,
  };
  const fuse = new Fuse(tipsToSearch, fuseOptions);
  return fuse.search(searchTerm).map((result) => result.item);
}

function formatCategoryTitle(category: string): string {
  return category.replace(/_/g, " ").replace(/\b\w/g, (l: string) => l.toUpperCase());
}

function generateNoResultsMessage(category?: string, searchTerm?: string): string {
  return `No tips found matching your criteria (Category: ${category || "All Categories"}, SearchTerm: ${searchTerm || "None"}). Try \`list_categories: true\` to see available categories.`;
}

function formatSingleTipToMarkdownBlock(tip: ScriptingTip): string {
  return `
### ${tip.title}
${tip.description ? `*${tip.description}*\n` : ""}
\`\`\`${tip.language}
${tip.script.trim()}
\`\`\`
${tip.id ? `**Runnable ID:** \`${tip.id}\`\n` : ""}
${tip.argumentsPrompt ? `**Inputs Needed (if run by ID):** ${tip.argumentsPrompt}\n` : ""}
${tip.keywords && tip.keywords.length > 0 ? `**Keywords:** ${tip.keywords.join(", ")}\n` : ""}
${
  tip.notes
    ? `**Note:**\n${tip.notes
        .split("\n")
        .map((n) => `> ${n}`)
        .join("\n")}\n`
    : ""
}
`;
}

function formatResultsToMarkdown(
  groupedResults: { category: KnowledgeCategory; tips: ScriptingTip[] }[],
  inputCategory?: KnowledgeCategory,
): { markdownOutput: string; lineLimitNotice: string; tipsRenderedCount: number } {
  if (groupedResults.length === 0) {
    return { markdownOutput: "", lineLimitNotice: "", tipsRenderedCount: 0 };
  }

  let cumulativeLineCount = 0;
  let lineLimitNotice = "";
  const outputParts: string[] = [];
  let tipsRenderedCount = 0;

  for (const catResult of groupedResults.sort((a, b) => a.category.localeCompare(b.category))) {
    if (lineLimitNotice) break; // Stop if limit was already hit in a previous category

    const categoryTitle = formatCategoryTitle(catResult.category);
    const categoryHeader = inputCategory ? "" : `## Tips: ${categoryTitle}\n`;
    const categoryHeaderLines = categoryHeader.split("\n").length - 1; // -1 because split creates one extra for trailing newline

    if (tipsRenderedCount > 0 && cumulativeLineCount + categoryHeaderLines > MAX_OUTPUT_LINES) {
      lineLimitNotice = `\n--- Output truncated due to exceeding ~${MAX_OUTPUT_LINES} line limit. ---`;
      break;
    }
    if (categoryHeader) {
      outputParts.push(categoryHeader);
      cumulativeLineCount += categoryHeaderLines;
    }

    for (const tip of catResult.tips) {
      const tipMarkdown = formatSingleTipToMarkdownBlock(tip);
      const tipLines = tipMarkdown.split("\n").length - 1;
      const separator = tipsRenderedCount > 0 || categoryHeader ? "\n---\n" : ""; // Add separator if not the very first item
      const separatorLines = separator.split("\n").length - 1;

      // Keep the first tip intact even when it exceeds the output budget.
      if (
        tipsRenderedCount > 0 &&
        cumulativeLineCount + separatorLines + tipLines > MAX_OUTPUT_LINES
      ) {
        lineLimitNotice = `\n--- Output truncated due to exceeding ~${MAX_OUTPUT_LINES} line limit. Some tips may have been omitted. ---`;
        break;
      }
      if (separator) outputParts.push(separator);
      outputParts.push(tipMarkdown);
      cumulativeLineCount += separatorLines + tipLines;
      tipsRenderedCount++;
    }
  }
  return { markdownOutput: outputParts.join(""), lineLimitNotice, tipsRenderedCount };
}

function handleListCategories(kb: KnowledgeBaseIndex, version?: string): string {
  if (kb.categories.length === 0) {
    return "No tip categories available. Knowledge base might be empty or failed to load.";
  }
  const categoryList = kb.categories
    .map((cat) => `- **${cat.id}**: ${cat.description} (${cat.tipCount} tips)`)
    .join("\n");

  const totalTipCount = kb.categories.reduce((sum, cat) => sum + (cat.tipCount || 0), 0);
  const versionString = version ? `\nmacos_automator version: ${version}` : "";

  return `## Available AppleScript/JXA Tip Categories:${versionString}\n${categoryList}\n\nTotal Scripts Available: ${totalTipCount}\nVisit https://github.com/steipete/macos-automator-mcp to contribute your AppleScripts\n\nUse \`category: "category_name"\` to get specific tips, or \`search_term: "keyword"\` to search. Tips with a runnable ID can be executed directly via the \`execute_script\` tool.`;
}

interface SearchResult {
  tips: ScriptingTip[];
  notice: string;
}

function performSearch(
  kb: KnowledgeBaseIndex,
  category?: string,
  searchTerm?: string,
): SearchResult {
  const searchTermLower = searchTerm?.toLowerCase() ?? "";
  const tipsToConsider: ScriptingTip[] = category
    ? kb.tips.filter((t: ScriptingTip) => t.category === category)
    : kb.tips;

  let filteredTips: ScriptingTip[] = searchTips(
    tipsToConsider,
    searchTermLower,
    PRIMARY_SEARCH_THRESHOLD,
  );
  let broadSearchNotice = "";

  if (filteredTips.length === 0 && searchTermLower) {
    logger.debug("Primary search yielded no results, trying broader search.", {
      searchTerm: searchTermLower,
      category,
    });
    filteredTips = searchTips(tipsToConsider, searchTermLower, BROAD_SEARCH_THRESHOLD);
    if (filteredTips.length > 0) {
      broadSearchNotice = `No direct matches found. The following tips are potentially relevant based on a broader search (threshold: ${BROAD_SEARCH_THRESHOLD}):\n\n`;
      logger.debug("Broad search yielded results.", { count: filteredTips.length });
    }
  }
  return { tips: filteredTips, notice: broadSearchNotice };
}

function groupTipsByCategory(
  tips: ScriptingTip[],
  specificCategory?: string,
): { category: KnowledgeCategory; tips: ScriptingTip[] }[] {
  if (specificCategory) return tips.length ? [{ category: specificCategory, tips }] : [];
  return Array.from(
    Map.groupBy(tips, (tip) => tip.category),
    ([category, tips]) => ({ category, tips }),
  );
}

export async function getScriptingTipsService(
  input: GetScriptingTipsInput,
  serverInfo?: { startTime: string; mode: string; version?: string },
): Promise<string> {
  if (input.refresh_database) {
    await forceReloadKnowledgeBase();
  }
  const kb: KnowledgeBaseIndex = await getKnowledgeBase();

  let serverDetailsString = "";
  if (serverInfo) {
    const versionInfo = serverInfo.version ? ` Version: ${serverInfo.version}` : "";
    serverDetailsString = `\n\n---\nServer Started: ${serverInfo.startTime}\nExecution Mode: ${serverInfo.mode}${versionInfo}`;
  }

  if (input.list_categories || (!input.category && !input.search_term)) {
    return handleListCategories(kb, serverInfo?.version) + serverDetailsString;
  }

  const searchResult = performSearch(kb, input.category, input.search_term);
  let noticeAboutLimit = "";
  const actualLimit = input.limit || DEFAULT_TIP_LIMIT;

  if ((input.search_term || input.category) && searchResult.tips.length > 0) {
    if (searchResult.tips.length > actualLimit) {
      noticeAboutLimit = `Showing the first ${actualLimit} of ${searchResult.tips.length} matching tips. Use the \`limit\` parameter to adjust this. (Default is 10).\n\n`;
      searchResult.tips = searchResult.tips.slice(0, actualLimit);
    }
  }

  if (searchResult.tips.length === 0) {
    const noResultsMessage = generateNoResultsMessage(input.category, input.search_term);
    return noResultsMessage + serverDetailsString;
  }

  const categorizedTips = groupTipsByCategory(searchResult.tips, input.category);
  const formattingResult = formatResultsToMarkdown(categorizedTips, input.category);
  const formattedTips = formattingResult.markdownOutput;
  const lineLimitNotice = formattingResult.lineLimitNotice;

  let outputMessage = searchResult.notice + noticeAboutLimit + lineLimitNotice + formattedTips;

  if (input.refresh_database) {
    outputMessage = `Knowledge base reloaded successfully.${serverDetailsString}\n\n${outputMessage}`;
  } else if (!outputMessage.includes(serverDetailsString) && outputMessage.trim() !== "") {
    outputMessage += serverDetailsString;
  }

  return outputMessage;
}
