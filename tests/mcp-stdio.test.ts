import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { Client } from "@modelcontextprotocol/sdk/client";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { execFileSync } from "node:child_process";
import path from "node:path";
import os from "node:os";
import fs from "node:fs/promises";
import { CallToolResultSchema } from "@modelcontextprotocol/sdk/types.js";
import packageJson from "../package.json" with { type: "json" };

const WORKSPACE_PATH = path.resolve(import.meta.dirname, "..");
const TSX_PATH = path.join(WORKSPACE_PATH, "node_modules", ".bin", "tsx");
const SERVER_PATH = path.join(WORKSPACE_PATH, "src", "server.ts");

const TEST_CONTENT = "Content written by execute_script via stdio test";

function shellEscape(value: string) {
  return value.replace(/'/g, "'\\''");
}

function toolByName(tools: Awaited<ReturnType<Client["listTools"]>>["tools"], name: string) {
  const tool = tools.find((candidate) => candidate.name === name);
  expect(tool, `expected MCP tool ${name} to be listed`).toBeDefined();
  return tool!;
}

describe("MCP stdio protocol", () => {
  let client: Client;
  let transport: StdioClientTransport;
  let tempDirectory: string;

  beforeAll(async () => {
    tempDirectory = await fs.mkdtemp(path.join(os.tmpdir(), "mcp-stdio-"));
    transport = new StdioClientTransport({
      command: TSX_PATH,
      args: [SERVER_PATH],
      cwd: WORKSPACE_PATH,
      stderr: "pipe",
      env: {
        MCP_E2E_TESTING: "true",
        VITEST: "true",
        LOCAL_KB_PATH: path.join(tempDirectory, "local-kb"),
        LOG_LEVEL: "ERROR",
      },
    });

    client = new Client({
      name: "macos-automator-mcp-tests",
      version: "0.0.0",
    });

    await client.connect(transport);
  }, 30000);

  afterAll(async () => {
    await client?.close();
    await fs.rm(tempDirectory, { recursive: true, force: true });
  });

  it("lists tools, returns tips, and executes a script", async () => {
    const { tools } = await client.listTools();
    const tipsTool = toolByName(tools, "get_scripting_tips");
    const executeTool = toolByName(tools, "execute_script");

    expect(tipsTool.annotations).toMatchObject({
      title: "Get Scripting Tips",
      readOnlyHint: true,
    });
    expect(executeTool.annotations).toMatchObject({
      title: "Execute Script",
      destructiveHint: true,
    });

    const tipsResult = await client.callTool({
      name: "get_scripting_tips",
      arguments: { search_term: "knowledge base", limit: 1 },
    });
    const tipsText = CallToolResultSchema.parse(tipsResult)
      .content.filter((item) => item.type === "text")
      .map((item) => item.text)
      .join("\n");
    expect(tipsText).toContain("How to Use This Knowledge Base");

    const tempFilePath = path.join(tempDirectory, "output.txt");
    const escapedTempFilePath = shellEscape(tempFilePath);
    const escapedTestContent = shellEscape(TEST_CONTENT);
    const appleScript = `do shell script "echo '${escapedTestContent}' > '${escapedTempFilePath}'"\nreturn "${escapedTempFilePath}"`;

    try {
      const result = await client.callTool({
        name: "execute_script",
        arguments: {
          script_content: appleScript,
        },
      });

      expect(result.isError).not.toBe(true);
      const fileContent = await fs.readFile(tempFilePath, "utf-8");
      expect(fileContent.trim()).toBe(TEST_CONTENT);
    } finally {
      try {
        await fs.unlink(tempFilePath);
      } catch {
        /* ignore */
      }
    }
  }, 60000);
});

describe("CLI flags", () => {
  it("prints version and exits without starting stdio transport", () => {
    const output = execFileSync(TSX_PATH, [SERVER_PATH, "--version"], {
      cwd: WORKSPACE_PATH,
      encoding: "utf8",
      env: {
        ...process.env,
        MCP_E2E_TESTING: "true",
        VITEST: "true",
      },
      timeout: 15000,
    });

    expect(output.trim()).toBe(packageJson.version);
  }, 20000);
});
