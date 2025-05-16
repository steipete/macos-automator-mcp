import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { report, printValidationReport, logErrorToReport, logWarningToReport } from './kbReport.js';
import { processKnowledgeBasePath } from './kbPathProcessor.js';

// Constants
const KNOWLEDGE_BASE_ROOT_DIR_NAME = 'knowledge_base';
const EMBEDDED_KNOWLEDGE_BASE_DIR = path.resolve(process.cwd(), KNOWLEDGE_BASE_ROOT_DIR_NAME);

const LOCAL_KB_ENV_VAR = 'LOCAL_KB_PATH';
const DEFAULT_LOCAL_KB_PATH = path.join(os.homedir(), '.macos-automator', 'knowledge_base');

function getLocalKnowledgeBasePath(cliArgPath?: string): string {
  if (cliArgPath) {
    console.info(`Using custom local knowledge base path from CLI argument: ${cliArgPath}`);
    return path.resolve(cliArgPath.startsWith('~') ? cliArgPath.replace('~', os.homedir()) : cliArgPath);
  }
  const envPath = process.env[LOCAL_KB_ENV_VAR];
  if (envPath) {
    console.info(`Using custom local knowledge base path from LOCAL_KB_PATH env var: ${envPath}`);
    return path.resolve(envPath.startsWith('~') ? envPath.replace('~', os.homedir()) : envPath);
  }
  console.info(`Using default local knowledge base path: ${DEFAULT_LOCAL_KB_PATH}`);
  return DEFAULT_LOCAL_KB_PATH;
}

async function validateKnowledgeBase(): Promise<void> {
  let localKbPathArg: string | undefined;
  const args = process.argv.slice(2);
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--local-kb-path' || args[i] === '-l') {
      if (i + 1 < args.length) {
        localKbPathArg = args[i+1];
        i++;
      } else {
        console.error("Error: --local-kb-path requires a value.");
        process.exit(1);
      }
    }
  }

  await processKnowledgeBasePath(EMBEDDED_KNOWLEDGE_BASE_DIR, false);

  const localKbPathToUse = getLocalKnowledgeBasePath(localKbPathArg);
  try {
      await fs.access(localKbPathToUse);
      await processKnowledgeBasePath(localKbPathToUse, true);
  } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
          console.info(`Local knowledge base path ${localKbPathToUse} not found or not accessible. Skipping local KB validation. This is normal if you haven\'t set one up.`);
      } else {
          console.error(`Error accessing local knowledge base path ${localKbPathToUse}: ${(error as Error).message}`);
          logErrorToReport(localKbPathToUse, `Error accessing local knowledge base: ${(error as Error).message}`, true);
      }
  }

  printValidationReport(report);
}

validateKnowledgeBase().catch(err => {
  console.error("Unhandled error during validation process:", err);
  process.exitCode = 1;
});