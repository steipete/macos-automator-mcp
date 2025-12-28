import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Client } from '@modelcontextprotocol/sdk/client';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';
import path from 'path';
import os from 'os';
import fs from 'fs/promises';

const WORKSPACE_PATH = path.resolve(__dirname, '..');
const TSX_PATH = path.join(WORKSPACE_PATH, 'node_modules', '.bin', 'tsx');
const SERVER_PATH = path.join(WORKSPACE_PATH, 'src', 'server.ts');
const TSX_TSCONFIG_PATH = path.join(WORKSPACE_PATH, 'tests', 'tsconfig.runtime.json');

const TEST_CONTENT = 'Content written by execute_script via stdio test';

async function waitForFileExists(filePath: string, timeoutMs = 15000, pollMs = 250) {
  const deadline = Date.now() + timeoutMs;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    try {
      await fs.access(filePath);
      return;
    } catch {
      /* ignore */
    }
    if (Date.now() > deadline) {
      throw new Error(`Timed out waiting for file to exist: ${filePath}`);
    }
    await new Promise((resolve) => setTimeout(resolve, pollMs));
  }
}

function shellEscape(value: string) {
  return value.replace(/'/g, "'\\''");
}

describe('MCP stdio protocol', () => {
  let client: Client;
  let transport: StdioClientTransport;

  beforeAll(async () => {
    transport = new StdioClientTransport({
      command: TSX_PATH,
      args: [SERVER_PATH],
      cwd: WORKSPACE_PATH,
      stderr: 'pipe',
      env: {
        MCP_E2E_TESTING: 'true',
        VITEST: 'true',
        TSX_TSCONFIG_PATH,
      },
    });

    client = new Client({
      name: 'macos-automator-mcp-tests',
      version: '0.0.0',
    });

    await client.connect(transport);
  }, 30000);

  afterAll(async () => {
    await client.close();
  });

  it('lists tools, returns tips, and executes a script', async () => {
    const { tools } = await client.listTools();
    expect(tools.some((tool) => tool.name === 'get_scripting_tips')).toBe(true);
    expect(tools.some((tool) => tool.name === 'execute_script')).toBe(true);

    const tipsResult = await client.callTool({
      name: 'get_scripting_tips',
      arguments: { search_term: 'knowledge base', limit: 1 },
    });
    const tipsText = (tipsResult.content ?? [])
      .map((item) => item.text ?? '')
      .join('\n');
    expect(tipsText).toContain('How to Use This Knowledge Base');

    const tempFilePath = path.join(os.tmpdir(), `mcp_stdio_test_${Date.now()}.txt`);
    const escapedTempFilePath = shellEscape(tempFilePath);
    const escapedTestContent = shellEscape(TEST_CONTENT);
    const appleScript = `do shell script "echo '${escapedTestContent}' > '${escapedTempFilePath}'"\nreturn "${escapedTempFilePath}"`;

    try {
      await client.callTool({
        name: 'execute_script',
        arguments: {
          script_content: appleScript,
        },
      });

      await waitForFileExists(tempFilePath, 20000);
      const fileContent = await fs.readFile(tempFilePath, 'utf-8');
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
