---
id: claude_code_open_project
title: Open Project in Claude Code
description: >-
  Opens a project directory in Claude Code (Anthropic's AI-powered CLI)
  in a new Terminal tab.
language: applescript
keywords:
  - claude
  - claude code
  - ai
  - terminal
  - project
  - anthropic
usage_examples:
  - Open a project folder in Claude Code for AI-assisted development
  - Start a new Claude Code session with a specific directory
parameters:
  - name: project_path
    description: The absolute path to the project directory
    required: true
  - name: initial_prompt
    description: Optional initial prompt to send to Claude Code
    required: false
category: 13_developer
---

# Open Project in Claude Code

This script opens a project in Claude Code, Anthropic's AI-powered CLI tool for software development.

```applescript
on run {input, parameters}
    set projectPath to "--MCP_INPUT:project_path"
    set initialPrompt to "--MCP_INPUT:initial_prompt"

    -- Validate project path
    if projectPath is "" or projectPath is missing value then
        return "Error: No project path provided."
    end if

    -- Build the claude command
    set claudeCommand to "cd " & quoted form of projectPath & " && claude"

    -- Add initial prompt if provided
    if initialPrompt is not "" and initialPrompt is not missing value then
        set claudeCommand to claudeCommand & " \"" & initialPrompt & "\""
    end if

    tell application "Terminal"
        activate

        -- Check if Terminal has windows
        if (count of windows) is 0 then
            do script claudeCommand
        else
            -- Open in new tab
            tell application "System Events"
                keystroke "t" using command down
            end tell
            delay 0.3
            do script claudeCommand in front window
        end if

        return "Opened Claude Code in: " & projectPath
    end tell
end run
```

## Use Cases

### Quick Project Access

Quickly open any project in Claude Code:

```json
{
  "kb_script_id": "claude_code_open_project",
  "input_data": {
    "project_path": "/Users/me/projects/my-app"
  }
}
```

### With Initial Prompt

Start Claude Code with a specific task:

```json
{
  "kb_script_id": "claude_code_open_project",
  "input_data": {
    "project_path": "/Users/me/projects/my-app",
    "initial_prompt": "Review the codebase and suggest improvements"
  }
}
```

## Requirements

- Claude Code CLI must be installed (`npm install -g @anthropic-ai/claude-code`)
- Terminal.app must have Accessibility permissions
