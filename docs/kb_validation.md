# Knowledge Base Validation

This document explains the validation process for the AppleScript and JavaScript for Automation (JXA) scripts in the knowledge base.

## Overview

The knowledge base consists of Markdown files containing AppleScript and JXA scripts. The validation process ensures that:

1. Each file has the correct frontmatter metadata (title, description, etc.)
2. Script IDs are unique across the knowledge base
3. Script blocks and placeholder metadata are internally consistent

## Validation Command

```bash
pnpm run validate
```

This command validates the structure and metadata of the embedded knowledge base. It also validates the default local knowledge base at `~/.macos-automator/knowledge_base` when that directory exists.

To validate a local knowledge base at another path:

```bash
pnpm run validate -- --local-kb-path /absolute/path/to/knowledge_base
```

The validator always checks the embedded knowledge base as well as the selected local knowledge base.

## Validation Process

The validation script:

1. Parses the frontmatter metadata for each file
2. Checks for required fields (title, description, etc.)
3. Verifies ID uniqueness
4. Extracts script content from code blocks and reports missing, empty, or language-mismatched blocks
5. Checks complex-script argument prompts against MCP placeholders

## Adding New Scripts

When adding new scripts to the knowledge base:

1. Create a new `.md` file in the appropriate category folder
2. Include the required frontmatter metadata
3. Add the script code in a fenced code block with the correct language tag (`applescript` or `javascript`)
4. Run `pnpm run validate` to check the entry metadata and script block structure
5. Fix any reported issues

## Validation Output

The validation process produces a report showing:

- Total files checked
- Total tips processed
- Categories found
- Validation errors and warnings

## Implementation Details

The validation process is implemented in TypeScript in the `scripts/` directory:

- `validate-kb.ts`: Main validator script
- `kbFileValidator.ts`: File validation logic
- `kbPathProcessor.ts`: Directory traversal logic
- `kbReport.ts`: Reporting utilities
