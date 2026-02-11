---
id: terminal_run_npx_ai_tool
title: Run npx AI Tool in Terminal
description: >-
  Runs any npx-based AI tool (like @anthropic-ai/claude-code, @openai/codex, etc.)
  in a new Terminal tab with optional arguments.
language: applescript
keywords:
  - npx
  - npm
  - ai
  - cli
  - terminal
  - tool
usage_examples:
  - Run Claude Code via npx without global installation
  - Execute any npx-based AI CLI tool
  - Test new AI tools without installing them
parameters:
  - name: package_name
    description: The npx package name (e.g., @anthropic-ai/claude-code)
    required: true
  - name: args
    description: Optional arguments to pass to the tool
    required: false
  - name: working_dir
    description: Optional working directory to run the command in
    required: false
category: 13_developer
---

# Run npx AI Tool in Terminal

This script runs any npx-based AI tool in a new Terminal tab, useful for testing or running AI CLIs without global installation.

```applescript
on run {input, parameters}
    set packageName to "--MCP_INPUT:package_name"
    set toolArgs to "--MCP_INPUT:args"
    set workingDir to "--MCP_INPUT:working_dir"

    -- Validate package name
    if packageName is "" or packageName is missing value then
        return "Error: No package name provided."
    end if

    -- Build the npx command
    set npxCommand to "npx -y " & packageName

    -- Add arguments if provided
    if toolArgs is not "" and toolArgs is not missing value then
        set npxCommand to npxCommand & " " & toolArgs
    end if

    -- Prepend cd if working directory provided
    if workingDir is not "" and workingDir is not missing value then
        set npxCommand to "cd " & quoted form of workingDir & " && " & npxCommand
    end if

    tell application "Terminal"
        activate

        if (count of windows) is 0 then
            do script npxCommand
        else
            tell application "System Events"
                keystroke "t" using command down
            end tell
            delay 0.3
            do script npxCommand in front window
        end if

        return "Running: " & npxCommand
    end tell
end run
```

## Use Cases

### Run Claude Code

```json
{
  "kb_script_id": "terminal_run_npx_ai_tool",
  "input_data": {
    "package_name": "@anthropic-ai/claude-code",
    "working_dir": "/Users/me/projects/my-app"
  }
}
```

### Run with Arguments

```json
{
  "kb_script_id": "terminal_run_npx_ai_tool",
  "input_data": {
    "package_name": "@openai/codex",
    "args": "--model gpt-4"
  }
}
```

## Popular AI npx Packages

- `@anthropic-ai/claude-code` - Claude Code CLI
- `@blockrun/alpha` - BlockRun AI Router
- `create-next-app` - Next.js with AI templates

## Requirements

- Node.js and npm must be installed
- Internet connection for npx to download packages
