# Development Guide for macOS Automator MCP

This guide provides instructions for setting up the development environment and contributing to the project.

## Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/steipete/macos-automator-mcp.git
    cd macos-automator-mcp
    ```

2.  **Install dependencies:**
    ```bash
    npm install
    ```

3.  **Build the project:**
    ```bash
    npm run build
    ```

4.  **Run in development mode:**
    ```bash
    npm run dev
    ```

## Project Structure

```
macos-automator-mcp/
├── src/                  # Source code
│   ├── server.ts         # Main server logic & MCP tool definitions
│   ├── AppleScriptExecutor.ts # Core osascript execution
│   ├── logger.ts         # Logging utility
│   ├── schemas.ts        # Zod input schemas
│   └── (cli.ts)          # Optional separate CLI entry if needed
├── dist/                 # Compiled JavaScript output
├── docs/                 # Documentation and screenshots
├── .github/workflows/    # GitHub Actions workflows (CI)
├── .eslintignore
├── .eslintrc.cjs
├── .gitignore
├── .prettierignore
├── .prettierrc.json
├── DEVELOPMENT.md        # This file
├── LICENSE
├── README.md
├── package-lock.json
├── package.json
├── start.sh              # Script to start the server
└── tsconfig.json         # TypeScript configuration
```

## Scripts

-   `npm run build`: Compiles TypeScript to JavaScript.
-   `npm run dev`: Runs the server in development mode with hot reloading (using tsx).
-   `npm run start`: Starts the compiled server.
-   `npm run lint`: Lints the codebase using ESLint.
-   `npm run format`: Formats the codebase using Prettier.

## General Development Notes

-   Ensure your code adheres to the linting and formatting rules.
-   Write tests for new features and bug fixes.
-   Keep documentation updated.
-   **Contributing:** Submit issues and pull requests to the main [GitHub repository](https://github.com/steipete/macos-automator-mcp). 