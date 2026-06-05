import { describe, it, expect } from "vitest";
import { substitutePlaceholders } from "../src/placeholderSubstitutor.js";

describe("substitutePlaceholders – JS-style ${...} placeholders", () => {
  it("substitutes ${inputData.key} with the AppleScript literal", () => {
    const { substitutedScript } = substitutePlaceholders({
      scriptContent: "display dialog ${inputData.message}",
      inputData: { message: "hi" },
      includeSubstitutionLogs: false,
    });
    expect(substitutedScript).toBe('display dialog "hi"');
  });

  it("substitutes ${arguments[N]} with the AppleScript literal at that index", () => {
    const { substitutedScript } = substitutePlaceholders({
      scriptContent: "display dialog ${arguments[0]} & ${arguments[1]}",
      args: ["world", "again"],
      includeSubstitutionLogs: false,
    });
    expect(substitutedScript).toBe('display dialog "world" & "again"');
  });

  it("maps a camelCase ${inputData.appName} placeholder to the snake_case input_data key", () => {
    const { substitutedScript } = substitutePlaceholders({
      scriptContent: "tell application ${inputData.appName}",
      inputData: { app_name: "Safari" },
      includeSubstitutionLogs: false,
    });
    expect(substitutedScript).toBe('tell application "Safari"');
  });

  it("emits the AppleScript bare keyword `missing value` for an absent key or out-of-range index", () => {
    const { substitutedScript } = substitutePlaceholders({
      scriptContent: "set a to ${inputData.nope}\nset b to ${arguments[5]}",
      inputData: { message: "hi" },
      args: ["only-one"],
      includeSubstitutionLogs: false,
    });
    expect(substitutedScript).toBe("set a to missing value\nset b to missing value");
  });

  it("still substitutes the quoted --MCP_INPUT: style (regression guard)", () => {
    const { substitutedScript } = substitutePlaceholders({
      scriptContent: 'display dialog "--MCP_INPUT:message"',
      inputData: { message: "hi" },
      includeSubstitutionLogs: false,
    });
    expect(substitutedScript).toBe('display dialog "hi"');
  });
});
