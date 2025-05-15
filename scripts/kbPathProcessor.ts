import fs from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter';
import { report, logErrorToReport, logWarningToReport } from './kbReport.js';
import { validateTipFile, validateSharedHandlerFile } from './kbFileValidator.js';

// Constants moved from validate-kb.ts that are relevant here
const SHARED_HANDLERS_DIR_NAME = '_shared_handlers';

async function validateTipFilesRecursively(
  currentPath: string,
  categoryId: string,
  kbPathToUse: string,
  isLocalKbScan: boolean,
  recursive = true
): Promise<void> {
  try {
    const entries = await fs.readdir(currentPath, { withFileTypes: true });
    
    for (const entry of entries) {
      const entryPath = path.join(currentPath, entry.name);
      
      if (entry.isDirectory() && recursive) {
        if (!entry.name.startsWith('_')) {
          await validateTipFilesRecursively(entryPath, categoryId, kbPathToUse, isLocalKbScan);
        }
      } else if (entry.isFile() && entry.name.endsWith('.md') && !entry.name.startsWith('_')) {
        await validateTipFile(entryPath, categoryId, kbPathToUse, isLocalKbScan);
      }
    }
  } catch (error) {
    if (!isLocalKbScan || (error as NodeJS.ErrnoException)?.code !== 'ENOENT') {
        logErrorToReport(currentPath, `Failed to read directory: ${(error as Error).message}`, isLocalKbScan);
    } else {
        // console.debug(`Optional category directory not found in local KB: ${currentPath}`);
    }
  }
}

export async function processKnowledgeBasePath(basePathToScan: string, isLocal: boolean): Promise<void> {
  console.info(`Validating knowledge base in: ${basePathToScan} ${isLocal ? '(Local)' : '(Embedded)'}`);
  try {
    const categoryDirEntries = await fs.readdir(basePathToScan, { withFileTypes: true });

    for (const categoryDirEntry of categoryDirEntries) {
      if (categoryDirEntry.isDirectory()) {
        const categoryId = categoryDirEntry.name;
        const categoryPath = path.join(basePathToScan, categoryId);

        if (categoryId === SHARED_HANDLERS_DIR_NAME) {
            try {
                const handlerFiles = await fs.readdir(categoryPath, { withFileTypes: true });
                for (const handlerFile of handlerFiles) {
                    if (handlerFile.isFile() && (handlerFile.name.endsWith('.applescript') || handlerFile.name.endsWith('.js'))) {
                        await validateSharedHandlerFile(path.join(categoryPath, handlerFile.name), isLocal);
                    }
                }
            } catch (error) { 
                if (!isLocal || (error as NodeJS.ErrnoException)?.code !== 'ENOENT') {
                    logErrorToReport(categoryPath, `Failed to read _shared_handlers directory: ${(error as Error).message}`, isLocal);
                } else {
                    // console.debug(`Optional _shared_handlers directory not found in local KB: ${categoryPath}`);
                }
            }
            continue;
        }

        const catInfoPath = path.join(categoryPath, '_category_info.md');
        try {
            await fs.access(catInfoPath, fs.constants.R_OK);
            report.totalFilesChecked++;
            const catInfoContent = await fs.readFile(catInfoPath, 'utf-8');
            const { data: catFm } = matter(catInfoContent);
            if (!catFm.description || typeof catFm.description !== 'string' || catFm.description.trim() === "") {
                logWarningToReport(catInfoPath, "Missing or empty 'description' in _category_info.md frontmatter.", isLocal);
            }
        } catch {
            if (!isLocal) {
                logWarningToReport(categoryPath, "_category_info.md not found or not readable. Category description will be default.", false);
            }
        }
        await validateTipFilesRecursively(categoryPath, categoryId, basePathToScan, isLocal);
      }
    }
  } catch (error: unknown) {
    if (error instanceof Error && 'code' in error && (error as NodeJS.ErrnoException).code === 'ENOENT') {
        if (!isLocal) { 
            console.error(`Required knowledge base directory NOT FOUND at ${basePathToScan}.`);
            logErrorToReport(basePathToScan, `Failed to read knowledge base structure: ${error.message}`, false);
        } else {
            console.warn(`Local knowledge base directory not found at ${basePathToScan}. Skipping.`);
            logWarningToReport(basePathToScan, `Local KB directory not found. This is okay if not using one.`, true);
        }
    } else if (error instanceof Error) {
        logErrorToReport(basePathToScan, `Failed to read knowledge base structure: ${error.message}`, isLocal);
    } else {
        logErrorToReport(basePathToScan, `Failed to read knowledge base structure: Unknown error occurred`, isLocal);
    }
  }
} 