export interface ValidationReport {
  totalFilesChecked: number;
  totalTipsParsed: number;
  totalSharedHandlers: number;
  categoriesFound: Set<string>;
  errors: string[];
  warnings: string[];
  fixesApplied: string[]; 
  uniqueTipIds: Set<string>;
  duplicateTipIdsPrimary: string[];
  overriddenTipIdsLocal: string[];
  localOnlyNewTipIds: Set<string>;
  sharedHandlerNames: Set<string>;
  duplicateSharedHandlersPrimary: string[];
  overriddenSharedHandlersLocal: string[];
}

export const report: ValidationReport = {
  totalFilesChecked: 0,
  totalTipsParsed: 0,
  totalSharedHandlers: 0,
  categoriesFound: new Set(),
  errors: [],
  warnings: [],
  fixesApplied: [],
  uniqueTipIds: new Set(),
  duplicateTipIdsPrimary: [],
  overriddenTipIdsLocal: [],
  localOnlyNewTipIds: new Set(),
  sharedHandlerNames: new Set(),
  duplicateSharedHandlersPrimary: [],
  overriddenSharedHandlersLocal: [],
};

export function logErrorToReport(filePath: string, message: string, isLocalKbIssue = false, currentReport: ValidationReport = report) {
  const prefix = isLocalKbIssue ? "LOCAL_KB " : "";
  currentReport.errors.push(`ERROR: ${prefix}[${filePath}] ${message}`);
}

export function logWarningToReport(filePath: string, message: string, isLocalKbIssue = false, currentReport: ValidationReport = report) {
  const prefix = isLocalKbIssue ? "LOCAL_KB " : "";
  currentReport.warnings.push(`WARN: ${prefix}[${filePath}] ${message}`);
}


export function printValidationReport(currentReport: ValidationReport = report) {
  console.log("\n--- Validation Report ---");
  console.log(`Total Files Checked: ${currentReport.totalFilesChecked}`);
  console.log(`Total Scriptable Tips Parsed: ${currentReport.totalTipsParsed}`);
  console.log(`Total Shared Handlers Parsed: ${currentReport.totalSharedHandlers}`);
  console.log(`Categories Found: ${currentReport.categoriesFound.size} (${Array.from(currentReport.categoriesFound).sort().join(', ')})`);
  console.log(`Unique Tip IDs (total): ${currentReport.uniqueTipIds.size}`);
  console.log(`  - From Local KB (new): ${currentReport.localOnlyNewTipIds.size}`);
  console.log(`  - Overridden by Local KB: ${currentReport.overriddenTipIdsLocal.length}`);
  console.log(`Unique Shared Handlers (total): ${currentReport.sharedHandlerNames.size}`);
  console.log(`  - Overridden by Local KB: ${currentReport.overriddenSharedHandlersLocal.length}`);

  if (currentReport.errors.length > 0) {
    console.log(`\n--- ERRORS (${currentReport.errors.length}) ---`);
    for (const err of currentReport.errors) {
        console.error(err);
    }
  } else {
    console.log("\n--- ERRORS (0) ---");
    console.log("No critical errors found. Great job!");
  }

  if (currentReport.warnings.length > 0) {
    console.log(`\n--- WARNINGS (${currentReport.warnings.length}) ---`);
    for (const warn of currentReport.warnings) {
        console.warn(warn);
    }
  } else {
    console.log("\n--- WARNINGS (0) ---");
  }

  if (currentReport.fixesApplied.length > 0) {
    console.log(`\n--- AUTO-FIXES APPLIED (${new Set(currentReport.fixesApplied).size} files) ---`);
    console.log("Specific auto-fixes were logged during processing (currently disabled for file writes).");
  } else {
    console.log("\n--- AUTO-FIXES APPLIED (0) ---");
  }

  if (currentReport.duplicateTipIdsPrimary.length > 0) {
    console.warn(`\n--- DUPLICATE TIP IDs IN PRIMARY KB (${currentReport.duplicateTipIdsPrimary.length}) ---`);
    console.warn("The following Tip IDs were duplicated in the primary KB. Ensure each explicit 'id' in frontmatter is unique, and filenames within categories also lead to unique generated IDs:");
    for (const id of currentReport.duplicateTipIdsPrimary) {
        console.warn(`  - ${id}`);
    }
  }
  if (currentReport.duplicateSharedHandlersPrimary.length > 0) {
    console.warn(`\n--- DUPLICATE SHARED HANDLERS IN PRIMARY KB (${currentReport.duplicateSharedHandlersPrimary.length}) ---`);
    console.warn("The following Shared Handler names (name_language) were duplicated in the primary KB. Ensure unique names:");
    for (const id of currentReport.duplicateSharedHandlersPrimary) {
        console.warn(`  - ${id}`);
    }
  }
  
  if (currentReport.overriddenTipIdsLocal.length > 0) {
      console.info(`\n--- OVERRIDDEN TIPS BY LOCAL KB (${currentReport.overriddenTipIdsLocal.length}) ---`);
      console.info("The following Tip IDs from the primary KB were overridden by a local version:");
      for (const id of currentReport.overriddenTipIdsLocal.sort()) {
          console.info(`  - ${id}`);
      }
  }
   if (currentReport.overriddenSharedHandlersLocal.length > 0) {
      console.info(`\n--- OVERRIDDEN SHARED HANDLERS BY LOCAL KB (${currentReport.overriddenSharedHandlersLocal.length}) ---`);
      console.info("The following Shared Handlers from the primary KB were overridden by a local version:");
      for (const id of currentReport.overriddenSharedHandlersLocal.sort()) {
          console.info(`  - ${id}`);
      }
  }

  console.log("\nValidation complete.");
  if (currentReport.errors.length > 0 || currentReport.duplicateTipIdsPrimary.length > 0 || currentReport.duplicateSharedHandlersPrimary.length > 0) {
    process.exitCode = 1;
  }
} 