# E2E Testing Strategies for MCP Servers with MCP Inspector

This document outlines key strategies and learnings from creating End-to-End (E2E) tests for an MCP (Model-Context-Protocol) server using the MCP Inspector UI, primarily with Playwright and Vitest.

## 1. Test Runner Configuration (Vitest)

*   **Single Run for CI/Automation:** To ensure Vitest runs tests once and then exits (suitable for CI or automated scripts), use the `run` command.
    *   Example: `npm test -- run --no-file-parallelism <test_file_path>`
    *   The `--no-file-parallelism` flag was used during development to simplify debugging by running tests sequentially if multiple test files were present. Adjust as needed.

## 2. MCP Inspector UI Selectors (Playwright)

Selector stability is crucial for reliable E2E tests. The MCP Inspector UI uses a combination of standard HTML and UI library components (potentially Mantine UI or similar).

*   **General Selector Strategy:**
    *   **Prefer IDs:** If an element has a unique `id`, this is usually the most robust selector (e.g., `textarea#scriptContent`).
    *   **`data-testid`:** If developers add custom `data-testid` attributes, these are excellent for testing.
    *   **Role + Accessible Name:** Use ARIA roles and accessible names (e.g., `button:has-text("Connect")`). Playwright's `getByRole` and `getByText` are very useful here.
    *   **Scope Locators:** When a page has multiple similar elements (e.g., several "Run Tool" buttons in different tabs), scope your locator to a unique parent, like an active tab panel:
        *   `const panel = page.locator('div[role=\"tabpanel\"]:has-text(\"tool_name\")');`
        *   `const runButton = panel.locator('button:has-text(\"Run Tool\")');`

*   **Specific Component Patterns (based on Inspector's structure):**
    *   **Textareas (e.g., for command arguments, script content):**
        *   The `scriptContent` textarea for `execute_script` was best found using its ID: `textarea#scriptContent`.
        *   Previously, a more complex selector like `textarea.mantine-Textarea-input[placeholder*=\"Some Text\"]` was attempted. While such patterns can work for UIs built with libraries like Mantine, direct IDs are better if available. If not, be prepared to inspect the exact classes and attributes.
        *   The arguments input field for the connection was identified via its placeholder within a wrapper, requiring careful targeting and typing: `await page.click('[placeholder*=\"Arguments (space-separated)\"]'); await page.keyboard.type(MCP_ARGS, { delay: 5 });`
    *   **Buttons:** Often identifiable by text content: `button:has-text("List Tools")`.
    *   **Tool Items in a List:** `page.getByText('tool_name', { exact: true })` proved effective.

*   **Dynamic Content & Visibility:**
    *   Always `await element.scrollIntoViewIfNeeded();` before clicking elements that might be outside the current viewport.
    *   Use `element.waitFor({ state: 'visible', timeout: ... })` to ensure elements are visible and interactable.
    *   For text content appearing dynamically (e.g., tool results, status messages), `page.waitForFunction(() => document.body.innerText.includes('Some Text'), { timeout: ... })` is reliable.

## 3. Playwright Techniques

*   **Passing Arguments to `page.waitForFunction`:** If your predicate function inside `page.waitForFunction` needs access to variables from your Node.js test scope, pass them as arguments:
    *   `await page.waitForFunction((arg) => document.body.innerText.includes(arg), myNodeVariable, { timeout: ... });`

*   **Debugging Failed Selectors with `page.evaluate()`:** If `waitForSelector` or locators fail, use `page.evaluate()` to inspect the DOM directly from the browser's context at the point of failure:
    ```typescript
    // const panel = page.locator(somePanelSelector);
    // await panel.waitFor({ state: 'visible' });
    // const debugInfo = await panel.evaluate((panelElement, problematicSelector) => {
    //   const info = {};
    //   info.panelOuterHTML = panelElement.outerHTML;
    //   const foundElement = panelElement.querySelector(problematicSelector);
    //   info.elementFound = !!foundElement;
    //   if (foundElement) {
    //     info.elementOuterHTML = foundElement.outerHTML;
    //     // Add more properties as needed
    //   }
    //   return info;
    // }, problematicSelector);
    // console.log('DOM Debug Info:', JSON.stringify(debugInfo, null, 2));
    // // Then the failing waitFor:
    // await panel.locator(problematicSelector).waitFor({ state: 'visible' });
    ```

*   **Test Structure (`beforeAll`, `afterAll`):**
    *   Use `beforeAll` for setting up global state: starting the Inspector process, launching the Playwright browser, performing initial connection steps common to all tests (if applicable).
    *   Use `afterAll` for cleanup: killing processes, closing the browser, deleting temporary files.

*   **Text Input:** For textareas or input fields that might have rich text editors or event listeners, `page.keyboard.type('text', { delay: 50 })` can be more reliable than `page.fill()` if `fill` causes issues. For simple inputs, `fill` is usually fine.

## 4. Timeout Strategy

*   **UI Interaction Timeouts:** For most Inspector UI element interactions (waiting for visibility, clicks), timeouts of **3-5 seconds** should be sufficient once the page is loaded. Example: `WAIT_FOR_ELEMENT_TIMEOUT = 5000;`
*   **Process/Network Timeouts:**
    *   Starting external processes (like the MCP Inspector): **15-25 seconds** (e.g., `npx` first-run can be slow).
    *   Initial page load (`page.goto`): **10-15 seconds**.
    *   Waiting for server connection status: **7-10 seconds**.
    *   Waiting for tool results (which involve server communication): **7-10 seconds**.
*   **Overall Test Timeouts:** (`test` / `it` block, `beforeAll`, `afterAll`): Set these generously enough to cover all steps, but review if individual operations within them are too slow. E.g., `SINGLE_TEST_TIMEOUT = 60000;`
*   **Debugging Timeouts:** If an element that *should* appear quickly is consistently timing out, it's more likely a selector problem than a need for an excessively long timeout (e.g., >10-15s for a simple UI element).

## 5. MCP Server Interaction via Inspector

*   **Launching the Target Server:** When the MCP Inspector is configured to start your MCP server, ensure the "Command" and "Arguments" fields in the Inspector UI (and thus in your test script) correctly point to the mechanism for launching your server.
    *   Example used: Command: `/bin/zsh`, Arguments: `/path/to/your/project/start.sh`
    *   Alternatively: Command: `node`, Arguments: `dist/server.js` (if your server is a Node.js script).
    Make sure the server can be started this way and that paths are correct.

## 6. General Stability

*   **Port Clearance:** In `beforeAll`, ensure any ports used by the Inspector (UI and Proxy) and your MCP server are cleared to prevent conflicts from previous runs.
    *   `execSync(\`lsof -ti tcp:<port> | xargs -r kill -9\`, { stdio: 'pipe' });`
*   **Explicit Waits:** Avoid fixed `page.waitForTimeout()` for regular flow control. Prefer waiting for specific conditions (element visibility, text, network idle). Small fixed delays (e.g., 50-250ms) should only be a last resort for very specific, hard-to-diagnose race conditions after other options are exhausted. The `await page.waitForTimeout(250);` before `scriptTextarea.waitFor` was one such case that ultimately helped with a stubborn visibility issue. 