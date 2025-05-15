# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the `macos-automator-mcp` project, which provides a Model Context Protocol (MCP) server that enables executing AppleScript and JavaScript for Automation (JXA) scripts on macOS. The server features a knowledge base of pre-defined scripts accessible by ID and supports inline scripts, script files, and argument passing.

## Architecture

- **Server Configuration**: The server reads configuration from environment variables like `LOG_LEVEL` and `KB_PARSING`.
- **MCP Tools**: Two main tools are provided:
  1. `execute_script`: Executes AppleScript/JXA from inline content, file path, or knowledge base ID
  2. `get_scripting_tips`: Retrieves information from the knowledge base
- **Knowledge Base**: A collection of pre-defined scripts stored as Markdown files in `knowledge_base/` directory with YAML frontmatter
- **ScriptExecutor**: Core component that executes scripts via `osascript` command

## Knowledge Base System

The knowledge base (`knowledge_base/` directory) contains numerous Markdown files organized by category:
- Each file has YAML frontmatter with metadata: `id`, `title`, `description`, `language`, etc.
- The actual script code is contained in the Markdown body in a fenced code block
- Scripts can use placeholders like `--MCP_INPUT:keyName` and `--MCP_ARG_N` for parameter substitution

## Common Development Commands

```bash
# Install dependencies
npm install

# Run the server in development mode with hot reloading
npm run dev

# Build the TypeScript project
npm run build

# Start the compiled server
npm run start

# Lint the codebase
npm run lint

# Format the codebase
npm run format

# Validate the knowledge base
npm run validate
```

## Environment Variables

- `LOG_LEVEL`: Set logging level (`DEBUG`, `INFO`, `WARN`, `ERROR`) - default is `INFO`
- `KB_PARSING`: Controls when knowledge base is parsed:
  - `lazy` (default): Parsed on first request
  - `eager`: Parsed when server starts

## Working with the Knowledge Base

When adding new scripts to the knowledge base:
1. Create a new `.md` file in the appropriate category folder
2. Include required YAML frontmatter (`title`, `description`, etc.)
3. Add the script code in a fenced code block
4. Run `npm run validate` to ensure the new content is correctly formatted

## Code Execution Flow

1. The `server.ts` file defines the MCP server and its tools
2. `knowledgeBaseService.ts` loads and indexes scripts from the knowledge base
3. `ScriptExecutor.ts` handles the actual execution of scripts
4. Input validation is handled via Zod schemas in `schemas.ts`
5. Logging is managed by the `Logger` class in `logger.ts`

## Security and Permissions

Remember that scripts run on macOS require specific permissions:
- Automation permissions for controlling applications
- Accessibility permissions for UI scripting via System Events
- Full Disk Access for certain file operations