# Testing the MCP server

Run `pnpm test` on macOS with Node.js 24 or newer. Vitest covers placeholder substitution and drives the server through the MCP SDK's stdio client. The stdio test launches the TypeScript entry point, lists tools, searches the knowledge base, executes a synthetic AppleScript that writes a temporary file, and checks the CLI version flag.

The protocol test does not require a browser, MCP Inspector, or application Automation permissions. It owns its temporary directory and closes the client after the suite. When adding cases, assert the tool response before checking side effects; an awaited script has already completed, so filesystem polling is unnecessary.

Use `pnpm build` to check the distributed JavaScript entry point. `node dist/server.js --version` should print the package version and exit. For manual protocol testing, configure an MCP client to run `node` with the absolute path to `dist/server.js`.

`MCP_E2E_TESTING=true` suppresses startup/first-call metadata. Set `LOCAL_KB_PATH` to a temporary test directory so personal knowledge-base overrides cannot change test results. Keep stdout reserved for protocol messages and consume server diagnostics from stderr.

App-specific AppleScript or JXA changes need a live macOS check with synthetic inputs. Prefer read-only operations or task-owned temporary files. Do not run the entire bundled script collection: many examples intentionally modify user applications and data.

See [knowledge-base validation](kb_validation.md) for checks that can run without executing scripts.
