---
title: "How to Use This Knowledge Base"
category: "00_readme_and_conventions" # Use category field for directory
id: conventions_how_to_use_kb
description: "Explains how to query and use the tips provided by this MCP server."
keywords: ["help", "meta", "documentation", "get_scripting_tips", "execute_script"]
language: applescript # Language of the script block, or 'plaintext' if no script
isComplex: false
---

This knowledge base provides AppleScript and JXA examples for macOS automation.

**Querying Tips:**
Use the `get_scripting_tips` tool:
- To list all categories: `{"toolName": "macos_automator:get_scripting_tips", "arguments": { "input": { "listCategories": true } } }`
- For tips in a specific category (e.g., "finder"): `{"toolName": "macos_automator:get_scripting_tips", "arguments": { "input": { "category": "finder" } } }`
- To search for a term (e.g., "URL" in "safari" category): `{"toolName": "macos_automator:get_scripting_tips", "arguments": { "input": { "category": "safari", "searchTerm": "URL" } } }`

**Executing Scripts:**
Use the `execute_script` tool:
1.  **Inline Script:** Provide code in `scriptContent`.
    ```json
    {
      "toolName": "macos_automator:execute_script",
      "arguments": { "input": { "scriptContent": "display dialog \"Hello\"" } }
    }
    ```
2.  **From Knowledge Base by ID:** If a tip has a "Runnable ID", use `knowledgeBaseScriptId`.
    ```json
    {
      "toolName": "macos_automator:execute_script",
      "arguments": {
        "input": {
          "knowledgeBaseScriptId": "safari_get_front_tab_url",
          // "inputData": { "someKey": "someValue" } // If the KB script expects it
        }
      }
    }
    ```
    Refer to the tip's "Inputs Needed" or "argumentsPrompt" (via `get_scripting_tips`) for required `inputData` or `arguments`.
3.  **From File:** Provide an absolute `scriptPath` to a file on the server.

**Placeholder Conventions for KB Scripts:**
- Use `--MCP_INPUT:yourKeyName` for values from the `inputData` object.
- Use `--MCP_ARG_1`, `--MCP_ARG_2` for values from the `arguments` array.
The server will substitute these before execution. Values are generally escaped as AppleScript strings.

```applescript
-- This is a conceptual example, not a runnable script.
-- It shows how placeholders MIGHT be used in a KB script.
(*
  This is a placeholder script demonstrating argument usage.
  It would be stored in the knowledge base.
*)
--MCP_INPUT:targetApplication
--MCP_ARG_1 -- This would be the message for the dialog

on runWithInput(inputData, argsList)
  set appName to inputData's targetApplication
  set dialogMessage to item 1 of argsList

  tell application appName
    activate
    display dialog dialogMessage
  end tell
end runWithInput
```
END_TIP