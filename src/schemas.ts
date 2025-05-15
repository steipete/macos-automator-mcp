// Zod input schemas 
import { z } from 'zod';

// Placeholder for KNOWN_CATEGORIES. In a real scenario, this might be populated dynamically
// or from a more extensive list. For now, ensure it's not empty for z.enum.
// const KNOWN_CATEGORIES = ['basics', 'finder', 'electron_editors', 'safari', 'chrome'] as const; // Keep for reference or future dynamic population

// Allow any string for category, as they are dynamically loaded from the KB.
const DynamicScriptingKnowledgeCategoryEnum = z.string()
    .describe("Category of AppleScript/JXA tips. Should match a discovered category ID from the knowledge base.");

export const ExecuteScriptInputSchema = z.object({
  scriptContent: z.string().optional()
    .describe("Raw AppleScript/JXA code. Mutually exclusive with scriptPath & kbScriptId."),
  scriptPath: z.string().optional()
    .describe("Absolute POSIX path to a script file. Mutually exclusive with scriptContent & kbScriptId."),
  kbScriptId: z.string().optional()
    .describe("Unique ID of a pre-defined script from the knowledge base. Mutually exclusive with scriptContent & scriptPath. Use 'get_scripting_tips' to find IDs."),
  language: z.enum(['applescript', 'javascript']).optional()
    .describe("Scripting language. Inferred if using kbScriptId. Defaults to 'applescript' if using scriptContent/scriptPath and not specified."),
  arguments: z.array(z.string()).optional().default([])
    .describe("String arguments for scriptPath scripts ('on run argv'). For kbScriptId, used if script is designed for positional string args (see tip's 'argumentsPrompt')."),
  inputData: z.record(z.string(), z.any()).optional() 
    .describe("JSON object providing named input data for kbScriptId scripts designed to accept structured input (see tip's 'argumentsPrompt'). Replaces placeholders like --MCP_INPUT:keyName."),
  timeoutSeconds: z.number().int().positive().optional().default(30)
    .describe("Script execution timeout in seconds."),
  useScriptFriendlyOutput: z.boolean().optional().default(false)
    .describe("Use 'osascript -ss' for script-friendly output."),
  includeExecutedScriptInOutput: z.boolean().optional().default(false)
    .describe("If true, the executed script content (after substitutions) or path will be included in the output."),
  includeSubstitutionLogs: z.boolean().optional().default(false)
    .describe("If true, detailed logs of placeholder substitutions will be included in the output.")
}).refine(data => {
    const sources = [data.scriptContent, data.scriptPath, data.kbScriptId].filter(s => s !== undefined && s !== null && s !== '');
    return sources.length === 1;
}, {
    message: "Exactly one of 'scriptContent', 'scriptPath', or 'kbScriptId' must be provided and be non-empty.",
    path: ["scriptContent", "scriptPath", "kbScriptId"],
});

export type ExecuteScriptInput = z.infer<typeof ExecuteScriptInputSchema>;

export const GetScriptingTipsInputSchema = z.object({
  category: DynamicScriptingKnowledgeCategoryEnum.optional()
    .describe("Specific category of tips. If omitted with no searchTerm, lists all categories."),
  searchTerm: z.string().optional()
    .describe("Keyword to search within tip titles, content, keywords, or IDs."),
  listCategories: z.boolean().optional().default(false)
    .describe("If true, returns only the list of available categories and their descriptions. Overrides other parameters."),
  refreshDatabase: z.boolean().optional().describe("If true, forces a reload of the knowledge base before processing the request.")
});

export type GetScriptingTipsInput = z.infer<typeof GetScriptingTipsInputSchema>;

// Output is always { content: [{ type: "text", text: "string_output" }] }
// No specific Zod schema needed for output beyond what MCP SDK handles. 