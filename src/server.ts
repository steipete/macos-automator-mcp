#!/usr/bin/env node

import fs from "node:fs/promises";

const packageJsonPathServer = new URL("../package.json", import.meta.url);
let pkg: { version: string };
try {
  pkg = JSON.parse(await fs.readFile(packageJsonPathServer, "utf-8"));
} catch (error) {
  if (process.env.MCP_E2E_TESTING !== "true" && process.env.VITEST !== "true") {
    console.error("Failed to load package.json:", error);
  }
  pkg = { version: "0.0.0-error" };
}

const SERVER_START_TIME_ISO = new Date().toISOString();

const IS_E2E_TESTING = process.env.MCP_E2E_TESTING === "true" || process.env.VITEST === "true";
let hasEmittedFirstCallInfo = false;
const serverInfoMessage = `MacOS Automator MCP v${pkg.version}, started at ${SERVER_START_TIME_ISO}`;

if (process.argv.includes("--version") || process.argv.includes("-v")) {
  process.stdout.write(`${pkg.version}\n`);
  process.exit(0);
}

const [
  { McpServer },
  { StdioServerTransport },
  { Logger },
  { conditionallyInitializeKnowledgeBase },
  { registerTools },
] = await Promise.all([
  import("@modelcontextprotocol/sdk/server/mcp.js"),
  import("@modelcontextprotocol/sdk/server/stdio.js"),
  import("./logger.js"),
  import("./services/KnowledgeBaseManager.js"),
  import("./registerTools.js"),
]);

function takeServerInfo(): string | undefined {
  if (IS_E2E_TESTING || hasEmittedFirstCallInfo) return undefined;
  hasEmittedFirstCallInfo = true;
  return serverInfoMessage;
}

const logger = new Logger("macos_automator_server");

async function main() {
  if (!IS_E2E_TESTING) {
    logger.info("[Server Startup] Current working directory", { cwd: process.cwd() });

    logger.info("Starting macos_automator MCP Server...");
    logger.warn(
      "CRITICAL: Ensure macOS Automation & Accessibility permissions are correctly configured for the application running this server (e.g., Terminal, Node). See README.md for details.",
    );

    const eagerParseEnv = process.env.KB_PARSING?.toLowerCase();
    if (eagerParseEnv === "eager") {
      await conditionallyInitializeKnowledgeBase(true);
    } else {
      conditionallyInitializeKnowledgeBase(false); // Log that it's lazy
    }
  }

  const server = new McpServer({
    name: "macos_automator",
    version: pkg.version,
  });

  registerTools(server, takeServerInfo);

  const transport = new StdioServerTransport();
  await server.connect(transport);

  process.on("SIGINT", async () => {
    logger.info("Shutting down macos_automator MCP Server...");
    await server.close();
    process.exit(0);
  });
}

main().catch((error) => {
  logger.error("Fatal error in server", error);
  process.exit(1);
});
