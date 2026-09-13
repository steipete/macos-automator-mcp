import fs from "node:fs/promises";
import path from "node:path";
import matter from "gray-matter";
import { z } from "zod";
import { SHARED_HANDLER_DIRECTORIES, extractScriptBlock } from "./kbFormat.js";
import type {
  ScriptingTip,
  KnowledgeCategory,
  SharedHandler,
  TipFrontmatter,
} from "./scriptingKnowledge.types.js";
import { Logger } from "../logger.js";

const logger = new Logger("KBLoader");

const optionalText = z
  .string()
  .nullish()
  .transform((value) => value ?? undefined);
const TipFrontmatterSchema = z.object({
  title: z.string().refine((value) => value.trim().length > 0),
  id: optionalText,
  description: optionalText,
  notes: optionalText,
  argumentsPrompt: optionalText,
  language: z
    .enum(["applescript", "javascript"])
    .nullish()
    .transform((value) => value ?? undefined),
  isComplex: z
    .boolean()
    .nullish()
    .transform((value) => value ?? undefined),
  keywords: z.unknown().optional(),
});

export interface ParsedTipFile {
  frontmatter: TipFrontmatter;
  body: string;
  script: string | null;
  determinedLanguage: "applescript" | "javascript";
}

export function parseMarkdownTipFile(fileContent: string, filePath: string): ParsedTipFile | null {
  try {
    const { data, content: markdownBody } = matter(fileContent);
    const parsed = TipFrontmatterSchema.safeParse(data);
    if (!parsed.success) {
      logger.warn("Markdown tip file has invalid frontmatter", {
        filePath,
        fields: parsed.error.issues.map((issue) => issue.path.join(".")),
      });
      return null;
    }
    const frontmatter = parsed.data;
    const block = extractScriptBlock(markdownBody);
    const script = block?.script ?? null;
    const determinedLanguage = block?.language ?? frontmatter.language ?? "applescript";
    return { frontmatter, body: markdownBody, script, determinedLanguage };
  } catch (e: unknown) {
    logger.error("Failed to parse Markdown tip file", { filePath, error: (e as Error).message });
    return null;
  }
}

export interface LoadedKnowledgePath {
  categories: { id: KnowledgeCategory; description?: string; tipCount: number }[];
  tips: ScriptingTip[];
  sharedHandlers: SharedHandler[];
}

// Loads tips, categories, and shared handlers from a given base knowledge base path.
export async function loadTipsAndHandlersFromPath(
  basePath: string,
  isLocalKb: boolean,
): Promise<LoadedKnowledgePath> {
  logger.info(`Loading knowledge data from path: ${basePath} (isLocal: ${isLocalKb})`);

  const loadedCategories: LoadedKnowledgePath["categories"] = [];
  const loadedTips: ScriptingTip[] = [];
  const loadedSharedHandlers: SharedHandler[] = [];
  const encounteredTipIdsThisPath = new Set<string>(); // Track IDs within this path to warn for local duplicates too

  async function findTipsRecursively(
    currentScanPath: string,
    categoryId: KnowledgeCategory,
  ): Promise<ScriptingTip[]> {
    logger.debug("Recursively scanning directory for tips", { currentScanPath, categoryId });

    let entries: import("node:fs").Dirent[];
    try {
      entries = await fs.readdir(currentScanPath, { withFileTypes: true });
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
        // Don't log ENOENT loudly, it might be expected
        logger.warn("Failed to read directory in findTipsRecursively, skipping.", {
          currentScanPath,
          categoryId,
          errorMessage: error instanceof Error ? error.message : String(error),
          isLocalKb,
        });
      }
      return [];
    }

    const currentLevelFiles: ScriptingTip[] = [];

    for (const entry of entries) {
      const entryPath = path.join(currentScanPath, entry.name);

      try {
        if (entry.isDirectory()) {
          const subDirResult = await findTipsRecursively(entryPath, categoryId);
          currentLevelFiles.push(...subDirResult);
        } else if (entry.isFile() && entry.name.endsWith(".md") && !entry.name.startsWith("_")) {
          let fileContent: string;
          try {
            fileContent = await fs.readFile(entryPath, "utf-8");
          } catch (fileReadError) {
            logger.warn("Failed to read file in findTipsRecursively, skipping file.", {
              entryPath,
              categoryId,
              errorMessage:
                fileReadError instanceof Error ? fileReadError.message : String(fileReadError),
            });
            continue;
          }

          const parsedFile = parseMarkdownTipFile(fileContent, entryPath);

          if (parsedFile) {
            const fm = parsedFile.frontmatter;
            const baseName = path
              .basename(entry.name, ".md")
              .replace(/^\d+[_.-]?\s*/, "")
              .replace(/\s+/g, "_")
              .toLowerCase();
            const relativePathFromCategory = path.relative(
              path.join(basePath, categoryId),
              path.dirname(entryPath),
            );
            const pathPrefix =
              relativePathFromCategory && relativePathFromCategory !== "."
                ? `${relativePathFromCategory.replace(/\//g, "_").replace(/\\/g, "_")}_`
                : "";
            const tipId = fm.id || `${categoryId}_${pathPrefix}${baseName}`;

            if (encounteredTipIdsThisPath.has(tipId)) {
              logger.warn(
                "Duplicate Tip ID found within the same processing path. Check for conflicting frontmatter IDs or filenames.",
                { tipId, filePath: entryPath, basePath },
              );
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
                keywords: Array.isArray(fm.keywords)
                  ? fm.keywords.map(String)
                  : fm.keywords
                    ? [String(fm.keywords)]
                    : [],
                notes: fm.notes,
                filePath: entryPath,
                isComplex: fm.isComplex ?? parsedFile.script.length > 250,
                argumentsPrompt: fm.argumentsPrompt,
                isLocal: isLocalKb,
              };
              currentLevelFiles.push(newTip);
              logger.debug("Found scriptable tip", { tipId, categoryId, isLocalKb });
            } else {
              logger.debug("Conceptual tip (no script block)", {
                title: fm.title,
                path: entryPath,
                isLocalKb,
              });
            }
          }
        }
      } catch (entryError) {
        logger.warn("Error processing entry in findTipsRecursively, skipping entry.", {
          entryPath,
          categoryId,
          isLocalKb,
          errorMessage: entryError instanceof Error ? entryError.message : String(entryError),
        });
      }
    }
    return currentLevelFiles;
  }

  for (const directory of SHARED_HANDLER_DIRECTORIES) {
    const sharedHandlersPath = path.join(basePath, directory);
    try {
      const handlerFiles = await fs.readdir(sharedHandlersPath, { withFileTypes: true });
      for (const handlerFile of handlerFiles) {
        if (
          handlerFile.isFile() &&
          (handlerFile.name.endsWith(".applescript") || handlerFile.name.endsWith(".js"))
        ) {
          const filePath = path.join(sharedHandlersPath, handlerFile.name);
          const content = await fs.readFile(filePath, "utf-8");
          const handlerName = path.basename(handlerFile.name, path.extname(handlerFile.name));
          const language = handlerFile.name.endsWith(".js") ? "javascript" : "applescript";

          if (
            loadedSharedHandlers.some(
              (handler) => handler.name === handlerName && handler.language === language,
            )
          )
            continue;
          loadedSharedHandlers.push({
            name: handlerName,
            content,
            filePath,
            language,
            isLocal: isLocalKb,
          });
          logger.debug("Loaded shared handler", { name: handlerName, language, isLocalKb });
        }
      }
    } catch (e: unknown) {
      const error = e as NodeJS.ErrnoException;
      if (error.code !== "ENOENT") {
        logger.warn("Error reading shared-handlers directory. Skipping.", {
          path: sharedHandlersPath,
          error: error.message,
          isLocalKb,
        });
      } else {
        logger.debug("shared-handlers directory not found, normal for some KBs.", {
          path: sharedHandlersPath,
          isLocalKb,
        });
      }
    }
  }

  let categoryDirEntries: import("node:fs").Dirent[];
  try {
    categoryDirEntries = await fs.readdir(basePath, { withFileTypes: true });
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT" || !isLocalKb) {
      logger.warn("Failed to read base directory for categories, skipping this path.", {
        basePath,
        isLocalKb,
        errorMessage: error instanceof Error ? error.message : String(error),
      });
    }
    return { categories: [], tips: [], sharedHandlers: [] }; // Return empty if base dir unreadable
  }

  for (const categoryDirEntry of categoryDirEntries) {
    if (
      categoryDirEntry.isDirectory() &&
      !SHARED_HANDLER_DIRECTORIES.includes(categoryDirEntry.name)
    ) {
      const categoryId = categoryDirEntry.name;
      const categoryPath = path.join(basePath, categoryId);
      let categoryDescription: string | undefined;
      const categoryInfoPath = path.join(categoryPath, "_category_info.md");

      try {
        const catInfoContent = await fs.readFile(categoryInfoPath, "utf-8");
        const { data } = matter(catInfoContent);
        if (data?.description && typeof data.description === "string") {
          categoryDescription = data.description;
        }
      } catch {
        /* No _category_info.md or error parsing, use default. */
      }

      const categoryScanResults = await findTipsRecursively(categoryPath, categoryId);
      loadedTips.push(...categoryScanResults);

      if (categoryScanResults.length > 0 || categoryDescription !== undefined) {
        loadedCategories.push({
          id: categoryId,
          description: categoryDescription,
          tipCount: categoryScanResults.length,
        });
        logger.debug("Processed category from path", {
          categoryId,
          tipCount: categoryScanResults.length,
          isLocalKb,
        });
      }
    }
  }
  return { categories: loadedCategories, tips: loadedTips, sharedHandlers: loadedSharedHandlers };
}
