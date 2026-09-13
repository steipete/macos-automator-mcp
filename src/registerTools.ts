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
      description: `Run AppleScript or JavaScript for Automation (JXA) on macOS with the host user's privileges.
Choose exactly one source: kb_script_id (discover IDs with get_scripting_tips), inline script_content, or an absolute script_path.
Knowledge-base scripts accept named input_data and positional arguments for placeholders; file scripts receive arguments in their run handler.
Use language for inline/file JXA. Optional fields control timeout, output formatting, execution timing, and diagnostic source/substitution output.`,
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
      description: `Discover AppleScript/JXA tips before writing a script from scratch. Search titles, IDs, keywords, descriptions and source with search_term; narrow by a discovered category ID and limit.
Use list_categories to browse categories. Results include runnable IDs for execute_script and any required inputs.
Use refresh_database after editing knowledge-base files; the index is cached until explicitly refreshed or the server restarts.`,
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
