import { runInNewContext } from "node:vm";
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

describe("literal-safe substitution", () => {
  it("never treats substituted input as another placeholder", () => {
    const { substitutedScript } = substitutePlaceholders({
      scriptContent: "return ${inputData.message}",
      inputData: { message: "${arguments[0]}" },
      args: ["changed"],
      includeSubstitutionLogs: false,
    });
    expect(substitutedScript).toBe('return "${arguments[0]}"');
  });

  it("only reads own input properties", () => {
    const { substitutedScript } = substitutePlaceholders({
      scriptContent: "return ${inputData.secret}",
      inputData: Object.create({ secret: "inherited" }) as Record<string, unknown>,
      includeSubstitutionLogs: false,
    });
    expect(substitutedScript).toBe("return missing value");
  });

  it("serializes JXA arrays, records, nulls and strings as JavaScript", () => {
    const { substitutedScript } = substitutePlaceholders({
      scriptContent: "JSON.stringify(${inputData.value})",
      inputData: { value: { items: [1, true, null], text: 'quote"\\\nline' } },
      language: "javascript",
      includeSubstitutionLogs: false,
    });
    expect(JSON.parse(runInNewContext(substitutedScript))).toEqual({
      items: [1, true, null],
      text: 'quote"\\\nline',
    });
  });

  it("uses JavaScript null for missing values", () => {
    expect(
      substitutePlaceholders({
        scriptContent: "${inputData.missing}",
        language: "javascript",
        includeSubstitutionLogs: false,
      }).substitutedScript,
    ).toBe("null");
  });

  it("replaces whole quoted placeholders without adding nested quotes", () => {
    expect(
      substitutePlaceholders({
        scriptContent: 'return "${inputData.message}"',
        inputData: { message: "hello" },
        includeSubstitutionLogs: false,
      }).substitutedScript,
    ).toBe('return "hello"');
  });

  it("retains legacy quoted/expression forms and their positional indexing", () => {
    const result = substitutePlaceholders({
      scriptContent: 'f("--MCP_INPUT:appName", --MCP_ARG_1, "--MCP_ARG_2", --MCP_INPUT:count)',
      inputData: { app_name: "Synthetic", count: 2 },
      args: ["a", "b"],
      includeSubstitutionLogs: true,
    });
    expect(result.substitutedScript).toBe('f("Synthetic", "a", "b", 2)');
    expect(result.logs).toHaveLength(4);
  });
});

it("escapes AppleScript record labels that are not plain identifiers", () => {
  const { substitutedScript } = substitutePlaceholders({
    scriptContent: "return ${inputData.value}",
    inputData: { value: { "foo-bar": 42, "a|b": "value" } },
    includeSubstitutionLogs: false,
  });
  expect(substitutedScript).toBe('return {|foo-bar|:42, |a\\|b|:"value"}');
});

it("preserves own __proto__ keys in nested JXA data", () => {
  const value = JSON.parse('{"items":[{"__proto__":{"flag":true},"normal":2}]}');
  const result = substitutePlaceholders({
    scriptContent: "JSON.stringify(${inputData.value})",
    inputData: { value },
    language: "javascript",
    includeSubstitutionLogs: false,
  });
  expect(JSON.parse(runInNewContext(result.substitutedScript))).toEqual(value);
});

it("quotes reserved AppleScript labels while preserving native property terminology", () => {
  const result = substitutePlaceholders({
    scriptContent: "return ${inputData.value}",
    inputData: { value: { true: 1, return: 2, _private: 3, name: "native" } },
    includeSubstitutionLogs: false,
  });
  expect(result.substitutedScript).toBe(
    'return {|true|:1, |return|:2, |_private|:3, name:"native"}',
  );
});
