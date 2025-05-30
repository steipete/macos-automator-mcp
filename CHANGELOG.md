# Changelog

## [0.4.1] - 2025-05-20
- Fixed version reporting to only occur on tool calls, not MCP initialization handshake
- Removed unnecessary server ready log message that was causing MCP client connection issues

## [0.4.0] - 2025-05-20
- Replaced the `use_script_friendly_output` boolean parameter with a more versatile `output_format_mode` string enum parameter for the `execute_script` tool. This provides finer-grained control over `osascript` output formatting flags.
  - New parameter: `output_format_mode` (enum: `'auto'`, `'human_readable'`, `'structured_error'`, `'structured_output_and_error'`, `'direct'`, default: `'auto'`).
  - The `'auto'` mode intelligently selects output formatting: `human_readable` (`-s h`) for AppleScript, and `direct` (no `-s` flags) for JXA, which is recommended for JXA compatibility, especially with Obj-C bridging.
  - `use_script_friendly_output` has been removed.
- Fixed a bug causing script execution time to be incorrectly reported as "0 milliseconds" for some scripts; timing is now measured with millisecond precision.
- Refined the display formatting for reported execution times, including how sub-millisecond durations and spacing are handled.

## [0.3.0] - 2025-05-19
- Included script execution time in the output of the `execute_script` tool. The `timings` object in the response now contains `execution_time_seconds` (duration of the script execution itself in seconds, with up to two decimal places).
- Increased the default script execution timeout (`timeoutSeconds`) from 30 seconds to 60 seconds.
- Optimized and shortened the description for the `execute_script` tool.
- Changed tool input parameter naming convention from camelCase to snake_case for all tools (e.g., `kbScriptId` is now `kb_script_id`). Placeholder keys within script content (e.g., `--MCP_INPUT:keyName`) remain camelCase, with internal mapping handled by the server.

## 0.2.3 - 2025-05-16
- Improve script execution error handling.
- Restructure JXA examples.

## 0.2.2 - 2025-05-16
- Limit search output to 500 lines to prevent overly large responses.

## 0.2.1 - 2025-05-16
- Limit search to 10 items by default.

## 0.2.0 - 2025-05-16
- Greatly increased knowledge base, esp. around web browsers & terminal.
- Add a two-step fuzzy search to inspire agents.
- Add default limit (10) for search results to improve response times.
- The script linter now also lints AppleScript and JXA.
- Improved knowledge base parsing performance.
- Improved file structure, split up large files.
- Reorganized knowledge base with shorter, more intuitive folder names.
- Moved JXA basics to position 03 (after AppleScript core) for better logical ordering.
- Moved CURSOR.md to .cursor/rules/agent.mdc for better compatibility with Cursor editor.

## 0.1.4 - 2025-05-15
- Initial release.
