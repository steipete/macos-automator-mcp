import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { ExecuteScriptInputSchema, GetScriptingTipsInputSchema } from "./schemas.js";
import { executeScript } from "./executeScript.js";
import { getScriptingTipsService } from "./services/knowledgeBaseService.js";

export function registerTools(server: McpServer, takeServerInfo: () => string | undefined): void {
  server.registerTool(
    "execute_script",
    {
      annotations: {
        title: "Execute Script",
        destructiveHint: true,
      },
      description: `Automate macOS tasks using AppleScript or JXA (JavaScript for Automation) to control applications like Terminal, Chrome, Safari, Finder, etc.

**1. Script Source (Choose one):**
*   \`kb_script_id\` (string): **Preferred.** Executes a pre-defined script from the knowledge base by its ID. Use \`get_scripting_tips\` to find IDs and inputs. Supports placeholder substitution via \`input_data\` or \`arguments\`. Ex: \`kb_script_id: "safari_get_front_tab_url"\`.
*   \`script_content\` (string): Executes raw AppleScript/JXA code. Good for simple or dynamic scripts. Ex: \`script_content: "tell application \\"Finder\\" to empty trash"\`.
*   \`script_path\` (string): Executes a script from an absolute POSIX path on the server. Ex: \`/Users/user/myscripts/myscript.applescript\`.

**2. Script Inputs (Optional):**
*   \`input_data\` (JSON object): For \`kb_script_id\`, provides named inputs (e.g., \`--MCP_INPUT:keyName\`). Values (string, number, boolean, simple array/object) are auto-converted. Ex: \`input_data: { "folder_name": "New Docs" }\`.
*   \`arguments\` (array of strings): For \`script_path\` (passes to \`on run argv\` / \`run(argv)\`). For \`kb_script_id\`, used for positional args (e.g., \`--MCP_ARG_1\`).

**3. Execution Options (Optional):**
*   \`language\` ('applescript' | 'javascript'): Specify for \`script_content\`/\`script_path\` (default: 'applescript'). Inferred for \`kb_script_id\`.
*   \`timeout_seconds\` (integer, optional, default: 60): Sets the maximum time (in seconds) the script is allowed to run. Increase for potentially long-running operations.
*   \`output_format_mode\` (enum, optional, default: 'auto'): Controls \`osascript\` output formatting.
    *   \`'auto'\`: Smart default - resolves to \`'human_readable'\` for AppleScript and \`'direct'\` for JXA.
    *   \`'human_readable'\`: For AppleScript, uses \`-s h\` flag.
    *   \`'structured_error'\`: For AppleScript, uses \`-s s\` flag (structured errors).
    *   \`'structured_output_and_error'\`: For AppleScript, uses \`-s ss\` flag (structured output & errors).
    *   \`'direct'\`: No special output flags (recommended for JXA).
*   \`include_executed_script_in_output\` (boolean, optional, default: false): If \`true\`, the final script content (after any placeholder substitutions) or script path that was executed will be included in the response. This is useful for debugging and understanding exactly what was run. Defaults to false.
*   \`include_substitution_logs\` (boolean, default: false): For \`kb_script_id\`, includes detailed placeholder substitution logs.
*   \`report_execution_time\` (boolean, optional, default: false): If \`true\`, an additional message with the formatted script execution time will be included in the response. Defaults to false.
`,
      inputSchema: ExecuteScriptInputSchema,
    },
    (args) => executeScript(args, takeServerInfo),
  );

  server.registerTool(
    "get_scripting_tips",
    {
      annotations: {
        title: "Get Scripting Tips",
        readOnlyHint: true,
      },
      description: `Discover how to automate any app on your Mac with this comprehensive knowledge base of AppleScript/JXA tips and runnable scripts. This tool is essential for discovery and should be the FIRST CHOICE when aiming to automate macOS tasks, especially those involving common applications or system functions, before attempting to write scripts from scratch. It helps identify pre-built, tested solutions, effectively teaching you how to control virtually any aspect of your macOS experience.

**Primary Use Cases & Parameters:**

*   **Discovering Solutions (Use \`search_term\`):**
    *   Parameter: \`search_term\` (string, optional).
    *   Functionality: Performs a fuzzy search across all tip titles, descriptions, keywords, script content, and IDs. Ideal for natural language queries like "how to..." (e.g., \`search_term: "how do I get the current Safari URL and title?"\`). This is the most common way to find relevant tips.
    *   Output: Returns a list of matching tips in Markdown format.

*   **Limiting Search Results (Use \`limit\`):**
    *   Parameter: \`limit\` (integer, optional, default: 10).
    *   Functionality: Specifies the maximum number of script tips to return when using \`search_term\` or browsing a specific \`category\` (without \`list_categories: true\`). Does not apply if \`list_categories\` is true.

*   **Browsing by Category (Use \`category\`):**
    *   Parameter: \`category\` (string, optional).
    *   Functionality: Shows tips from a specific category. Combine with \`limit\` to control result count.
    *   Example: \`category: "01_intro"\` or \`category: "07_browsers/chrome"\`.

*   **Listing All Categories (Use \`list_categories: true\`):**
    *   Parameter: \`list_categories\` (boolean, optional).
    *   Functionality: Returns a structured list of all available categories with their descriptions. This helps you understand what automation areas are covered.
    *   Output: Category tree in Markdown format.

*   **Refreshing Database (Use \`refresh_database: true\`):**
    *   Parameter: \`refresh_database\` (boolean, optional).
    *   Functionality: Forces a reload of the knowledge base if new scripts have been added. Typically not needed as the database refreshes automatically.

**Best Practices:**
1. **Always start with search**: Use natural language queries to find solutions (e.g., "send email from Mail app").
2. **Browse categories when exploring**: Use \`list_categories: true\` to see available automation areas.
3. **Use specific IDs for execution**: Once you find a script, use its ID with \`execute_script\` tool for precise execution.`,
      inputSchema: GetScriptingTipsInputSchema,
    },
    async (args: unknown) => {
      const input = GetScriptingTipsInputSchema.parse(args);

      let content = await getScriptingTipsService(input);

      const serverInfo = takeServerInfo();
      if (serverInfo) content += "\n\n" + serverInfo;

      return {
        content: [
          {
            type: "text",
            text: content,
          },
        ],
      };
    },
  );
}
