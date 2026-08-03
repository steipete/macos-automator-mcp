# MCP tool reference

macOS Automator MCP exposes two tools over stdio. All input field names use `snake_case`.

## `get_scripting_tips`

Search the bundled and local AppleScript/JXA knowledge bases. Set `list_categories` to `true` to list the available categories.

| Input              | Type             | Default | Description                                                           |
| ------------------ | ---------------- | ------- | --------------------------------------------------------------------- |
| `list_categories`  | boolean          | `false` | Return category IDs, descriptions, and tip counts.                    |
| `category`         | string           | —       | Limit results to a discovered category ID.                            |
| `search_term`      | string           | —       | Fuzzy-search titles, IDs, keywords, descriptions, and script content. |
| `limit`            | positive integer | `10`    | Maximum search or category results.                                   |
| `refresh_database` | boolean          | `false` | Reload bundled and local knowledge before querying.                   |

Example search input:

```json
{
  "search_term": "clipboard text",
  "limit": 5
}
```

Results are Markdown. Runnable tips include an ID, language, script, keywords, notes, and any expected inputs.

## `execute_script`

Run exactly one script source. Choose one of these mutually exclusive inputs:

| Input            | Type   | Description                                                    |
| ---------------- | ------ | -------------------------------------------------------------- |
| `kb_script_id`   | string | ID returned by `get_scripting_tips`; the language is inferred. |
| `script_content` | string | Inline AppleScript or JXA source.                              |
| `script_path`    | string | Absolute POSIX path to a readable script file.                 |

### Script inputs

| Input        | Type                          | Description                                                                              |
| ------------ | ----------------------------- | ---------------------------------------------------------------------------------------- |
| `language`   | `applescript` or `javascript` | Language for inline or file sources; defaults to `applescript`.                          |
| `arguments`  | string array                  | File arguments for `on run argv`/`run(argv)`, or positional knowledge-base placeholders. |
| `input_data` | object                        | Named values substituted into knowledge-base script placeholders.                        |

Knowledge-base scripts can use `${inputData.keyName}` or the legacy `--MCP_INPUT:keyName` form for named inputs. The server maps camel-case placeholder names to snake-case `input_data` keys. Positional placeholders use `${arguments[N]}` or the legacy `--MCP_ARG_N` form.

Example knowledge-base input:

```json
{
  "kb_script_id": "finder_create_new_folder_desktop",
  "input_data": {
    "folder_name": "MCP Notes"
  }
}
```

### Execution options

| Input                               | Type    | Default | Description                                            |
| ----------------------------------- | ------- | ------- | ------------------------------------------------------ |
| `timeout_seconds`                   | integer | `60`    | Stop the script when the timeout expires.              |
| `output_format_mode`                | enum    | `auto`  | Select `osascript` output formatting.                  |
| `include_executed_script_in_output` | boolean | `false` | Include the final substituted source or executed path. |
| `include_substitution_logs`         | boolean | `false` | Include placeholder-substitution diagnostics.          |
| `report_execution_time`             | boolean | `false` | Add a formatted execution-duration message.            |

Output modes:

| Mode                          | Behavior                                                    |
| ----------------------------- | ----------------------------------------------------------- |
| `auto`                        | Uses `human_readable` for AppleScript and `direct` for JXA. |
| `human_readable`              | Passes `-s h` to `osascript`.                               |
| `structured_error`            | Passes `-s s` to `osascript`.                               |
| `structured_output_and_error` | Requests structured output and errors.                      |
| `direct`                      | Adds no `-s` output flags.                                  |

The response contains an array of text content items and may set `isError` to `true`. macOS permission failures include a hint to check Automation and Accessibility access.

## Security boundary

The tool is an execution bridge, not a sandbox. Inline scripts, file scripts, and knowledge-base scripts run as the user account that launched the server and can change files, applications, and system state. Treat script content as code, review it before execution, and keep approval controls in the MCP client for destructive calls.
