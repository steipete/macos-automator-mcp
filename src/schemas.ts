// Zod input schemas 
import { z } from 'zod';

// Placeholder for KNOWN_CATEGORIES. In a real scenario, this might be populated dynamically
// or from a more extensive list. For now, ensure it's not empty for z.enum.
// const KNOWN_CATEGORIES = ['basics', 'finder', 'electron_editors', 'safari', 'chrome'] as const; // Keep for reference or future dynamic population

// Allow any string for category, as they are dynamically loaded from the KB.
const DynamicScriptingKnowledgeCategoryEnum = z.string()
    .describe("Category of AppleScript/JXA tips. Should match a discovered category ID from the knowledge base.");

export const ExecuteScriptInputSchema = z.object({
  kb_script_id: z.string().optional().describe(
    'The ID of a knowledge base script to execute. Replaces script_content and script_path if provided.',
  ),
  script_content: z.string().optional().describe(
    'The content of the script to execute. Required if kb_script_id or script_path is not provided.',
  ),
  script_path: z.string().optional().describe(
    'The path to the script file to execute. Required if kb_script_id or script_content is not provided.',
  ),
  arguments: z.array(z.string()).optional().describe(
    'Optional arguments to pass to the script. For AppleScript, these are passed to the main `run` handler. For JXA, these are passed to the `run` function.',
  ),
  input_data: z.record(z.unknown()).optional().describe(
    'Optional JSON object to provide named inputs for --MCP_INPUT placeholders in knowledge base scripts.',
  ),
  language: z.enum(['applescript', 'javascript']).optional().describe(
    "Specifies the scripting language. Crucial for `script_content` and `script_path` if not 'applescript'. Defaults to 'applescript'. Inferred if using `kb_script_id`.",
  ),
  timeout_seconds: z.number().int().optional().default(60).describe(
    'The timeout for the script execution in seconds. Defaults to 60.',
  ),
  use_script_friendly_output: z.boolean().optional().default(false).describe(
    'If true, uses osascript -ss flag for AppleScript for more structured output. Defaults to false.',
  ),
  report_execution_time: z.boolean().optional().default(false).describe(
    'If true, the tool will return an additional message containing the formatted script execution time. Defaults to false.',
  ),
  include_executed_script_in_output: z.boolean().optional().default(false)
    .describe("If true, the executed script content (after substitutions) or path will be included in the output."),
  include_substitution_logs: z.boolean().optional().default(false)
    .describe("If true, detailed logs of placeholder substitutions will be included in the output.")
}).refine(data => {
    const sources = [data.script_content, data.script_path, data.kb_script_id].filter(s => s !== undefined && s !== null && s !== '');
    return sources.length === 1;
}, {
    message: "Exactly one of 'script_content', 'script_path', or 'kb_script_id' must be provided and be non-empty.",
    path: ["script_content", "script_path", "kb_script_id"],
});

export type ExecuteScriptInput = z.infer<typeof ExecuteScriptInputSchema>;

export const GetScriptingTipsInputSchema = z.object({
  category: DynamicScriptingKnowledgeCategoryEnum.optional()
    .describe("Specific category of tips. If omitted with no `search_term`, lists all categories."),
  search_term: z.string().optional()
    .describe("Keyword to search within tip titles, content, keywords, or IDs."),
  list_categories: z.boolean().optional().default(false)
    .describe("If true, returns only the list of available categories and their descriptions. Overrides other parameters."),
  refresh_database: z.boolean().optional().describe("If true, forces a reload of the knowledge base before processing the request."),
  limit: z.number().int().positive().optional().default(10)
    .describe("Maximum number of results to return. Default is 10."),
});

export type GetScriptingTipsInput = z.infer<typeof GetScriptingTipsInputSchema>;

// Output is always { content: [{ type: "text", text: "string_output" }] }
// No specific Zod schema needed for output beyond what MCP SDK handles. 