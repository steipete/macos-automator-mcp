import { expect, it, vi } from "vitest";
import type { LoadedKnowledgePath } from "../src/services/kbLoader.js";

vi.mock("node:fs/promises", () => ({ default: { access: async () => {} } }));
vi.mock("../src/logger.js", () => ({
  Logger: class {
    info() {}
    debug() {}
    warn() {}
    error() {}
  },
}));
const { load } = vi.hoisted(() => ({ load: vi.fn() }));
vi.mock("../src/services/kbLoader.js", () => ({ loadTipsAndHandlersFromPath: load }));

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((done) => {
    resolve = done;
  });
  return { promise, resolve };
}
function data(id: string): LoadedKnowledgePath {
  return {
    categories: [{ id: "test", description: "test", tipCount: 1 }],
    sharedHandlers: [],
    tips: [
      {
        id,
        category: "test",
        title: id,
        script: "return 1",
        language: "applescript",
        keywords: [],
        filePath: "synthetic.md",
      },
    ],
  };
}

it("keeps the newest refresh cached when an older load finishes last", async () => {
  const old = deferred<LoadedKnowledgePath>();
  const started = deferred<void>();
  let embeddedCalls = 0;
  load.mockImplementation((_path: string, local: boolean) => {
    if (local) return Promise.resolve({ categories: [], tips: [], sharedHandlers: [] });
    if (++embeddedCalls === 1) {
      started.resolve();
      return old.promise;
    }
    return Promise.resolve(data("new"));
  });
  const { getKnowledgeBase, forceReloadKnowledgeBase } =
    await import("../src/services/KnowledgeBaseManager.js");
  const first = getKnowledgeBase();
  await started.promise;
  expect((await forceReloadKnowledgeBase()).tips[0].id).toBe("new");
  old.resolve(data("old"));
  expect((await first).tips[0].id).toBe("old");
  expect((await getKnowledgeBase()).tips[0].id).toBe("new");
  expect(embeddedCalls).toBe(2);
});
