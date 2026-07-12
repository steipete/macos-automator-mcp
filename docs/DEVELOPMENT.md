# Development Guide for macOS Automator MCP

This guide provides instructions for setting up the development environment, running the server locally, understanding the knowledge base, and contributing to the project.

## Getting Started

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/steipete/macos-automator-mcp.git
    cd macos-automator-mcp
    ```

2.  **Install dependencies:**

    ```bash
    pnpm install
    ```

3.  **Build the project:**

    ```bash
    pnpm run build
    ```

4.  **Run in development mode:**
    ```bash
    pnpm run dev
    ```

## Running Locally for Development

- **Using start.sh:**

  ```bash
  ./start.sh
  ```

- **Direct Execution:**

  ```bash
  node dist/server.js
  ```

- **Testing with MCP Client:**
  Ensure the server is running and accessible via the MCP client.

- **Installing the local CLI globally:**
  ```bash
  pnpm add --global .
  ```

## Project Structure Overview

```
macos-automator-mcp/
├── src/                  # Source code
│   ├── server.ts         # Main server logic & MCP tool definitions
│   ├── AppleScriptExecutor.ts # Core osascript execution
│   ├── logger.ts         # Logging utility
│   ├── schemas.ts        # Zod input schemas
│   └── (cli.ts)          # Optional separate CLI entry if needed
├── dist/                 # Compiled JavaScript output
├── docs/                 # Documentation and screenshots
├── .github/workflows/    # GitHub Actions workflows (CI)
├── .oxlintrc.json
├── .gitignore
├── docs/DEVELOPMENT.md   # This file
├── LICENSE
├── README.md
├── pnpm-lock.yaml
├── package.json
├── start.sh              # Script to start the server
└── tsconfig.json         # TypeScript configuration
```

## Knowledge Base System (`knowledge_base/`)

The server features an extensible knowledge base of AppleScript/JXA tips and runnable scripts, stored as Markdown files in the `knowledge_base/` directory. This allows for easy contribution and maintenance of a rich script library.

### Directory Structure

- **`knowledge_base/`**: Root directory.
- **`knowledge_base/_shared_handlers/`**: Contains reusable AppleScript (`.applescript`) or JXA (`.js`) handlers/subroutines. These are not yet automatically prepended but are loaded and can be referenced in complex script designs.
- **`knowledge_base/<category_name>/`**: Each subdirectory represents a category of tips (e.g., `finder`, `safari`, `mail`).
- **`knowledge_base/<category_name>/_category_info.md`**: (Optional) A Markdown file whose frontmatter can contain a `description` for the category, used by `get_scripting_tips`.
- **`knowledge_base/<category_name>/<tip_file_name>.md`**: Individual Markdown files for each script/tip.

### Tip File Format (`.md`)

Each tip file uses YAML frontmatter and a Markdown body containing the script.

````yaml
---
id: unique_script_id # Optional but recommended for complex/runnable scripts (e.g., safari_get_all_links)
title: "Descriptive Title of the Tip/Script"
description: "Brief explanation of what the script does."
language: applescript # Or "javascript"; defaults to applescript. Overridden by code block language.
keywords:
  - relevant
  - keyword
  - tags
notes: |
  Important considerations, requirements (e.g., permissions, app settings),
  or potential issues with this script.
  Can be multi-line.
argumentsPrompt: "Optional: Describe inputs needed if script is run by ID, e.g., 'Provide the target URL and new tab title.'"
isComplex: false # Optional: Set to true if a long/complex script, influences display in get_scripting_tips
# usesSharedHandlers: ["string_utils"] # Future: For linking to _shared_handlers
---

Markdown body explaining the script, its usage, or context.

```applescript
-- Your AppleScript code here
log "Hello from AppleScript!"
return "Script executed"
```

Or for JXA:

```javascript
// Your JXA code here
console.log("Hello from JXA!");
"Script executed"; // Last expression is returned
```
````

**Key Frontmatter Fields:**

- `id`: A unique identifier for the script. If provided, this script can be executed by `execute_script` using the `kb_script_id` parameter. Convention: `category_verb_noun`.
- `title`: (Required) The display title of the tip.
- `description`: A brief summary.
- `language`: Can be `applescript` or `javascript`. If a fenced code block specifies a language (e.g., ` ```applescript `), that takes precedence for the script itself.
- `keywords`: An array of relevant search terms.
- `notes`: Important information, warnings, or prerequisites.
- `argumentsPrompt`: If the script is designed to be run by `id` and accepts parameters (via `${inputData.key}`, `${arguments[N]}`, or the legacy `--MCP_INPUT:key` and `--MCP_ARG_N` placeholders), this field should describe the expected `input_data` or `arguments`.
- `isComplex`: A hint, often automatically determined by script length. Complex scripts with IDs are highlighted as runnable by `get_scripting_tips`.

### Parsing and Loading

- The `src/services/knowledgeBaseService.ts` handles loading and parsing these Markdown files.
- It uses the `gray-matter` library for parsing frontmatter.
- The knowledge base is **lazy-loaded** on the first call to `get_scripting_tips` or when `execute_script` uses a `kb_script_id`.

## Scripts Overview

- `pnpm run build`: Compiles TypeScript to JavaScript.
- `pnpm run dev`: Runs the server in development mode with hot reloading (using tsx).
- `pnpm run start`: Starts the compiled server.
- `pnpm run lint`: Lints the codebase using oxlint.
- `pnpm run format`: Formats the codebase using oxfmt.

## General Development Notes

- Ensure your code adheres to the linting and formatting rules.
- Write tests for new features and bug fixes.
- Keep documentation updated.
- **Contributing:** Submit issues and pull requests to the main [GitHub repository](https://github.com/steipete/macos-automator-mcp).
- **Adding Knowledge Base Tips:** To contribute new scripts or tips, create a new `.md` file in the appropriate category directory under `knowledge_base/`, following the format described above. Ensure titles are clear, descriptions are helpful, and notes cover any prerequisites or potential issues.

## License

This project is licensed under the MIT License.
