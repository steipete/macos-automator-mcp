import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { chromium, Browser, Page, BrowserContext } from 'playwright';
import { ChildProcess, spawn, execSync } from 'child_process';
import path from 'path';
import os from 'os';
import fs from 'fs/promises';

const shouldSkipInspectorE2E = !!process.env.CI;
const describeFn = shouldSkipInspectorE2E ? describe.skip : describe.sequential;

const WORKSPACE_PATH = path.resolve(__dirname, '..');
const SESSION_TOKEN = 'test-session-token';
const INSPECTOR_URL = `http://localhost:6274/?MCP_PROXY_AUTH_TOKEN=${SESSION_TOKEN}`;
const INSPECTOR_UI_PORT = INSPECTOR_URL.split(':').pop()!.split('/')[0];
const INSPECTOR_PROXY_PORT = 6277;
const MCP_COMMAND = path.join(WORKSPACE_PATH, 'scripts', 'run-server-in-ci.sh');
const MCP_ARGS = '';

const testFileContent = "Content written by execute_script test via MCP Inspector";
let tempFilePath = ''; // Will be determined during the execute_script part
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

// --- Selectors ---
const commandInputSelector = 'input[placeholder="Command"]';
const argsWrapperSelector = '[placeholder*="Arguments (space-separated)"]';
const connectButtonSelector = 'button:has-text("Connect")';
const listToolsButtonSelector = 'button:has-text("List Tools")';
const connectedStatusSelector = 'text="Connected"';
const disconnectButtonSelector = 'button:has-text("Disconnect")';
const executeScriptPanelSelector = 'div[role="tabpanel"]:has-text("execute_script")';

// --- Timeouts ---
const WAIT_FOR_ELEMENT_TIMEOUT = 5000;
const CONNECT_BUTTON_CLICK_TIMEOUT = 7000;
// Inspector takes a while to spin up on cold CI runners; give it breathing room.
const STATUS_CONNECTED_TIMEOUT = 60000;
const WAIT_FOR_SELECTOR_TIMEOUT = 5000;
const SINGLE_TEST_TIMEOUT = 60000;
const BEFORE_ALL_TIMEOUT = 60000;
const AFTER_ALL_TIMEOUT = 30000;

// --- Helper to connect and list tools (run once in beforeAll) ---
async function connectAndListTools(page: Page) {
  await page.waitForSelector(commandInputSelector, { timeout: WAIT_FOR_ELEMENT_TIMEOUT });
  await page.click(commandInputSelector);
  await page.fill(commandInputSelector, MCP_COMMAND);
  await page.keyboard.press('Tab');
  await page.waitForSelector(argsWrapperSelector, { state: 'visible', timeout: WAIT_FOR_SELECTOR_TIMEOUT });
  await page.click(argsWrapperSelector);
  await page.keyboard.type(MCP_ARGS, { delay: 5 });

  await page.waitForTimeout(50);
  const connectButton = await page.locator(connectButtonSelector);
  await connectButton.waitFor({ state: 'visible', timeout: WAIT_FOR_ELEMENT_TIMEOUT });
  if (!(await connectButton.isEnabled({ timeout: WAIT_FOR_ELEMENT_TIMEOUT }))) {
    await page.waitForFunction((selector) => {
      const btn = document.querySelector(selector);
      return btn && !btn.hasAttribute('disabled');
    }, connectButtonSelector, { timeout: WAIT_FOR_ELEMENT_TIMEOUT });
  }
  await connectButton.click({ timeout: CONNECT_BUTTON_CLICK_TIMEOUT });

  await page.waitForSelector(connectedStatusSelector, { timeout: STATUS_CONNECTED_TIMEOUT });
  expect(await page.isVisible(connectedStatusSelector)).toBe(true);

  const listButton = page.locator(listToolsButtonSelector);
  await listButton.waitFor({ state: 'visible', timeout: WAIT_FOR_ELEMENT_TIMEOUT });
  await listButton.click();
}

describeFn('MCP Inspector E2E Test for macos-automator-mcp', () => {
  let browser: Browser;
  let context: BrowserContext;
  let page: Page;
  let inspectorProcess: ChildProcess;

  beforeAll(async () => {
    // Kill any existing processes on the ports
    const portsToClear = [INSPECTOR_UI_PORT, INSPECTOR_PROXY_PORT.toString()];
    for (const port of portsToClear) {
      try {
        execSync(`lsof -ti tcp:${port} | xargs -r kill -9`, { stdio: 'pipe' });
      } catch { /* Ignore */ }
    }
    await new Promise(resolve => setTimeout(resolve, 1500)); // For port release

    // Start Inspector Process
    inspectorProcess = spawn('npx', ['@modelcontextprotocol/inspector'], {
      stdio: 'pipe',
      shell: true,
      detached: false,
      env: {
        ...process.env,
        MCP_AUTO_OPEN_ENABLED: 'false',
        MCP_PROXY_AUTH_TOKEN: SESSION_TOKEN,
      },
    });
    let inspectorReady = false;
    await new Promise<void>((resolve, reject) => {
      const readinessTimeout = setTimeout(() => reject(new Error('MCP Inspector readiness timeout')), 25000);
      inspectorProcess.stdout?.on('data', (data) => {
        if (data.toString().includes('MCP Inspector is up and running')) {
          inspectorReady = true;
          clearTimeout(readinessTimeout);
          resolve();
        }
      });
      inspectorProcess.stderr?.on('data', (data) => console.error(`[Inspector stderr]: ${data}`));
      inspectorProcess.on('error', reject);
      inspectorProcess.on('exit', (code, signal) => {
        if (!inspectorReady && code !== 0 && signal !== 'SIGTERM' && signal !== 'SIGKILL') {
            reject(new Error(`MCP Inspector exited prematurely with code ${code}, signal ${signal}`));
        }
      });
    });
    await new Promise(resolve => setTimeout(resolve, 2000)); // Reduced proxy stabilization

    // Launch Browser and Page
    browser = await chromium.launch({ headless: !!process.env.CI });
    context = await browser.newContext();
    page = await context.newPage();
    await page.goto(INSPECTOR_URL, { waitUntil: 'networkidle', timeout: 15000 });
    await page.bringToFront();

    // Initial Connect and List Tools
    await connectAndListTools(page); 
  }, BEFORE_ALL_TIMEOUT);

  afterAll(async () => {
    if (page && !page.isClosed()) {
        try {
            const isDisconnectBtnVisible = await page.isVisible(disconnectButtonSelector, {timeout: 2000});
            if (isDisconnectBtnVisible) {
                await page.click(disconnectButtonSelector, {timeout: 5000});
                await page.waitForTimeout(1000);
            }
        } catch { console.warn("[Global Teardown] Error clicking disconnect button");}
    }
    await context?.close();
    await browser?.close();

    if (inspectorProcess && inspectorProcess.pid && !inspectorProcess.killed) {
      const killed = inspectorProcess.kill('SIGTERM');
      if (killed) {
        await new Promise<void>(resolve => {
          const kt = setTimeout(() => { inspectorProcess.kill('SIGKILL'); resolve(); }, 5000);
          inspectorProcess.on('exit', () => { clearTimeout(kt); resolve(); });
        });
      }
    }
    if (tempFilePath) {
      try { await fs.unlink(tempFilePath); } catch { /* ignore */ }
    }
     // Final port clearance
    const portsToClearAfter = [INSPECTOR_UI_PORT, INSPECTOR_PROXY_PORT.toString()];
    for (const port of portsToClearAfter) {
      try { execSync(`lsof -ti tcp:${port} | xargs -r kill -9`, { stdio: 'pipe' }); } catch { /* Ignore */ }
    }
  }, AFTER_ALL_TIMEOUT);

  it('should connect, list tools, run get_scripting_tips, then run execute_script and verify file', async () => {
    // Assumes connectAndListTools was successful in beforeAll, so tools are listed.

    // --- Test get_scripting_tips --- 
    const getTipsToolItem = page.getByText('get_scripting_tips', { exact: true });
    await getTipsToolItem.waitFor({ state: 'visible', timeout: WAIT_FOR_ELEMENT_TIMEOUT });
    await getTipsToolItem.scrollIntoViewIfNeeded();
    await getTipsToolItem.click();

    const runToolButtonGetTips = page.locator('div[role="tabpanel"] button:has-text("Run Tool")');
    await runToolButtonGetTips.waitFor({ state: 'visible', timeout: WAIT_FOR_ELEMENT_TIMEOUT });
    await runToolButtonGetTips.click();

    await page.waitForFunction(() => document.body.innerText.includes('Tool Result: Success'), { timeout: 10000 });
    await page.waitForFunction(() => document.body.innerText.includes('How to Use This Knowledge Base'), { timeout: 7000 });

    // --- Test execute_script ---
    const executeScriptToolItem = page.getByText('execute_script', { exact: true });
    await executeScriptToolItem.waitFor({ state: 'visible', timeout: WAIT_FOR_ELEMENT_TIMEOUT });
    await executeScriptToolItem.scrollIntoViewIfNeeded();
    await executeScriptToolItem.click();
    
    // Wait for the execute_script panel to be visible
    const panel = page.locator(executeScriptPanelSelector);
    await panel.waitFor({ state: 'visible', timeout: WAIT_FOR_ELEMENT_TIMEOUT });
    
    tempFilePath = path.join(os.tmpdir(), `mcp_e2e_test_${Date.now()}.txt`);
    const escapedTempFilePath = tempFilePath.replace(/'/g, "'\\''");
    const escapedTestFileContent = testFileContent.replace(/'/g, "'\\''");
    const appleScript = `do shell script "echo '${escapedTestFileContent}' > '${escapedTempFilePath}'"\nreturn "${escapedTempFilePath}"`;
    
    // Wait for the textarea to be available and fill it
    await page.waitForTimeout(1000); // Give time for the panel to fully load
    
    // Use a more flexible selector approach - MCP inspector may have multiple textareas
    const scriptTextarea = page.locator('textarea').first();
    await scriptTextarea.waitFor({ state: 'visible', timeout: 10000 });
    await scriptTextarea.fill(appleScript);
    
    const runToolButtonExecScript = panel.locator('button:has-text("Run Tool")'); // Scoped to panel
    await runToolButtonExecScript.waitFor({state: 'visible', timeout: WAIT_FOR_ELEMENT_TIMEOUT}); 
    await runToolButtonExecScript.click();

    await page.waitForSelector('text=Tool Result', { timeout: STATUS_CONNECTED_TIMEOUT });
    await waitForFileExists(tempFilePath, 20000);

    const fileContentFromNode = await fs.readFile(tempFilePath, 'utf-8');
    expect(fileContentFromNode.trim()).toBe(testFileContent);
  }, SINGLE_TEST_TIMEOUT);
}); 
