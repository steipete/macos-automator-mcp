// src/services/knowledgeBaseService.ts
import fs from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter';
import { fileURLToPath } from 'node:url'; // Import for robust pathing
import os from 'node:os'; // Added for home directory resolution
import type {
  ScriptingTip,
  KnowledgeBaseIndex,
  KnowledgeCategory,
  SharedHandler,
  TipFrontmatter
} from './scriptingKnowledge.types.js';
import type { GetScriptingTipsInput } from '../schemas.js'; // Changed to type-only import
import { Logger } from '../logger.js';

const logger = new Logger('KnowledgeBaseService');

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const KNOWLEDGE_BASE_ROOT_DIR_NAME = 'knowledge_base';
// Adjusted path to be relative to this file, assuming knowledge_base is at project root
const KNOWLEDGE_BASE_DIR = path.resolve(__dirname, '..', '..', KNOWLEDGE_BASE_ROOT_DIR_NAME);
const SHARED_HANDLERS_DIR_NAME = '_shared_handlers';

const LOCAL_KB_ENV_VAR = 'LOCAL_KB_PATH';
const DEFAULT_LOCAL_KB_PATH = path.join(os.homedir(), '.macos-automator', 'knowledge_base');

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

async function getLocalKnowledgeBasePath(): Promise<string> {
  const customPath = process.env[LOCAL_KB_ENV_VAR];
  if (customPath) {
    logger.info(`Using custom local knowledge base path from LOCAL_KB_PATH: ${customPath}`);
    return path.resolve(customPath.startsWith('~') ? customPath.replace('~', os.homedir()) : customPath);
  }
  logger.info(`Using default local knowledge base path: ${DEFAULT_LOCAL_KB_PATH}`);
  return DEFAULT_LOCAL_KB_PATH;
}

// Helper function to load tips and handlers from a given base path
async function loadKnowledgeBaseFromPath(
  basePath: string, 
  isLocalKb: boolean, 
  categories: KnowledgeBaseIndex['categories'],
  allTips: ScriptingTip[],
  sharedHandlers: SharedHandler[],
  encounteredTipIds: Set<string>
): Promise<void> {
  logger.info(`Loading knowledge base from path: ${basePath}`);
  
  // Helper function to recursively find tips in directories
  async function findTipsRecursively(
    currentScanPath: string, 
    categoryId: KnowledgeCategory, 
    currentEncounteredTipIds: Set<string> // Changed to currentEncounteredTipIds
  ): Promise<{ count: number; files: ScriptingTip[] }> {
    logger.debug('Recursively scanning directory for tips', { currentScanPath, categoryId });
    
    let entries: import('node:fs').Dirent[];
    try {
      entries = await fs.readdir(currentScanPath, { withFileTypes: true });
    } catch (error) {
      // Log if not ENOENT, or if it's local KB (where we might expect it not to exist)
      if ((error as NodeJS.ErrnoException).code !== 'ENOENT' || isLocalKb) {
        logger.warn('Failed to read directory in findTipsRecursively, skipping.', { 
          currentScanPath, 
          categoryId, 
          errorMessage: (error instanceof Error ? error.message : String(error)),
          isLocalKb
        });
      }
      return { count: 0, files: [] };
    }
    
    let currentLevelCount = 0;
    const currentLevelFiles: ScriptingTip[] = [];
    
    for (const entry of entries) {
      const entryPath = path.join(currentScanPath, entry.name);
      
      try {
        if (entry.isDirectory()) {
          const subDirResult = await findTipsRecursively(entryPath, categoryId, currentEncounteredTipIds);
          currentLevelCount += subDirResult.count;
          currentLevelFiles.push(...subDirResult.files);
        } else if (entry.isFile() && entry.name.endsWith('.md') && !entry.name.startsWith('_')) {
          let fileContent: string;
          try {
            fileContent = await fs.readFile(entryPath, 'utf-8');
          } catch (fileReadError) {
            logger.warn('Failed to read file in findTipsRecursively, skipping file.', {
              entryPath,
              categoryId,
              errorMessage: (fileReadError instanceof Error ? fileReadError.message : String(fileReadError))
            });
            continue;
          }
          
          const parsedFile = parseMarkdownTipFile(fileContent, entryPath);

          if (parsedFile?.frontmatter?.title) {
            const fm = parsedFile.frontmatter;
            const baseName = path.basename(entry.name, '.md').replace(/^\d+[_.-]?\s*/, '').replace(/\s+/g, '_');
            
            const relativePathFromCategory = path.relative(path.join(basePath, categoryId), path.dirname(entryPath));
            const pathPrefix = relativePathFromCategory && relativePathFromCategory !== '.' ? 
              `${relativePathFromCategory.replace(/\//g, '_').replace(/\\/g, '_')}_` : '';
            const tipId = fm.id || `${categoryId}_${pathPrefix}${baseName}`;

            if (currentEncounteredTipIds.has(tipId) && !isLocalKb) { // Only warn for duplicates in non-local KB, local overrides
              logger.warn('Duplicate Tip ID resolved in primary KB. Ensure unique frontmatter IDs or filenames.', { tipId, filePath: entryPath });
            }
            currentEncounteredTipIds.add(tipId); // Add to encountered, local will override if processed later

            if (parsedFile.script) {
              const newTip: ScriptingTip = {
                id: tipId,
                category: categoryId,
                title: fm.title,
                description: fm.description,
                script: parsedFile.script,
                language: parsedFile.determinedLanguage,
                keywords: Array.isArray(fm.keywords) ? fm.keywords.map(String) : (fm.keywords ? [String(fm.keywords)] : []),
                notes: fm.notes,
                filePath: entryPath, // Store the actual path for reference
                isComplex: fm.isComplex !== undefined ? fm.isComplex : (parsedFile.script.length > 250),
                argumentsPrompt: fm.argumentsPrompt,
                isLocal: isLocalKb // Mark if the tip is from local KB
              };
              
              // If it's a local KB and the tip ID already exists, replace the existing one
              const existingTipIndex = allTips.findIndex(t => t.id === tipId);
              if (isLocalKb && existingTipIndex !== -1) {
                logger.info(`Overriding tip with local version: ${tipId}`, { oldPath: allTips[existingTipIndex].filePath, newPath: entryPath });
                allTips[existingTipIndex] = newTip;
                // We don't increment currentLevelCount here as it's an override, not a new tip for category count purposes
              } else {
                currentLevelFiles.push(newTip);
                currentLevelCount++;
              }
              logger.debug('Found scriptable tip', { tipId, categoryId, isLocalKb, newTip: !isLocalKb || existingTipIndex === -1 });
            } else {
              logger.debug("Conceptual tip (no script block)", { title: fm.title, path: entryPath, isLocalKb });
            }
          }
        }
      } catch (entryError) {
        logger.warn('Error processing entry in findTipsRecursively, skipping entry.', {
          entryPath,
          categoryId,
          isLocalKb,
          errorMessage: (entryError instanceof Error ? entryError.message : String(entryError))
        });
      }
    }
    
    return { count: currentLevelCount, files: currentLevelFiles };
  }

  // Load shared handlers from this path
  const sharedHandlersPath = path.join(basePath, SHARED_HANDLERS_DIR_NAME);
  try {
    const handlerFiles = await fs.readdir(sharedHandlersPath, { withFileTypes: true });
    for (const handlerFile of handlerFiles) {
      if (handlerFile.isFile() && (handlerFile.name.endsWith('.applescript') || handlerFile.name.endsWith('.js'))) {
        const filePath = path.join(sharedHandlersPath, handlerFile.name);
        const content = await fs.readFile(filePath, 'utf-8');
        const handlerName = path.basename(handlerFile.name, path.extname(handlerFile.name));
        const language = (handlerFile.name.endsWith('.js') ? 'javascript' : 'applescript') as 'javascript' | 'applescript';
        
        const existingHandlerIndex = sharedHandlers.findIndex(h => h.name === handlerName && h.language === language);
        const newHandler: SharedHandler = { name: handlerName, content, filePath, language, isLocal: isLocalKb };

        if (isLocalKb && existingHandlerIndex !== -1) {
          logger.info(`Overriding shared handler with local version: ${handlerName} (${language})`, { oldPath: sharedHandlers[existingHandlerIndex].filePath, newPath: filePath });
          sharedHandlers[existingHandlerIndex] = newHandler;
        } else if (existingHandlerIndex === -1) { // Only add if no existing handler (even from another local path if we had multiple)
          sharedHandlers.push(newHandler);
        }
        logger.debug('Loaded shared handler', { name: handlerName, language, isLocalKb, newHandler: existingHandlerIndex === -1 });
      }
    }
  } catch (e: unknown) {
    const error = e as NodeJS.ErrnoException;
    if (error.code !== 'ENOENT') {
       logger.warn('Error reading _shared_handlers directory. Skipping.', { path: sharedHandlersPath, error: error.message, isLocalKb });
    } else {
       logger.info('_shared_handlers directory not found. Skipping shared handlers.', { path: sharedHandlersPath, isLocalKb });
    }
  }

  // Scan categories in this path
  let categoryDirEntries: import('node:fs').Dirent[];
  try {
    categoryDirEntries = await fs.readdir(basePath, { withFileTypes: true });
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'ENOENT' || !isLocalKb) { // Don't warn ENOENT for local if it's expected not to exist
        logger.warn('Failed to read base directory for categories, skipping.', { 
            basePath, 
            isLocalKb, 
            errorMessage: (error instanceof Error ? error.message : String(error))
        });
    }
    return; // Cannot proceed if base directory cannot be read
  }

  for (const categoryDirEntry of categoryDirEntries) {
    if (categoryDirEntry.isDirectory() && categoryDirEntry.name !== SHARED_HANDLERS_DIR_NAME) {
      const categoryId = categoryDirEntry.name as KnowledgeCategory;
      const categoryPath = path.join(basePath, categoryId);
      let categoryDescription = `Tips and examples for ${categoryId.replace(/_/g, ' ')}.`;
      const categoryInfoPath = path.join(categoryPath, '_category_info.md');
      const existingCategory = categories.find(c => c.id === categoryId);
      
      try {
          const catInfoContent = await fs.readFile(categoryInfoPath, 'utf-8');
          const { data } = matter(catInfoContent);
          const catFm = data as TipFrontmatter;
          if (catFm?.description) {
              categoryDescription = catFm.description;
          }
      } catch {
          /* No _category_info.md or error parsing, use default. */
      }

      const categoryScanResults = await findTipsRecursively(categoryPath, categoryId, encounteredTipIds);
      
      if (categoryScanResults.files.length > 0) {
        // Add new files to allTips, local files would have already replaced existing ones if ID matched
        // We only add files that are not already there (by reference, which means they are new from this pass)
        for (const newTip of categoryScanResults.files) {
            if (!allTips.find(t => t.id === newTip.id)) { // Check if it's truly a new tip, not an override
                allTips.push(newTip);
            }
        }
      }

      if (existingCategory) {
        if (isLocalKb) {
            // Update description if local _category_info.md provides one
            // And add new tip counts from the local source for this category
            // Note: The original logic for category.tipCount needs to be re-evaluated. 
            // It should sum unique tips for that category across both sources.
            // For now, we just ensure the category exists and its description might be updated.
            // Tip count will be based on the final allTips array filtered by category.
            existingCategory.description = categoryDescription; // Local _category_info can override description
            logger.debug('Updated existing category with local data', { categoryId, isLocalKb });
        }
      } else if (categoryScanResults.count > 0 || categoryScanResults.files.some(f => allTips.find(t => t.id === f.id && t.category === categoryId))) {
        // Add new category if it has new tips or if local files contribute to an existing category ID not yet in `categories` list.
        categories.push({ 
            id: categoryId, 
            description: categoryDescription, 
            tipCount: 0 // Will be recalculated later
        });
        logger.debug('Added new category', { categoryId, isLocalKb });
      }
    }
  }
}

async function actualLoadAndIndexKnowledgeBase(): Promise<KnowledgeBaseIndex> {
  indexedKnowledgeBase = null;
  logger.info('Starting: Load and index knowledge base from Markdown files...');
  const categories: KnowledgeBaseIndex['categories'] = [];
  const allTips: ScriptingTip[] = [];
  const sharedHandlers: SharedHandler[] = [];
  const encounteredTipIds = new Set<string>(); // Shared across all loading paths

  // Load from the standard knowledge base first
  await loadKnowledgeBaseFromPath(KNOWLEDGE_BASE_DIR, false, categories, allTips, sharedHandlers, encounteredTipIds);

  // Then load from the local knowledge base, potentially overriding tips and handlers
  const localKbPath = await getLocalKnowledgeBasePath();
  try {
      await fs.access(localKbPath); // Check if local path exists
      logger.info(`Local knowledge base path found: ${localKbPath}. Loading additional tips.`);
      await loadKnowledgeBaseFromPath(localKbPath, true, categories, allTips, sharedHandlers, encounteredTipIds);
  } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
          logger.info(`Local knowledge base path not found or not accessible: ${localKbPath}. Skipping.`);
      } else {
          logger.warn(`Error accessing local knowledge base path: ${localKbPath}. Skipping.`, { error: (error as Error).message });
      }
  }

  // Recalculate tip counts for categories based on the final merged list of tips
  for (const cat of categories) {
    cat.tipCount = allTips.filter(tip => tip.category === cat.id).length;
  }
  // Filter out categories with no tips after merging
  const finalCategories = categories.filter(cat => cat.tipCount > 0);

  // Sort results
  finalCategories.sort((a, b) => a.id.localeCompare(b.id));
  allTips.sort((a, b) => a.id.localeCompare(b.id));
  sharedHandlers.sort((a,b) => `${a.language}_${a.name}`.localeCompare(`${b.language}_${b.name}`));

  indexedKnowledgeBase = { categories: finalCategories, tips: allTips, sharedHandlers };
  logger.info(
    `Knowledge base loading complete: ${finalCategories.length} categories, ` +
    `${allTips.length} scriptable tips (${allTips.filter(t=>t.isLocal).length} local), ` +
    `${sharedHandlers.length} shared handlers (${sharedHandlers.filter(h=>h.isLocal).length} local).`
  );

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

// New function for conditional eager initialization
export async function conditionallyInitializeKnowledgeBase(eagerMode: boolean): Promise<void> {
  if (eagerMode) {
    logger.info('KB_PARSING is set to eager. Initializing knowledge base at startup...');
    try {
      await getKnowledgeBase(); // This will trigger loading if not already done
      logger.info('Eager initialization of knowledge base complete.');
    } catch (error) {
      logger.error('Error during eager initialization of knowledge base', { 
        errorMessage: (error instanceof Error ? error.message : String(error)),
        stack: (error instanceof Error ? error.stack : undefined)
      });
      // Depending on policy, might want to re-throw or handle so server doesn't start, 
      // but for now, just log and continue.
    }
  } else {
    logger.info('KB_PARSING is lazy (or not set). Knowledge base will load on first use.');
  }
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