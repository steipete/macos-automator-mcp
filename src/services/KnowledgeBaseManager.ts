import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import type {
  KnowledgeBaseIndex,
  ScriptingTip,
  SharedHandler,
  KnowledgeCategory,
} from "./scriptingKnowledge.types.js";
import { loadTipsAndHandlersFromPath } from "./kbLoader.js";
import type { LoadedKnowledgePath } from "./kbLoader.js";
import { Logger } from "../logger.js";

const logger = new Logger("KnowledgeBaseManager");

const EMBEDDED_KNOWLEDGE_BASE_DIR = path.resolve(import.meta.dirname, "..", "..", "knowledge_base");
const LOCAL_KB_ENV_VAR = "LOCAL_KB_PATH";
const DEFAULT_LOCAL_KB_PATH = path.join(os.homedir(), ".macos-automator", "knowledge_base");

let knowledgeBaseLoadPromise: Promise<KnowledgeBaseIndex> | null = null;

function getLocalKnowledgeBasePath(): string {
  const customPath = process.env[LOCAL_KB_ENV_VAR];
  if (customPath) {
    logger.info(`Using custom local knowledge base path from LOCAL_KB_PATH: ${customPath}`);
    return path.resolve(
      customPath.startsWith("~") ? customPath.replace("~", os.homedir()) : customPath,
    );
  }
  logger.info(`Using default local knowledge base path: ${DEFAULT_LOCAL_KB_PATH}`);
  return DEFAULT_LOCAL_KB_PATH;
}

function mergeKnowledgeData(
  base: KnowledgeBaseIndex,
  loadedPathData: LoadedKnowledgePath,
  isLocalOverrideContext: boolean,
): KnowledgeBaseIndex {
  const tipsMap = new Map<string, ScriptingTip>(base.tips.map((tip) => [tip.id, tip]));
  const handlersMap = new Map<string, SharedHandler>(
    base.sharedHandlers.map((h) => [`${h.name}_${h.language}`, h]),
  );
  const categoriesMap = new Map<
    KnowledgeCategory,
    { id: KnowledgeCategory; description: string; tipCount: number }
  >(base.categories.map((c) => [c.id, c]));

  for (const newTip of loadedPathData.tips) {
    const previous = tipsMap.get(newTip.id);
    if (previous && !isLocalOverrideContext) continue;
    if (previous) {
      logger.info(`Overriding tip with local version: ${newTip.id}`, {
        oldPath: previous.filePath,
        newPath: newTip.filePath,
      });
    }
    tipsMap.set(newTip.id, { ...newTip, isLocal: isLocalOverrideContext });
  }

  for (const newHandler of loadedPathData.sharedHandlers) {
    const handlerKey = `${newHandler.name}_${newHandler.language}`;
    const previous = handlersMap.get(handlerKey);
    if (previous && !isLocalOverrideContext) continue;
    if (previous) {
      logger.info(
        `Overriding shared handler with local version: ${newHandler.name} (${newHandler.language})`,
        {
          oldPath: previous.filePath,
          newPath: newHandler.filePath,
        },
      );
    }
    handlersMap.set(handlerKey, { ...newHandler, isLocal: isLocalOverrideContext });
  }

  for (const newCategory of loadedPathData.categories) {
    const existingCategory = categoriesMap.get(newCategory.id);
    if (existingCategory) {
      if (isLocalOverrideContext && newCategory.description !== undefined) {
        existingCategory.description = newCategory.description;
        logger.debug("Updated existing category description with local data", {
          categoryId: newCategory.id,
        });
      }
    } else {
      categoriesMap.set(newCategory.id, {
        ...newCategory,
        description:
          newCategory.description ?? `Tips and examples for ${newCategory.id.replace(/_/g, " ")}.`,
        tipCount: 0,
      });
      logger.debug("Added new category from loaded path", { categoryId: newCategory.id });
    }
  }

  const finalTips = Array.from(tipsMap.values());
  const finalCategories = Array.from(categoriesMap.values());

  for (const cat of finalCategories) {
    cat.tipCount = finalTips.filter((tip) => tip.category === cat.id).length;
  }
  const activeCategories = finalCategories.filter(
    (cat) => cat.tipCount > 0 || cat.id === "no_knowledge_base_found", // Keep special error category
  );

  activeCategories.sort((a, b) => a.id.localeCompare(b.id));
  finalTips.sort((a, b) => a.id.localeCompare(b.id));
  const finalHandlers = Array.from(handlersMap.values()).sort((a, b) =>
    `${a.language}_${a.name}`.localeCompare(`${b.language}_${b.name}`),
  );

  return { categories: activeCategories, tips: finalTips, sharedHandlers: finalHandlers };
}

async function actualLoadAndIndexKnowledgeBase(): Promise<KnowledgeBaseIndex> {
  logger.info("Starting: Load and index knowledge base...");

  let baseKb: KnowledgeBaseIndex = { categories: [], tips: [], sharedHandlers: [] };

  try {
    await fs.access(EMBEDDED_KNOWLEDGE_BASE_DIR);
    logger.info(`Embedded knowledge base path found: ${EMBEDDED_KNOWLEDGE_BASE_DIR}. Loading...`);
    const embeddedData = await loadTipsAndHandlersFromPath(EMBEDDED_KNOWLEDGE_BASE_DIR, false);
    baseKb = mergeKnowledgeData(baseKb, embeddedData, false);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      logger.warn(
        `Embedded knowledge base directory not found at ${EMBEDDED_KNOWLEDGE_BASE_DIR}. This is a critical issue.`,
      );
      baseKb.categories.push({
        id: "no_knowledge_base_found",
        description:
          "ERROR: Embedded Knowledge base directory missing. Functionality will be severely limited.",
        tipCount: 0,
      });
    } else {
      logger.error(`Error accessing embedded knowledge base: ${EMBEDDED_KNOWLEDGE_BASE_DIR}`, {
        error: (error as Error).message,
      });
    }
  }

  const localKbPath = getLocalKnowledgeBasePath();
  try {
    await fs.access(localKbPath);
    logger.info(`Local knowledge base path found: ${localKbPath}. Loading and merging.`);
    const localData = await loadTipsAndHandlersFromPath(localKbPath, true);
    baseKb = mergeKnowledgeData(baseKb, localData, true);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      logger.info(
        `Local knowledge base path not found or not accessible: ${localKbPath}. Skipping.`,
      );
    } else {
      logger.warn(`Error accessing local knowledge base path: ${localKbPath}. Skipping.`, {
        error: (error as Error).message,
      });
    }
  }

  logger.info(
    `Knowledge base loading complete: ${baseKb.categories.length} categories, ` +
      `${baseKb.tips.length} scriptable tips (${baseKb.tips.filter((t) => t.isLocal).length} local/overridden), ` +
      `${baseKb.sharedHandlers.length} shared handlers (${baseKb.sharedHandlers.filter((h) => h.isLocal).length} local/overridden).`,
  );
  return baseKb;
}

export function getKnowledgeBase(): Promise<KnowledgeBaseIndex> {
  if (!knowledgeBaseLoadPromise) {
    const loadPromise = actualLoadAndIndexKnowledgeBase().catch((error: unknown) => {
      // A failed older load must not invalidate a newer refresh.
      if (knowledgeBaseLoadPromise === loadPromise) knowledgeBaseLoadPromise = null;
      throw error;
    });
    knowledgeBaseLoadPromise = loadPromise;
  }
  return knowledgeBaseLoadPromise;
}

export function forceReloadKnowledgeBase(): Promise<KnowledgeBaseIndex> {
  logger.info("Forcing knowledge base reload...");
  knowledgeBaseLoadPromise = null;
  return getKnowledgeBase();
}

export async function conditionallyInitializeKnowledgeBase(eagerMode: boolean): Promise<void> {
  if (eagerMode) {
    logger.info("KB_PARSING is set to eager. Initializing knowledge base at startup...");
    try {
      await getKnowledgeBase();
      logger.info("Eager initialization of knowledge base complete.");
    } catch (error) {
      logger.error("Error during eager initialization of knowledge base", {
        errorMessage: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
      });
    }
  } else {
    logger.info("KB_PARSING is lazy (or not set). Knowledge base will load on first use.");
  }
}
