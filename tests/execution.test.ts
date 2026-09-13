import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { ScriptExecutor } from "../src/ScriptExecutor.js";
import { executeScript } from "../src/executeScript.js";
import { ExecuteScriptInputSchema } from "../src/schemas.js";

beforeEach(() => {
  vi.spyOn(ScriptExecutor.prototype, "execute").mockResolvedValue({
    stdout: "synthetic",
    stderr: "",
    execution_time_seconds: 0.01,
  });
});
afterEach(() => vi.restoreAllMocks());

it("resolves a file source without forwarding an empty content field", async () => {
  await executeScript(
    { script_content: "", script_path: "/synthetic.applescript" },
    () => undefined,
  );
  expect(ScriptExecutor.prototype.execute).toHaveBeenCalledWith(
    { path: "/synthetic.applescript" },
    expect.any(Object),
  );
});

it("forwards run-handler arguments to inline scripts", async () => {
  await executeScript(
    { script_content: "on run argv\nreturn item 1 of argv\nend run", arguments: ["value"] },
    () => undefined,
  );
  expect(ScriptExecutor.prototype.execute).toHaveBeenCalledWith(
    expect.any(Object),
    expect.objectContaining({ arguments: ["value"] }),
  );
});

it.each([-1, 0, 2147484])("rejects invalid timeout %s before execution", (timeout_seconds) => {
  expect(
    ExecuteScriptInputSchema.safeParse({ script_content: "return 1", timeout_seconds }).success,
  ).toBe(false);
});

it("accepts the largest whole-second timeout supported by Node timers", async () => {
  await executeScript({ script_content: "return 1", timeout_seconds: 2147483 }, () => undefined);
  expect(ScriptExecutor.prototype.execute).toHaveBeenCalledWith(
    expect.any(Object),
    expect.objectContaining({ timeoutMs: 2147483000 }),
  );
});

it("carries rounded seconds into the next minute", async () => {
  vi.mocked(ScriptExecutor.prototype.execute).mockResolvedValue({
    stdout: "synthetic",
    stderr: "",
    execution_time_seconds: 119.999,
  });
  const result = await executeScript(
    { script_content: "return 1", report_execution_time: true },
    () => undefined,
  );
  expect(result.content.at(-1)!.text).toBe("Script executed in 2 minute(s) and 0 seconds.");
});
