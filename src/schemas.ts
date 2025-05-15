// Zod input schemas 
import { z } from 'zod';

export const ExecuteScriptInputSchema = z.object({
  scriptContent: z.string().optional()
    .describe("The raw AppleScript or JXA code to execute. Mutually exclusive with scriptPath."),
  scriptPath: z.string().optional()
    .describe("The absolute POSIX path to a script file (.scpt, .applescript, .js for JXA) on the server. Mutually exclusive with scriptContent."),
  language: z.enum(['applescript', 'javascript']).optional().default('applescript')
    .describe("The scripting language to use. Defaults to 'applescript'."),
  arguments: z.array(z.string()).optional().default([])
    .describe("An array of string arguments to pass to the script file (primarily for scripts run via scriptPath). These are available in the 'on run argv' handler in AppleScript or 'run(argv)' function in JXA."),
  timeoutSeconds: z.number().int().positive().optional().default(30)
    .describe("Maximum execution time for the script in seconds. Defaults to 30 seconds."),
  useScriptFriendlyOutput: z.boolean().optional().default(false)
    .describe("If true, instructs 'osascript' to use script-friendly output format (-ss flag). This can affect how lists and other data types are returned. Defaults to false (human-readable output).")
}).refine(data => {
    return (data.scriptContent !== undefined && data.scriptPath === undefined) ||
           (data.scriptContent === undefined && data.scriptPath !== undefined);
}, {
    message: "Exactly one of 'scriptContent' or 'scriptPath' must be provided.",
    path: ["scriptContent", "scriptPath"], // Indicate which fields are involved in the refinement
});

export type ExecuteScriptInput = z.infer<typeof ExecuteScriptInputSchema>;

// Output is always { content: [{ type: "text", text: "string_output" }] }
// No specific Zod schema needed for output beyond what MCP SDK handles. 