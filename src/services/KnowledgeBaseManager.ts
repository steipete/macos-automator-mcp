import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import type { KnowledgeBaseIndex, ScriptingTip, SharedHandler, KnowledgeCategory } from './scriptingKnowledge.types.js';
import { loadTipsAndHandlersFromPath } from './kbLoader.js';
import type { LoadedKnowledgePath } from './kbLoader.js';
import { Logger } from '../logger.js';

const logger = new Logger('KnowledgeBaseManager');

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Constants for KB paths
const KNOWLEDGE_BASE_ROOT_DIR_NAME = 'knowledge_base';
const EMBEDDED_KNOWLEDGE_BASE_DIR = path.resolve(__dirname, '..', '..', KNOWLEDGE_BASE_ROOT_DIR_NAME);
const LOCAL_KB_ENV_VAR = 'LOCAL_KB_PATH';
const DEFAULT_LOCAL_KB_PATH = path.join(os.homedir(), '.macos-automator', 'knowledge_base');

// State variables for caching and loading
let indexedKnowledgeBase: KnowledgeBaseIndex | null = null;
let isLoadingKnowledgeBase = false;
let knowledgeBaseLoadPromise: Promise<KnowledgeBaseIndex> | null = null;

async function getLocalKnowledgeBasePath(): Promise<string> {
  const customPath = process.env[LOCAL_KB_ENV_VAR];
  if (customPath) {
    logger.info(`Using custom local knowledge base path from LOCAL_KB_PATH: ${customPath}`);
    return path.resolve(customPath.startsWith('~') ? customPath.replace('~', os.homedir()) : customPath);
  }
  logger.info(`Using default local knowledge base path: ${DEFAULT_LOCAL_KB_PATH}`);
  return DEFAULT_LOCAL_KB_PATH;
}

function mergeKnowledgeData(
  base: KnowledgeBaseIndex,
  loadedPathData: LoadedKnowledgePath,
  isLocalOverrideContext: boolean
): KnowledgeBaseIndex {
  // Use Maps for efficient lookups and updates
  const tipsMap = new Map<string, ScriptingTip>(base.tips.map(tip => [tip.id, tip]));
  const handlersMap = new Map<string, SharedHandler>(
    base.sharedHandlers.map(h => [`${h.name}_${h.language}`, h])
  );
  const categoriesMap = new Map<KnowledgeCategory, { id: KnowledgeCategory; description: string; tipCount: number }>(
      base.categories.map(c => [c.id, c])
  );

  // Merge/override tips from loadedPathData
  for (const newTip of loadedPathData.tips) {
    const tipKey = newTip.id;
    if (tipsMap.has(tipKey)) {
      if (isLocalOverrideContext) {
        logger.info(`Overriding tip with ${isLocalOverrideContext ? 'local' : 'new'} version: ${newTip.id}`, { oldPath: tipsMap.get(tipKey)?.filePath, newPath: newTip.filePath });
        tipsMap.set(tipKey, { ...newTip, isLocal: isLocalOverrideContext }); // Mark as local if from local override context
      }
    } else {
      // Add as a new tip, mark its origin (isLocal based on context)
      tipsMap.set(tipKey, { ...newTip, isLocal: isLocalOverrideContext });
    }
  }

  // Merge/override shared handlers from loadedPathData
  for (const newHandler of loadedPathData.sharedHandlers) {
    const handlerKey = `${newHandler.name}_${newHandler.language}`;
    if (handlersMap.has(handlerKey)) {
      if (isLocalOverrideContext) {
        logger.info(`Overriding shared handler with ${isLocalOverrideContext ? 'local' : 'new'} version: ${newHandler.name} (${newHandler.language})`, { oldPath: handlersMap.get(handlerKey)?.filePath, newPath: newHandler.filePath });
        handlersMap.set(handlerKey, { ...newHandler, isLocal: isLocalOverrideContext });
      }
    } else {
      handlersMap.set(handlerKey, { ...newHandler, isLocal: isLocalOverrideContext });
    }
  }

  // Merge categories (add new, update descriptions from local if provided)
  for (const newCategory of loadedPathData.categories) {
    const existingCategory = categoriesMap.get(newCategory.id);
    if (existingCategory) {
      if (isLocalOverrideContext) {
        // Update description if local _category_info.md provided it
        existingCategory.description = newCategory.description;
        logger.debug('Updated existing category description with local data', { categoryId: newCategory.id });
      }
      // tipCount will be recalculated later, so no need to sum here
    } else {
      categoriesMap.set(newCategory.id, { ...newCategory, tipCount: 0 }); // tipCount will be recalculated
      logger.debug('Added new category from loaded path', { categoryId: newCategory.id });
    }
  }
  
  const finalTips = Array.from(tipsMap.values());
  const finalCategories = Array.from(categoriesMap.values());

  // Recalculate tip counts for all categories based on the final merged list of tips
  for (const cat of finalCategories) {
    cat.tipCount = finalTips.filter(tip => tip.category === cat.id).length;
  }
  // Filter out categories with no tips after merging
  const activeCategories = finalCategories.filter(cat => cat.tipCount > 0 || 
    (cat.id === 'no_knowledge_base_found' as KnowledgeCategory) // Keep special error category
  );

  activeCategories.sort((a, b) => a.id.localeCompare(b.id));
  finalTips.sort((a, b) => a.id.localeCompare(b.id));
  const finalHandlers = Array.from(handlersMap.values()).sort((a,b) => `${a.language}_${a.name}`.localeCompare(`${b.language}_${b.name}`));

  return { categories: activeCategories, tips: finalTips, sharedHandlers: finalHandlers };
}


async function actualLoadAndIndexKnowledgeBase(): Promise<KnowledgeBaseIndex> {
  logger.info('Starting: Load and index knowledge base...');
  
  let baseKb: KnowledgeBaseIndex = { categories: [], tips: [], sharedHandlers: [] };

  // Load from the standard embedded knowledge base first
  try {
    await fs.access(EMBEDDED_KNOWLEDGE_BASE_DIR);
    logger.info(`Embedded knowledge base path found: ${EMBEDDED_KNOWLEDGE_BASE_DIR}. Loading...`);
    const embeddedData = await loadTipsAndHandlersFromPath(EMBEDDED_KNOWLEDGE_BASE_DIR, false);
    baseKb = mergeKnowledgeData(baseKb, embeddedData, false); // embedded data is not 'local override' context
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
      logger.warn(`Embedded knowledge base directory not found at ${EMBEDDED_KNOWLEDGE_BASE_DIR}. This is a critical issue.`);
      // Potentially throw or return a minimal KB with an error category
      baseKb.categories.push({
        id: 'no_knowledge_base_found' as KnowledgeCategory,
        description: 'ERROR: Embedded Knowledge base directory missing. Functionality will be severely limited.',
        tipCount: 0
      });
    } else {
      logger.error(`Error accessing embedded knowledge base: ${EMBEDDED_KNOWLEDGE_BASE_DIR}`, { error: (error as Error).message });
    }
  }

  // Then load from the local knowledge base, which can override or add to the embedded one
  const localKbPath = await getLocalKnowledgeBasePath();
  try {
      await fs.access(localKbPath);
      logger.info(`Local knowledge base path found: ${localKbPath}. Loading and merging.`);
      const localData = await loadTipsAndHandlersFromPath(localKbPath, true);
      baseKb = mergeKnowledgeData(baseKb, localData, true); // local data IS 'local override' context
  } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
          logger.info(`Local knowledge base path not found or not accessible: ${localKbPath}. Skipping.`);
      } else {
          logger.warn(`Error accessing local knowledge base path: ${localKbPath}. Skipping.`, { error: (error as Error).message });
      }
  }

  indexedKnowledgeBase = baseKb; // Store the fully merged and processed KB

  logger.info(
    `Knowledge base loading complete: ${indexedKnowledgeBase.categories.length} categories, ` +
    `${indexedKnowledgeBase.tips.length} scriptable tips (${indexedKnowledgeBase.tips.filter(t=>t.isLocal).length} local/overridden), ` +
    `${indexedKnowledgeBase.sharedHandlers.length} shared handlers (${indexedKnowledgeBase.sharedHandlers.filter(h=>h.isLocal).length} local/overridden).`
  );
  return indexedKnowledgeBase;
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
        // knowledgeBaseLoadPromise = null; // Optional: clear promise once resolved/rejected if not needed for retries
    });
    return knowledgeBaseLoadPromise;
}

export async function forceReloadKnowledgeBase(): Promise<KnowledgeBaseIndex> {
  logger.info('Forcing knowledge base reload...');
  indexedKnowledgeBase = null;
  knowledgeBaseLoadPromise = null; 
  isLoadingKnowledgeBase = false;
  return getKnowledgeBase(); // This will trigger a fresh load
}

export async function conditionallyInitializeKnowledgeBase(eagerMode: boolean): Promise<void> {
  if (eagerMode) {
    logger.info('KB_PARSING is set to eager. Initializing knowledge base at startup...');
    try {
      await getKnowledgeBase();
      logger.info('Eager initialization of knowledge base complete.');
    } catch (error) {
      logger.error('Error during eager initialization of knowledge base', { 
        errorMessage: (error instanceof Error ? error.message : String(error)),
        stack: (error instanceof Error ? error.stack : undefined)
      });
    }
  } else {
    logger.info('KB_PARSING is lazy (or not set). Knowledge base will load on first use.');
  }
} 