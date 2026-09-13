export const SHARED_HANDLER_DIRECTORIES: readonly string[] = [
  "_shared_handlers",
  "shared-handlers",
];

export function extractScriptBlock(
  markdown: string,
): { script: string; language: "applescript" | "javascript" } | null {
  // Preserve the documented AppleScript precedence in mixed-language tips.
  for (const language of ["applescript", "javascript"] as const) {
    const match = markdown.match(new RegExp("```" + language + "\\s*\\n([\\s\\S]*?)\\n```", "i"));
    if (match) return { script: match[1].trim(), language };
  }
  return null;
}
