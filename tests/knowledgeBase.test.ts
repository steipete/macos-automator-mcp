import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { GetScriptingTipsInputSchema } from "../src/schemas.js";
import { parseMarkdownTipFile } from "../src/services/kbLoader.js";

let localPath: string;
async function write(relative: string, content: string) {
  const file = path.join(localPath, relative);
  await fs.mkdir(path.dirname(file), { recursive: true });
  await fs.writeFile(file, content);
}
function tip(id: string) {
  return `---\nid: ${id}\ntitle: ${id}\n---\n\`\`\`applescript\nreturn "synthetic"\n\`\`\`\n`;
}

beforeEach(async () => {
  vi.resetModules();
  localPath = await fs.mkdtemp(path.join(os.tmpdir(), "mcp-kb-"));
  vi.stubEnv("LOCAL_KB_PATH", localPath);
  vi.stubEnv("LOG_LEVEL", "ERROR");
});
afterEach(async () => {
  vi.unstubAllEnvs();
  await fs.rm(localPath, { recursive: true, force: true });
});

describe("knowledge-base queries", () => {
  it("lists categories for empty and limit-only requests", async () => {
    const { getScriptingTipsService } = await import("../src/services/knowledgeBaseService.js");
    for (const input of [{}, { limit: 1 }]) {
      expect(await getScriptingTipsService(GetScriptingTipsInputSchema.parse(input))).toContain(
        "Available AppleScript/JXA Tip Categories",
      );
    }
  });

  it("advertises the schema's snake_case query fields", async () => {
    const { getScriptingTipsService } = await import("../src/services/knowledgeBaseService.js");
    const list = await getScriptingTipsService(
      GetScriptingTipsInputSchema.parse({ list_categories: true }),
    );
    const empty = await getScriptingTipsService(
      GetScriptingTipsInputSchema.parse({ category: "nonexistent-synthetic-category" }),
    );
    expect(list).toContain('search_term: "keyword"');
    expect(empty).toContain("list_categories: true");
  });

  it("searches category names that match Object prototype properties", async () => {
    await write("__proto__/tip.md", tip("synthetic_proto_tip"));
    await write("constructor/tip.md", tip("synthetic_constructor_tip"));
    const { getScriptingTipsService } = await import("../src/services/knowledgeBaseService.js");
    const result = await getScriptingTipsService(
      GetScriptingTipsInputSchema.parse({ search_term: "synthetic" }),
    );
    expect(result).toContain("synthetic_proto_tip");
    expect(result).toContain("synthetic_constructor_tip");
  });
});

describe("local knowledge-base merging", () => {
  it("loads documented shared handlers and retains the legacy directory", async () => {
    await write("_shared_handlers/canonical.js", "function canonical() { return 1; }");
    await write("shared-handlers/legacy.js", "function legacy() { return 2; }");
    const { getKnowledgeBase } = await import("../src/services/KnowledgeBaseManager.js");
    const kb = await getKnowledgeBase();
    expect(kb.sharedHandlers.map((h) => h.name)).toEqual(
      expect.arrayContaining(["canonical", "legacy", "string_utils"]),
    );
  });

  it("preserves an embedded description when local tips have no category metadata", async () => {
    const { getKnowledgeBase, forceReloadKnowledgeBase } =
      await import("../src/services/KnowledgeBaseManager.js");
    const original = (await getKnowledgeBase()).categories.find(
      (c) => c.id === "01_intro",
    )!.description;
    await write("01_intro/tip.md", tip("synthetic_intro"));
    const reloaded = await forceReloadKnowledgeBase();
    expect(reloaded.categories.find((c) => c.id === "01_intro")!.description).toBe(original);
  });

  it("accepts category-description overrides without requiring local tips", async () => {
    await write(
      "01_intro/_category_info.md",
      "---\ndescription: Synthetic local description\n---\n",
    );
    const { getKnowledgeBase } = await import("../src/services/KnowledgeBaseManager.js");
    expect(
      (await getKnowledgeBase()).categories.find((c) => c.id === "01_intro")!.description,
    ).toBe("Synthetic local description");
  });
});

it.each([
  "title: [bad]",
  "title: valid\nid: 42",
  "title: valid\nnotes: [bad]",
  "title: valid\nlanguage: python",
])("rejects malformed frontmatter without poisoning the index: %s", (frontmatter) => {
  expect(
    parseMarkdownTipFile(
      `---\n${frontmatter}\n---\n\`\`\`applescript\nreturn 1\n\`\`\``,
      "synthetic.md",
    ),
  ).toBeNull();
});

it("validates runnable tips in underscore-prefixed subdirectories", async () => {
  await write("category/_common_patterns/invalid.md", "---\ntitle: ''\n---\n");
  const { processKnowledgeBasePath } = await import("../scripts/kbPathProcessor.js");
  const { report } = await import("../scripts/kbReport.js");
  await processKnowledgeBasePath(localPath, true);
  expect(report.errors.some((error) => error.includes("invalid.md"))).toBe(true);
});

it("prefers canonical shared handlers consistently in loading and validation", async () => {
  await write("_shared_handlers/same.js", "function same() { return 1; }");
  await write("shared-handlers/same.js", "function same() { return 2; }");
  const { getKnowledgeBase } = await import("../src/services/KnowledgeBaseManager.js");
  expect(
    (await getKnowledgeBase()).sharedHandlers.find((h) => h.name === "same")!.content,
  ).toContain("return 1");
  const { processKnowledgeBasePath } = await import("../scripts/kbPathProcessor.js");
  const { report } = await import("../scripts/kbReport.js");
  await processKnowledgeBasePath(localPath, false);
  expect(report.errors).toEqual([]);
  expect(report.totalSharedHandlers).toBe(1);
});

it("validates the same AppleScript block the runtime selects from mixed-language tips", async () => {
  const markdown =
    "---\ntitle: Mixed language tip\nlanguage: applescript\n---\n```javascript\n42\n```\n```applescript\nreturn 42\n```";
  await write("category/mixed.md", markdown);
  expect(parseMarkdownTipFile(markdown, "mixed.md")!.script).toBe("return 42");
  const { processKnowledgeBasePath } = await import("../scripts/kbPathProcessor.js");
  const { report } = await import("../scripts/kbReport.js");
  await processKnowledgeBasePath(localPath, true);
  expect(
    report.warnings.some((warning) => warning.includes("differs from script block language")),
  ).toBe(false);
});
