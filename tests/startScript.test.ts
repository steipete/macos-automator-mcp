import { expect, it } from "vitest";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";

it.each(["compiled", "local", "global"])(
  "forwards launcher arguments through the %s runtime",
  async (runner) => {
    const root = await fs.mkdtemp(path.join(os.tmpdir(), "mcp-launcher-"));
    try {
      await fs.copyFile(new URL("../start.sh", import.meta.url), path.join(root, "start.sh"));
      const bin = path.join(root, "bin");
      await fs.mkdir(bin);
      await fs.symlink(process.execPath, path.join(bin, "node"));
      if (runner === "compiled") {
        await fs.mkdir(path.join(root, "dist"));
        await fs.writeFile(
          path.join(root, "dist/server.js"),
          'console.log(JSON.stringify({runner:"compiled",args:process.argv.slice(2)}));',
        );
      } else {
        await fs.mkdir(path.join(root, "src"));
        await fs.writeFile(path.join(root, "src/server.ts"), "// Synthetic source fixture\n");
        const localBin = path.join(root, "node_modules/.bin");
        await fs.mkdir(localBin, { recursive: true });
        for (const [location, name] of [
          [path.join(localBin, "tsx"), "local"],
          ...(runner === "global" ? [[path.join(bin, "tsx"), "global"]] : []),
        ]) {
          await fs.writeFile(
            location,
            `#!${process.execPath}\nconsole.log(JSON.stringify({runner:${JSON.stringify(name)},args:process.argv.slice(3)}));\n`,
            { mode: 0o755 },
          );
        }
      }
      const output = execFileSync(
        "/bin/bash",
        [path.join(root, "start.sh"), "--version", "two words"],
        {
          encoding: "utf8",
          cwd: os.tmpdir(),
          env: { PATH: `${bin}:/usr/bin:/bin` },
          timeout: 10000,
        },
      );
      expect(JSON.parse(output)).toEqual({ runner, args: ["--version", "two words"] });
    } finally {
      await fs.rm(root, { recursive: true, force: true });
    }
  },
);
