# Architecture and knowledge-base format

The server exposes `execute_script` and `get_scripting_tips` over MCP stdio. See the [tool reference](tool-reference.md) for inputs and [configuration](configuration.md) for environment variables and macOS permissions.

## Runtime modules

- `src/server.ts` reads the package version, handles `--version`/`-v`, initializes eager knowledge loading when requested, connects stdio, and shuts down on SIGINT. Tool dependencies load after the version-only exit.
- `src/registerTools.ts` registers the two tools and their annotations. Startup information is appended once, on the first tool result.
- `src/executeScript.ts` resolves inline, file, or knowledge-base sources; substitutes KB inputs; and formats success/error responses.
- `src/ScriptExecutor.ts` runs `osascript` with an argument array, checks file readability, applies timeouts, and captures stdout/stderr. It requires macOS.
- `src/schemas.ts` owns tool input validation and inferred input types; `src/types.ts` contains execution/result types.
- `src/placeholderSubstitutor.ts` resolves named and positional KB placeholders. Inline and file sources are passed through without template substitution.
- `src/logger.ts` writes structured, level-filtered messages to stderr; stdout belongs to the MCP protocol.

## Knowledge-base pipeline

`kbLoader.ts` reads Markdown/YAML and script blocks. The top-level directory determines the category; nested directories contribute to generated IDs. Files beginning with `_` supply metadata or supporting content rather than runnable tips. AppleScript blocks take precedence when both supported languages appear in a tip.

A tip requires a frontmatter title and a nonempty fenced `applescript` or `javascript` block to become runnable. An explicit `id` wins; otherwise the loader combines category, relative subdirectory, and normalized filename. The code block determines the execution language. Keywords, descriptions, notes, and argument prompts accompany search results.

`KnowledgeBaseManager.ts` loads the embedded package knowledge base and then the local knowledge base. Local tips replace embedded tips with the same ID. Shared handlers are indexed by name and language, but are not automatically included in scripts. The manager caches the merged index; explicit refresh reloads it. There is no filesystem watcher.

`knowledgeBaseService.ts` filters by category and uses Fuse.js to search titles, IDs, keywords, descriptions, and scripts. It tries a broader threshold if the primary search finds nothing. Results are grouped by category and formatted as Markdown. The first tip is always shown in full; subsequent tips stop at an approximate 500-line budget.

## Authoring and validation

See the [development guide](DEVELOPMENT.md) for the frontmatter format and the [validation guide](kb_validation.md) for checks. Scripts must be self-contained and document their expected inputs, application requirements, and permissions.

The validator is separate from execution: it checks metadata, IDs, and script-block structure without running the examples. A metadata-valid script is not necessarily safe or compatible with every application version. Exercise changed scripts with synthetic data and the applications they target.
