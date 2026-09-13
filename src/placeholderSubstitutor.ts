export interface SubstitutionResult {
  substitutedScript: string;
  logs: string[];
}

export function escapeForAppleScriptStringLiteral(value: string): string {
  return `"${value.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
}

function camelToSnake(str: string): string {
  return str.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`);
}

export function valueToAppleScriptLiteral(value: unknown): string {
  if (typeof value === "string") {
    return escapeForAppleScriptStringLiteral(value);
  }
  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }
  if (Array.isArray(value)) {
    return `{${value.map((v) => valueToAppleScriptLiteral(v)).join(", ")}}`;
  }
  if (typeof value === "object" && value !== null) {
    const recordParts = Object.entries(value).map(
      ([key, value]) => `${appleScriptIdentifier(key)}:${valueToAppleScriptLiteral(value)}`,
    );
    return `{${recordParts.join(", ")}}`;
  }
  return "missing value";
}

// AppleScript language keywords, excluding application/property terminology such as name.
const appleScriptKeywords = new Set(
  `about above after against and apart around as aside at back before
beginning behind below beneath beside between but by considering contain contains continue copy div
does eighth else end equal equals error every exit false fifth first for fourth from front get given
global if ignoring in instead into is it its last local me middle mod my ninth not of on onto or out
over prop property put ref reference repeat return returning script second set seventh since sixth
some tell tenth that the then third through thru timeout times to transaction true try until use
where while whose with without`.split(/\s+/),
);

function appleScriptIdentifier(key: string): string {
  if (/^[a-zA-Z][a-zA-Z0-9_]*$/.test(key) && !appleScriptKeywords.has(key.toLowerCase()))
    return key;
  return `|${key.replace(/\\/g, "\\\\").replace(/\|/g, "\\|")}|`;
}

function valueToJavaScriptLiteral(value: unknown): string {
  const json = JSON.stringify(value) ?? "null";
  // Object initializers give __proto__ special meaning; JSON parsing preserves data keys.
  return value !== null && typeof value === "object" ? `JSON.parse(${JSON.stringify(json)})` : json;
}

interface SubstitutePlaceholdersArgs {
  scriptContent: string;
  inputData?: Record<string, unknown>;
  args?: string[];
  language?: "applescript" | "javascript";
  includeSubstitutionLogs: boolean;
}

const templateToken = String.raw`\$\{(?:inputData\.\w+|arguments\[\d+\])\}`;
const legacyToken = String.raw`--MCP_(?:INPUT:\w+|ARG_\d+)`;
const placeholderPattern = new RegExp(
  `(["'])(${templateToken}|${legacyToken})\\1|(${templateToken})|([(,=]\\s*)(${legacyToken})\\b`,
  "g",
);

export function substitutePlaceholders({
  scriptContent,
  inputData,
  args,
  language = "applescript",
  includeSubstitutionLogs,
}: SubstitutePlaceholdersArgs): SubstitutionResult {
  const logs: string[] = [];
  // One pass over source: inserted values must never become template syntax.
  const substitutedScript = scriptContent.replace(
    placeholderPattern,
    (
      match: string,
      _quote: string | undefined,
      quotedToken: string | undefined,
      bareTemplate: string | undefined,
      prefix: string | undefined,
      bareLegacy: string | undefined,
    ) => {
      const token = quotedToken ?? bareTemplate ?? bareLegacy!;
      const named = token.match(/(?:inputData\.|MCP_INPUT:)(\w+)/);
      let value: unknown;
      if (named) {
        const key = camelToSnake(named[1]);
        value = inputData && Object.hasOwn(inputData, key) ? inputData[key] : undefined;
      } else {
        const position = token.match(/(?:arguments\[|MCP_ARG_)(\d+)/)!;
        const index = Number(position[1]) - (token.startsWith("--MCP_") ? 1 : 0);
        value = args && index >= 0 && index < args.length ? args[index] : undefined;
      }
      const replacement =
        language === "javascript"
          ? valueToJavaScriptLiteral(value)
          : valueToAppleScriptLiteral(value);
      if (includeSubstitutionLogs) logs.push(`[SUBST] ${JSON.stringify({ match, replacement })}`);
      return (prefix ?? "") + replacement;
    },
  );
  return { substitutedScript, logs };
}
