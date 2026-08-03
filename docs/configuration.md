# Configuration and permissions

The MCP server reads configuration from the environment of the application that launches it.

## Environment variables

| Variable        | Values                           | Default                             | Purpose                                         |
| --------------- | -------------------------------- | ----------------------------------- | ----------------------------------------------- |
| `LOG_LEVEL`     | `DEBUG`, `INFO`, `WARN`, `ERROR` | `INFO`                              | Controls stderr logging.                        |
| `KB_PARSING`    | `lazy`, `eager`                  | `lazy`                              | Loads knowledge on first use or during startup. |
| `LOCAL_KB_PATH` | Filesystem path                  | `~/.macos-automator/knowledge_base` | Selects the local knowledge-base directory.     |

Add variables to the server entry in the MCP client configuration:

```json
{
  "mcpServers": {
    "macos_automator": {
      "command": "npx",
      "args": ["-y", "--package", "@steipete/macos-automator-mcp", "macos-automator-mcp"],
      "env": {
        "LOG_LEVEL": "DEBUG",
        "KB_PARSING": "eager"
      }
    }
  }
}
```

## macOS privacy permissions

macOS assigns privacy permissions to the application hosting the MCP server. Depending on the client, that may be Terminal, an editor, a desktop MCP client, or another Node.js host.

### Automation

Grant Automation access when a script sends Apple events to Finder, Safari, Mail, Calendar, or another application:

1. Open **System Settings → Privacy & Security → Automation**.
2. Find the application that launches the MCP server.
3. Enable the target applications it needs to control.

macOS can prompt the first time the host controls each target application. The server cannot approve or grant access itself.

### Accessibility

Grant Accessibility access for UI scripting through System Events, including simulated clicks, keystrokes, menu selection, and UI-element inspection:

1. Open **System Settings → Privacy & Security → Accessibility**.
2. Add or enable the application that launches the MCP server.

Some file automation may separately require **Full Disk Access**, depending on the paths and application involved.

Permission failures commonly surface as Apple event errors `-1743` or `-10004`. A `-1712` timeout can also mean a permission prompt is waiting behind another window. See [Debugging AppleScript and JXA](debugging_applescript.md) for diagnosis.

## Local knowledge base

Local tips add to the bundled knowledge base. By default, the server reads:

```text
~/.macos-automator/knowledge_base
```

Set `LOCAL_KB_PATH` to use another directory. A leading `~` is expanded to the current user's home directory.

Mirror the bundled `knowledge_base/` category structure. Tip files are Markdown with YAML frontmatter and an AppleScript or JavaScript code block; shared handlers are `.applescript` or `.js` files in `_shared_handlers/`.

Merging follows these rules:

- A local tip with the same ID replaces the bundled tip.
- A local shared handler with the same name and language replaces the bundled handler.
- A local `_category_info.md` can replace a category description.
- New local IDs, handlers, and categories are added to the index.

Validate an alternate local knowledge base from a source checkout:

```sh
pnpm run validate -- --local-kb-path /absolute/path/to/knowledge_base
```

The [development guide](DEVELOPMENT.md) documents the tip format and contribution workflow.
