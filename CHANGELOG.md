# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.2.0] - 2025-05-16

### Changed
- Refactored `src/server.ts` by extracting placeholder substitution logic into `src/placeholderSubstitutor.ts` for improved modularity.
- Refactored `scripts/validate-kb.ts` into multiple focused modules (`kbReport.ts`, `kbFileValidator.ts`, `kbPathProcessor.ts`) for better maintainability.
- Refactored `src/services/knowledgeBaseService.ts`:
    - Extracted file loading and parsing to `src/services/kbLoader.ts`.
    - Extracted KB state management, merging, and lifecycle to `src/services/KnowledgeBaseManager.ts`.
    - Simplified `knowledgeBaseService.ts` to a service layer with internal helpers for search and formatting.
- Optimized Knowledge Base merging logic in `KnowledgeBaseManager.ts` using `Map` objects for improved performance.
- Removed obsolete comments and refactoring artifacts from recently modified files.

### Added
- Enhanced fuzzy search in `getScriptingTipsService` to perform a two-stage search (standard then broader threshold) and notify users if results are from the broader search.

## [0.1.4] - 2024-08-16

### Fixed
- Correctly handle `isComplex` default and `argumentsPrompt` conditions in `knowledgeBaseService.ts` during tip loading.
- Ensure local tip overrides in `knowledgeBaseService.ts` properly replace existing tips and their `isLocal` flag is set.
- Improved robustness of ID generation and duplicate ID detection in `validate-kb.ts` for both primary and local KBs.
- Resolved issue where `defaultValue` in `schemas.ts` for `ExecuteScriptInputSchema` `language` field was not being correctly applied if language was omitted for `kbScriptId` sourced scripts (it's inferred from KB metadata for those).

### Changed
- `validate-kb.ts` now distinguishes between errors/duplicates in the primary KB (which will cause non-zero exit) vs. issues/overrides in the local KB (which are warnings/info).
- `validate-kb.ts` now also checks for duplicate shared handler names (name + language).

## [0.1.3] - 2024-08-15

### Fixed
- Resolved issue with `inputData` and `arguments` placeholder substitution in `server.ts` where `valueToAppleScriptLiteral` might not correctly handle all nested types or produce valid AppleScript for certain inputs. Refined substitution logic and regexes for `--MCP_INPUT:key` and `--MCP_ARG_N` to be more robust, especially for quoted and expression contexts.
- Corrected deep debug logging for char codes in server.ts substitution.

### Changed
- Improved logging for substitution process in `server.ts` when `includeSubstitutionLogs` is true.

## [0.1.2] - 2024-08-14

### Fixed
- Resolved pathing issues for `package.json` loading in `server.ts` when the server is run from different contexts (e.g., as a global CLI tool via npx, or directly from source/dist), ensuring `pkg.version` is reliable.
- Corrected path resolution for the embedded `knowledge_base` directory in `knowledgeBaseService.ts` to be robust regardless of how the package is installed or run.

## [0.1.1] - 2024-08-13

### Added
- Initial version of the MCP server.
- `execute_script` tool for running AppleScript and JXA.
- `get_scripting_tips` tool for accessing the knowledge base.
- Basic knowledge base structure and example tips.
- Validation script (`validate-kb.ts`) for the knowledge base.

## 0.1.4 - 2025-05-15
- Version bump to resolve npm versioning conflict.

## 0.1.3 - 2025-05-15
- Fix CLI symlink start: resolve real paths to ensure server starts when invoked via npx or global install.

## 0.1.2 - 2025-05-15
- Initial release. 