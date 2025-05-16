# Knowledge Base Validation

This document explains the validation process for the AppleScript and JavaScript for Automation (JXA) scripts in the knowledge base.

## Overview

The knowledge base consists of Markdown files containing AppleScript and JXA scripts. The validation process ensures that:

1. Each file has the correct frontmatter metadata (title, description, etc.)
2. Script IDs are unique across the knowledge base
3. Scripts have valid syntax (without executing them)

## Validation Commands

### Basic Validation

```bash
npm run validate
```

This command validates the structure and metadata of all knowledge base files without checking script syntax.

### Syntax Validation

```bash
npm run validate:syntax
```

This command performs all basic validation checks plus validates the syntax of AppleScript and JXA scripts using the `osascript` command without executing them.

### Testing Specific Files

```bash
npm run validate:test
```

This runs validation on a test directory with known valid and invalid scripts for testing purposes.

## Validation Process

The validation script:

1. Parses the frontmatter metadata for each file
2. Checks for required fields (title, description, etc.)
3. Verifies ID uniqueness
4. Extracts script content from code blocks
5. For syntax validation, checks script syntax using:
   - `osacompile -o /dev/null script.applescript` for AppleScript
   - `osacompile -l JavaScript -o /dev/null script.js` for JXA

The syntax validation is fail-fast - if a script has syntax errors, the validator will report them without executing the script.

## Adding New Scripts

When adding new scripts to the knowledge base:

1. Create a new `.md` file in the appropriate category folder
2. Include the required frontmatter metadata
3. Add the script code in a fenced code block with the correct language tag (`applescript` or `javascript`)
4. Run `npm run validate:syntax` to ensure your script is valid
5. Fix any reported issues

## Validation Output

The validation process produces a report showing:

- Total files checked
- Total tips processed
- Categories found
- Validation errors and warnings
- Script syntax errors (if syntax validation is enabled)

## Implementation Details

The validation process is implemented in TypeScript in the `scripts/` directory:

- `validate-kb.ts`: Main validator script
- `kbFileValidator.ts`: File validation logic
- `kbPathProcessor.ts`: Directory traversal logic
- `kbReport.ts`: Reporting utilities
- `scriptValidator.ts`: Script syntax validation logic

The script syntax validation uses the macOS built-in `osacompile` tool to validate without executing, using the approach:

```bash
# For AppleScript - fast inline validation
osacompile -e 'tell app "Finder" to beep' -o /dev/null

# For JXA - fast inline validation
osacompile -l JavaScript -e 'Application("Finder").beep()' -o /dev/null
```

This approach checks for syntax errors without actually executing the scripts. By compiling to `/dev/null`, we're able to validate syntax while discarding the compiled output. If there are syntax errors, the command will exit with a non-zero status code, making it safe and effective for CI environments.