import { expect, it } from "vitest";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { ScriptExecutor } from "../src/ScriptExecutor.js";

it("passes option-looking inline AppleScript arguments as data", async () => {
  const result = await new ScriptExecutor().execute(
    { content: "on run argv\nreturn item 1 of argv\nend run" },
    { arguments: ["-e"] },
  );
  expect(result.stdout).toBe("-e");
});

it("preserves all option-looking JXA arguments", async () => {
  const args = ["-e", "-l", "--", "two words"];
  const result = await new ScriptExecutor().execute(
    { content: "function run(argv) { return JSON.stringify(argv); }" },
    { language: "javascript", arguments: args },
  );
  expect(JSON.parse(result.stdout)).toEqual(args);
});

it("preserves file arguments after the osascript option boundary", async () => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), "mcp-executor-"));
  try {
    const file = path.join(root, "script.applescript");
    await fs.writeFile(file, "on run argv\nreturn item 1 of argv\nend run");
    const result = await new ScriptExecutor().execute({ path: file }, { arguments: ["--"] });
    expect(result.stdout).toBe("--");
  } finally {
    await fs.rm(root, { recursive: true, force: true });
  }
});
