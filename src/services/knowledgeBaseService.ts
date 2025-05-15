// src/services/knowledgeBaseService.ts
import fs from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter';
import { fileURLToPath } from 'node:url'; // Import for robust pathing
import type {
  ScriptingTip,
  KnowledgeBaseIndex,
  KnowledgeCategory,
  SharedHandler,
  TipFrontmatter
} from './scriptingKnowledge.types.js';
import { GetScriptingTipsInput } from '../schemas.js';
import { Logger } from '../logger.js';

const logger = new Logger('KnowledgeBaseService');

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const KNOWLEDGE_BASE_ROOT_DIR_NAME = 'knowledge_base';
// Adjusted path to be relative to this file, assuming knowledge_base is at project root
const KNOWLEDGE_BASE_DIR = path.resolve(__dirname, '..', '..', KNOWLEDGE_BASE_ROOT_DIR_NAME);
const SHARED_HANDLERS_DIR_NAME = '_shared_handlers';

let indexedKnowledgeBase: KnowledgeBaseIndex | null = null;
let isLoadingKnowledgeBase = false; // Type inferred
let knowledgeBaseLoadPromise: Promise<KnowledgeBaseIndex> | null = null;

function parseMarkdownTipFile(
  fileContent: string,
  filePath: string
): { frontmatter: TipFrontmatter, body: string, script: string | null, determinedLanguage: 'applescript' | 'javascript' } | null {
  try {
    const { data, content: markdownBody } = matter(fileContent);
    const frontmatter = data as TipFrontmatter;

    if (!frontmatter.title) {
      logger.warn('Markdown tip file missing title in frontmatter', { filePath });
      return null;
    }

    let script: string | null = null;
    let determinedLanguage: 'applescript' | 'javascript' = frontmatter.language || 'applescript';

    const asMatch = markdownBody.match(/```applescript\s*\n([\s\S]*?)\n```/i);
    const jsMatch = markdownBody.match(/```javascript\s*\n([\s\S]*?)\n```/i);

    if (asMatch) {
      script = asMatch[1].trim();
      determinedLanguage = 'applescript';
    } else if (jsMatch) {
      script = jsMatch[1].trim();
      determinedLanguage = 'javascript';
    }

    return { frontmatter, body: markdownBody, script, determinedLanguage };
  } catch (e: unknown) {
    logger.error('Failed to parse Markdown tip file', { filePath, error: (e as Error).message });
    return null;
  }
}

async function actualLoadAndIndexKnowledgeBase(): Promise<KnowledgeBaseIndex> {
  logger.info('Starting: Load and index knowledge base from Markdown files...');
  const categories: KnowledgeBaseIndex['categories'] = [];
  const allTips: ScriptingTip[] = [];
  const sharedHandlers: SharedHandler[] = [];
  const encounteredTipIds = new Set<string>();

  try {
    const sharedHandlersPath = path.join(KNOWLEDGE_BASE_DIR, SHARED_HANDLERS_DIR_NAME);
    try {
      const handlerFiles = await fs.readdir(sharedHandlersPath, { withFileTypes: true });
      for (const handlerFile of handlerFiles) {
        if (handlerFile.isFile() && (handlerFile.name.endsWith('.applescript') || handlerFile.name.endsWith('.js'))) {
          const filePath = path.join(sharedHandlersPath, handlerFile.name);
          const content = await fs.readFile(filePath, 'utf-8');
          const handlerName = path.basename(handlerFile.name, path.extname(handlerFile.name));
          const language = handlerFile.name.endsWith('.js') ? 'javascript' : 'applescript';
          sharedHandlers.push({ name: handlerName, content, filePath, language });
          logger.debug('Loaded shared handler', { name: handlerName, language });
        }
      }
    } catch (e: unknown) {
      const error = e as NodeJS.ErrnoException;
      if (error.code !== 'ENOENT') {
         logger.warn('Error reading _shared_handlers directory. Skipping.', { error: error.message });
      } else {
         logger.info('_shared_handlers directory not found. Skipping shared handlers.');
      }
    }

    const categoryDirEntries = await fs.readdir(KNOWLEDGE_BASE_DIR, { withFileTypes: true });

    for (const categoryDirEntry of categoryDirEntries) {
      if (categoryDirEntry.isDirectory() && categoryDirEntry.name !== SHARED_HANDLERS_DIR_NAME) {
        const categoryId = categoryDirEntry.name as KnowledgeCategory;
        const categoryPath = path.join(KNOWLEDGE_BASE_DIR, categoryId);
        let tipCount = 0;
        let categoryDescription = `Tips and examples for ${categoryId.replace(/_/g, ' ')}.`;

        try {
            const catInfoPath = path.join(categoryPath, '_category_info.md');
            const catInfoContent = await fs.readFile(catInfoPath, 'utf-8');
            const { data } = matter(catInfoContent);
            const catFm = data as TipFrontmatter;
            if (catFm?.description) {
                categoryDescription = catFm.description;
            }
        } catch {
            /* No _category_info.md or error parsing, use default description. Error variable intentionally unused. */
        }

        const tipFileEntries = await fs.readdir(categoryPath, { withFileTypes: true });
        for (const tipFileEntry of tipFileEntries) {
          if (tipFileEntry.isFile() && tipFileEntry.name.endsWith('.md') && !tipFileEntry.name.startsWith('_')) {
            const filePath = path.join(categoryPath, tipFileEntry.name);
            const fileContent = await fs.readFile(filePath, 'utf-8');
            const parsedFile = parseMarkdownTipFile(fileContent, filePath);

            if (parsedFile?.frontmatter?.title) {
              const fm = parsedFile.frontmatter;
              const baseName = path.basename(tipFileEntry.name, '.md').replace(/^\d+[_.-]?\s*/, '').replace(/\s+/g, '_');
              const tipId = fm.id || `${categoryId}_${baseName}`;

              if (encounteredTipIds.has(tipId)) {
                  logger.warn('Duplicate Tip ID resolved. Consider making frontmatter IDs unique or renaming files.', { tipId, filePath });
              }
              encounteredTipIds.add(tipId);

              if (parsedFile.script) {
                allTips.push({
                  id: tipId,
                  category: categoryId,
                  title: fm.title,
                  description: fm.description,
                  script: parsedFile.script,
                  language: parsedFile.determinedLanguage,
                  keywords: Array.isArray(fm.keywords) ? fm.keywords.map(String) : (fm.keywords ? [String(fm.keywords)] : []),
                  notes: fm.notes,
                  filePath: filePath,
                  isComplex: fm.isComplex !== undefined ? fm.isComplex : (parsedFile.script.length > 250),
                  argumentsPrompt: fm.argumentsPrompt,
                });
                tipCount++;
              } else {
                 logger.debug("Conceptual tip (no script block)", { title: fm.title, path: filePath });
              }
            }
          }
        }
        if (tipCount > 0) {
            categories.push({ id: categoryId, description: categoryDescription, tipCount });
        }
      }
    }
    categories.sort((a: KnowledgeBaseIndex['categories'][0], b: KnowledgeBaseIndex['categories'][0]) => a.id.localeCompare(b.id));
    allTips.sort((a: ScriptingTip, b: ScriptingTip) => a.id.localeCompare(b.id));

    indexedKnowledgeBase = { categories, tips: allTips, sharedHandlers };
    logger.info(`Knowledge base loading complete: ${categories.length} categories, ${allTips.length} scriptable tips, ${sharedHandlers.length} shared handlers.`);

  } catch (error: unknown) {
    logger.error('Fatal error during knowledge base indexing', { error: (error as Error).message, stack: (error as Error).stack, path: KNOWLEDGE_BASE_DIR });
    indexedKnowledgeBase = { categories: [], tips: [], sharedHandlers: [] };
  }
  return indexedKnowledgeBase;
}

// Exported function to allow explicit reloading
export async function forceReloadKnowledgeBase(): Promise<KnowledgeBaseIndex> {
  logger.info('Forcing knowledge base reload...');
  indexedKnowledgeBase = null;
  knowledgeBaseLoadPromise = null;
  isLoadingKnowledgeBase = false; 
  return getKnowledgeBase(); // This will trigger a fresh load
}

export async function getKnowledgeBase(): Promise<KnowledgeBaseIndex> {
    if (indexedKnowledgeBase && !isLoadingKnowledgeBase) {
        return indexedKnowledgeBase;
    }
    if (isLoadingKnowledgeBase && knowledgeBaseLoadPromise) {
        logger.debug('Knowledge base is currently loading, awaiting existing promise.');
        return knowledgeBaseLoadPromise;
    }
    isLoadingKnowledgeBase = true;
    knowledgeBaseLoadPromise = actualLoadAndIndexKnowledgeBase().finally(() => {
        isLoadingKnowledgeBase = false;
    });
    return knowledgeBaseLoadPromise;
}

export async function getScriptingTipsService(
  input: GetScriptingTipsInput
): Promise<string> {
  if (input.refreshDatabase) {
    await forceReloadKnowledgeBase();
  }
  const kb = await getKnowledgeBase();

  if (input.listCategories || (!input.category && !input.searchTerm)) {
    if (kb.categories.length === 0) return "No tip categories available. Knowledge base might be empty or failed to load.";
    const categoryList = kb.categories
      .map(cat => `- **${cat.id}**: ${cat.description} (${cat.tipCount} tips)`)
      .join('\n');
    return `## Available AppleScript/JXA Tip Categories:\n${categoryList}\n\nUse \`category: "category_name"\` to get specific tips, or \`searchTerm: "keyword"\` to search. Tips with a runnable ID can be executed directly via the \`execute_script\` tool.`;
  }

  const results: { category: KnowledgeCategory; tips: ScriptingTip[] }[] = []; // Changed to const
  const searchTermLower = input.searchTerm?.toLowerCase();

  const tipsToSearch = input.category && kb.categories.find((c: { id: KnowledgeCategory }) => c.id === input.category)
    ? kb.tips.filter((t: ScriptingTip) => t.category === input.category)
    : kb.tips;

  if (searchTermLower) {
      const filteredTips = tipsToSearch.filter((tip: ScriptingTip) =>
          tip.title.toLowerCase().includes(searchTermLower) ||
          tip.id.toLowerCase().includes(searchTermLower) ||
          tip.script.toLowerCase().includes(searchTermLower) || 
          tip.description?.toLowerCase().includes(searchTermLower) ||
          tip.keywords?.some((k: string) => k.toLowerCase().includes(searchTermLower))
      );
      const groupedByCat = filteredTips.reduce((acc: Record<KnowledgeCategory, ScriptingTip[]>, tip: ScriptingTip) => {
          if (!acc[tip.category]) {
            acc[tip.category] = [];
          }
          acc[tip.category].push(tip);
          return acc;
      }, {} as Record<KnowledgeCategory, ScriptingTip[]>);
      for (const catKey in groupedByCat) {
          results.push({ category: catKey as KnowledgeCategory, tips: groupedByCat[catKey].sort((a: ScriptingTip, b: ScriptingTip) => a.title.localeCompare(b.title)) });
      }
  } else if (input.category) {
      const tipsForCategory = kb.tips.filter((t: ScriptingTip) => t.category === input.category).sort((a: ScriptingTip, b: ScriptingTip) => a.title.localeCompare(b.title));
      if (tipsForCategory.length > 0) {
          results.push({category: input.category, tips: tipsForCategory});
      }
  }

  if (results.length === 0) {
    return `No tips found matching your criteria (Category: ${input.category || 'All Categories'}, SearchTerm: ${input.searchTerm || 'None'}). Try \`listCategories: true\` to see available categories.`;
  }

  return results.sort((a: { category: KnowledgeCategory }, b: { category: KnowledgeCategory }) => a.category.localeCompare(b.category)).map((catResult: { category: KnowledgeCategory; tips: ScriptingTip[] }) => {
    const categoryTitle = catResult.category.replace(/_/g, ' ').replace(/\b\w/g, (l: string) => l.toUpperCase());
    const categoryHeader = `## Tips: ${categoryTitle}\n`;
    const tipMarkdown = catResult.tips.map((tip: ScriptingTip) => `
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