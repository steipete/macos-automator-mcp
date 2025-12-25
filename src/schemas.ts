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
  output_format_mode: z.enum(['auto', 'human_readable', 'structured_error', 'structured_output_and_error', 'direct']).optional().default('auto').describe(
    "Controls osascript output formatting. \n'auto': (Default) Smart selection based on language (AppleScript: human_readable, JXA: direct). \n'human_readable': AppleScript -s h. \n'structured_error': AppleScript -s s. \n'structured_output_and_error': AppleScript -s ss. \n'direct': No -s flags (recommended for JXA)."
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

// AX Query Input Schema
export const AXQueryInputSchema = z.object({
    command: z.enum(['query', 'perform']).describe('The operation to perform. (Formerly cmd)'),

    // Fields for lenient parsing if locator is flattened
    app: z.string().optional().describe('Top-level app name (used if locator is a string and app is not specified within a locator object)'),
    role: z.string().optional().describe('Top-level role (used if locator is a string/flattened)'),
    match: z.record(z.string()).optional().describe('Top-level match (used if locator is a string/flattened)'),

    locator: z.union([
        z.object({
            app: z.string().describe('Bundle ID or display name of the application to query'),
            role: z.string().describe('Accessibility role to match, e.g., "AXButton", "AXStaticText"'),
            match: z.record(z.string()).describe('Attributes to match for the element'),
            navigation_path_hint: z.array(z.string()).optional().describe('Optional path to navigate within the application hierarchy, e.g., ["window[1]", "toolbar[1]"]. (Formerly pathHint)'),
        }),
        z.string().describe('Bundle ID or display name of the application to query (used if role/match are provided at top level and this string serves as the app name)')
    ]).describe('Specifications to find the target element(s). Can be a full locator object or just an app name string (if role/match are top-level).'),

    return_all_matches: z.boolean().optional().describe('When true, returns all matching elements rather than just the first match. Default is false. (Formerly multi)'),
    attributes_to_query: z.array(z.string()).optional().describe('Attributes to query for matched elements. If not provided, common attributes will be included. (Formerly attributes)'),
    required_action_name: z.string().optional().describe('Filter elements to only those supporting this action, e.g., "AXPress". (Formerly requireAction)'),
    action_to_perform: z.string().optional().describe('Only used with command: "perform" - The action to perform on the matched element. (Formerly action)'),
    report_execution_time: z.boolean().optional().default(false).describe(
      'If true, the tool will return an additional message containing the formatted script execution time. Defaults to false.',
    ),
    limit: z.number().int().positive().optional().default(500).describe(
      'Maximum number of lines to return in the output. Defaults to 500. Output will be truncated if it exceeds this limit.'
    ),
    max_elements: z.number().int().positive().optional().describe(
      'For return_all_matches: true queries, specifies the maximum number of UI elements to fully process and return. If omitted, a default (e.g., 200) is used internally by the ax binary. Helps control performance for very large result sets.'
    ),
    debug_logging: z.boolean().optional().default(false).describe(
      'If true, enables detailed debug logging from the ax binary, which will be returned as part of the response. Defaults to false.'
    ),
    output_format: z.enum(['smart', 'verbose', 'text_content']).optional().default('smart').describe(
      "Controls the format and verbosity of the attribute output. \n" +
      "'smart': (Default) Omits empty/placeholder values. Key-value pairs. \n" +
      "'verbose': Includes all attributes, even empty/placeholders. Key-value pairs. Useful for debugging. \n" +
      "'text_content': Returns only concatenated text values of common textual attributes (e.g., AXValue, AXTitle, AXDescription). No keys. Ideal for fast text extraction."
    )
}).refine(
    (data) => {
        // If command is 'perform', action_to_perform must be provided
        return data.command !== 'perform' || (!!data.action_to_perform);
    },
    {
        message: "When command is 'perform', an action_to_perform must be provided",
        path: ["action_to_perform"],
    }
).superRefine((data, ctx) => {
    if (typeof data.locator === 'string') { // Case 1: locator is a string (app name)
        if (data.role === undefined) {
            ctx.addIssue({
                code: z.ZodIssueCode.custom,
                message: "If 'locator' is a string (app name), top-level 'role' must be provided.",
                path: ['role'], // Path refers to the top-level role
            });
        }
        // data.match will default to {} if undefined later in the handler
        // data.app (top-level) is ignored if data.locator (string) is present, as the locator string *is* the app name.
    } else { // Case 2: locator is an object
        // Ensure top-level app, role, match are not present if locator is a full object, to avoid ambiguity.
        // This is a stricter interpretation. Alternatively, we could prioritize the locator object's fields.
        if (data.app !== undefined) {
            ctx.addIssue({
                code: z.ZodIssueCode.custom,
                message: "Top-level 'app' should not be provided if 'locator' is a detailed object. Define 'app' inside the 'locator' object.",
                path: ['app'],
            });
        }
        if (data.role !== undefined) {
            ctx.addIssue({
                code: z.ZodIssueCode.custom,
                message: "Top-level 'role' should not be provided if 'locator' is a detailed object. Define 'role' inside the 'locator' object.",
                path: ['role'],
            });
        }
        if (data.match !== undefined) {
            ctx.addIssue({
                code: z.ZodIssueCode.custom,
                message: "Top-level 'match' should not be provided if 'locator' is a detailed object. Define 'match' inside the 'locator' object.",
                path: ['match'],
            });
        }
    }
});

export type AXQueryInput = z.infer<typeof AXQueryInputSchema>;

// Output is always { content: [{ type: "text", text: "string_output" }] }
// No specific Zod schema needed for output beyond what MCP SDK handles. 