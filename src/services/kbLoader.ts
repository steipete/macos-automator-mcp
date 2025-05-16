import fs from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter';
import type { ScriptingTip, KnowledgeCategory, SharedHandler, TipFrontmatter } from './scriptingKnowledge.types.js';
import { Logger } from '../logger.js'; // Assuming logger is one level up

const logger = new Logger('KBLoader');

// Original KNOWLEDGE_BASE_ROOT_DIR_NAME and SHARED_HANDLERS_DIR_NAME might not be needed here
// if kbLoader only processes a given base path.
// For now, keep SHARED_HANDLERS_DIR_NAME if it's used intrinsically by loadKnowledgeBaseFromPath logic.
const SHARED_HANDLERS_DIR_NAME = '_shared_handlers';

export interface ParsedTipFile {
  frontmatter: TipFrontmatter;
  body: string;
  script: string | null;
  determinedLanguage: 'applescript' | 'javascript';
}

export function parseMarkdownTipFile(
  fileContent: string,
  filePath: string
): ParsedTipFile | null {
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

export interface LoadedKnowledgePath {
    categories: { id: KnowledgeCategory; description: string; tipCount: number }[];
    tips: ScriptingTip[];
    sharedHandlers: SharedHandler[];
}

// This function is a refactor of the original loadKnowledgeBaseFromPath and its recursive helper.
// It now focuses on loading from a single basePath and doesn't merge directly into global collections.
export async function loadTipsAndHandlersFromPath(
  basePath: string, 
  isLocalKb: boolean
): Promise<LoadedKnowledgePath> {
  logger.info(`Loading knowledge data from path: ${basePath} (isLocal: ${isLocalKb})`);
  
  const loadedCategories: LoadedKnowledgePath['categories'] = [];
  const loadedTips: ScriptingTip[] = [];
  const loadedSharedHandlers: SharedHandler[] = [];
  const encounteredTipIdsThisPath = new Set<string>(); // Track IDs within this path to warn for local duplicates too

  async function findTipsRecursively(
    currentScanPath: string, 
    categoryId: KnowledgeCategory
  ): Promise<{ count: number; files: ScriptingTip[] }> {
    logger.debug('Recursively scanning directory for tips', { currentScanPath, categoryId });
    
    let entries: import('node:fs').Dirent[];
    try {
      entries = await fs.readdir(currentScanPath, { withFileTypes: true });
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== 'ENOENT') { // Don't log ENOENT loudly, it might be expected
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
          // Do not pass encounteredTipIdsThisPath down for sub-categories, ID uniqueness is per category or global later
          const subDirResult = await findTipsRecursively(entryPath, categoryId);
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
            const baseName = path.basename(entry.name, '.md').replace(/^\d+[_.-]?\s*/, '').replace(/\s+/g, '_').toLowerCase();
            const relativePathFromCategory = path.relative(path.join(basePath, categoryId), path.dirname(entryPath));
            const pathPrefix = relativePathFromCategory && relativePathFromCategory !== '.' ? 
              `${relativePathFromCategory.replace(/\//g, '_').replace(/\\/g, '_')}_` : '';
            const tipId = fm.id || `${categoryId}_${pathPrefix}${baseName}`;

            if (encounteredTipIdsThisPath.has(tipId)) { 
              logger.warn('Duplicate Tip ID found within the same processing path. Check for conflicting frontmatter IDs or filenames.', { tipId, filePath: entryPath, basePath });
            }
            encounteredTipIdsThisPath.add(tipId);

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
                filePath: entryPath,
                isComplex: fm.isComplex !== undefined ? fm.isComplex : (parsedFile.script.length > 250),
                argumentsPrompt: fm.argumentsPrompt,
                isLocal: isLocalKb 
              };
              currentLevelFiles.push(newTip);
              currentLevelCount++;
              logger.debug('Found scriptable tip', { tipId, categoryId, isLocalKb });
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

  const sharedHandlersPath = path.join(basePath, SHARED_HANDLERS_DIR_NAME);
  try {
    const handlerFiles = await fs.readdir(sharedHandlersPath, { withFileTypes: true });
    for (const handlerFile of handlerFiles) {
      if (handlerFile.isFile() && (handlerFile.name.endsWith('.applescript') || handlerFile.name.endsWith('.js'))) {
        const filePath = path.join(sharedHandlersPath, handlerFile.name);
        const content = await fs.readFile(filePath, 'utf-8');
        const handlerName = path.basename(handlerFile.name, path.extname(handlerFile.name));
        const language = (handlerFile.name.endsWith('.js') ? 'javascript' : 'applescript') as 'javascript' | 'applescript';
        
        loadedSharedHandlers.push({ name: handlerName, content, filePath, language, isLocal: isLocalKb });
        logger.debug('Loaded shared handler', { name: handlerName, language, isLocalKb });
      }
    }
  } catch (e: unknown) {
    const error = e as NodeJS.ErrnoException;
    if (error.code !== 'ENOENT') {
       logger.warn('Error reading _shared_handlers directory. Skipping.', { path: sharedHandlersPath, error: error.message, isLocalKb });
    } else {
       logger.debug('_shared_handlers directory not found, normal for some KBs.', { path: sharedHandlersPath, isLocalKb });
    }
  }

  let categoryDirEntries: import('node:fs').Dirent[];
  try {
    categoryDirEntries = await fs.readdir(basePath, { withFileTypes: true });
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'ENOENT' || !isLocalKb) { 
        logger.warn('Failed to read base directory for categories, skipping this path.', { 
            basePath, isLocalKb, 
            errorMessage: (error instanceof Error ? error.message : String(error))
        });
    }
    return { categories: [], tips: [], sharedHandlers: [] }; // Return empty if base dir unreadable
  }

  for (const categoryDirEntry of categoryDirEntries) {
    if (categoryDirEntry.isDirectory() && categoryDirEntry.name !== SHARED_HANDLERS_DIR_NAME) {
      const categoryId = categoryDirEntry.name as KnowledgeCategory;
      const categoryPath = path.join(basePath, categoryId);
      let categoryDescription = `Tips and examples for ${categoryId.replace(/_/g, ' ')}.`;
      const categoryInfoPath = path.join(categoryPath, '_category_info.md');
      
      try {
          const catInfoContent = await fs.readFile(categoryInfoPath, 'utf-8');
          const { data } = matter(catInfoContent);
          if (data?.description && typeof data.description === 'string') {
              categoryDescription = data.description;
          }
      } catch { /* No _category_info.md or error parsing, use default. */ }

      const categoryScanResults = await findTipsRecursively(categoryPath, categoryId);
      loadedTips.push(...categoryScanResults.files);
      
      if (categoryScanResults.count > 0) { // Only add category if it has tips from this path
        loadedCategories.push({ 
            id: categoryId, 
            description: categoryDescription, 
            tipCount: categoryScanResults.count 
        });
        logger.debug('Processed category from path', { categoryId, tipCount: categoryScanResults.count, isLocalKb });
      }
    }
  }
  return { categories: loadedCategories, tips: loadedTips, sharedHandlers: loadedSharedHandlers };
} 