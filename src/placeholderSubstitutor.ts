export interface SubstitutionResult {
  substitutedScript: string;
  logs: string[];
}

// Helper functions for KB script argument substitution
export function escapeForAppleScriptStringLiteral(value: string): string {
    return `"${value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
}

export function valueToAppleScriptLiteral(value: unknown): string {
    if (typeof value === 'string') {
        return escapeForAppleScriptStringLiteral(value);
    }
    if (typeof value === 'number' || typeof value === 'boolean') {
        return String(value);
    }
    if (Array.isArray(value)) {
        return `{${value.map(v => valueToAppleScriptLiteral(v)).join(", ")}}`;
    }
    if (typeof value === 'object' && value !== null) {
        const recordParts = Object.entries(value).map(([k, v]) => `${k}:${valueToAppleScriptLiteral(v)}`);
        return `{${recordParts.join(", ")}}`;
    }
    // Consider throwing an error or having a more specific way to log warnings
    // For now, mirroring server.ts behavior and relying on its logger
    // logger.warn('Unsupported type for AppleScript literal conversion, using "missing value"', { value });
    console.warn('[placeholderSubstitutor] Unsupported type for AppleScript literal conversion, using "missing value"', { value });
    return "missing value"; // AppleScript's equivalent of null/undefined (bare keyword)
}

interface SubstitutePlaceholdersArgs {
    scriptContent: string;
    inputData?: Record<string, unknown>;
    args?: string[];
    includeSubstitutionLogs: boolean;
    // Add a logger instance or a logging callback if fine-grained logging from here is needed
    // For now, logs are collected and returned.
}

export function substitutePlaceholders(
    { scriptContent, inputData, args, includeSubstitutionLogs }: SubstitutePlaceholdersArgs
): SubstitutionResult {
    let currentScriptContent = scriptContent;
    const substitutionLogs: string[] = [];

    const logSub = (message: string, data: unknown) => {
        const logEntry = `[SUBST] ${message} ${JSON.stringify(data)}`;
        if (includeSubstitutionLogs) {
            substitutionLogs.push(logEntry);
        }
    };

    // JS-style ${inputData.key}
    const jsInputDataRegex = /\\$\\{inputData\\.(\\w+)\\}/g;
    logSub('Before jsInputDataRegex', { scriptContentLength: currentScriptContent.length });
    currentScriptContent = currentScriptContent.replace(jsInputDataRegex, (match, keyName) => {
        const replacementValue = inputData && keyName in inputData
            ? valueToAppleScriptLiteral(inputData[keyName])
            : "missing value"; // Bare keyword
        logSub('jsInputDataRegex replacing', { match, keyName, replacementValue });
        return replacementValue;
    });
    logSub('After jsInputDataRegex', { scriptContentLength: currentScriptContent.length });

    // JS-style ${arguments[N]}
    const jsArgumentsRegex = /\\$\\{arguments\\[(\\d+)\\]\\}/g;
    logSub('Before jsArgumentsRegex', { scriptContentLength: currentScriptContent.length });
    currentScriptContent = currentScriptContent.replace(jsArgumentsRegex, (match, indexStr) => {
        const index = Number.parseInt(indexStr, 10);
        const replacementValue = args && index >= 0 && index < args.length
            ? valueToAppleScriptLiteral(args[index])
            : "missing value"; // Bare keyword
        logSub('jsArgumentsRegex replacing', { match, indexStr, index, replacementValue });
        return replacementValue;
    });
    logSub('After jsArgumentsRegex', { scriptContentLength: currentScriptContent.length });
    
    // Quoted "--MCP_INPUT:keyName" (handles single or double quotes around the placeholder)
    const quotedMcpInputRegex = /(["'])--MCP_INPUT:(\w+)\1/g; 
    logSub('Before quotedMcpInputRegex (match surrounding quotes)', { scriptContentLength: currentScriptContent.length });
    currentScriptContent = currentScriptContent.replace(quotedMcpInputRegex, (match, _openingQuote, keyName) => {
         const replacementValue = inputData && keyName in inputData
            ? valueToAppleScriptLiteral(inputData[keyName])
            : "missing value"; 
         logSub('quotedMcpInputRegex (match surrounding quotes) replacing', { match, keyName, replacementValue });
         return replacementValue; 
    });
    logSub('After quotedMcpInputRegex (match surrounding quotes)', { scriptContentLength: currentScriptContent.length });

    // Quoted "--MCP_ARG_N" (handles single or double quotes)
    const quotedMcpArgRegex = /(["'])--MCP_ARG_(\d+)\1/g;
    logSub('Before quotedMcpArgRegex (match surrounding quotes)', { scriptContentLength: currentScriptContent.length });
    currentScriptContent = currentScriptContent.replace(quotedMcpArgRegex, (match, _openingQuote, argNumStr) => {
        const argIndex = Number.parseInt(argNumStr, 10) - 1;
        const replacementValue = args && argIndex >= 0 && argIndex < args.length
            ? valueToAppleScriptLiteral(args[argIndex])
            : "missing value"; 
        logSub('quotedMcpArgRegex (match surrounding quotes) replacing', { match, argNumStr, argIndex, replacementValue });
        return replacementValue;
    });
    logSub('After quotedMcpArgRegex (match surrounding quotes)', { scriptContentLength: currentScriptContent.length });

    // Context-aware bare placeholders (not in comments) e.g., in function calls like myFunc(--MCP_INPUT:key)
    const expressionMcpInputRegex = /([(,=]\s*)--MCP_INPUT:(\w+)\b/g;
    logSub('Before expressionMcpInputRegex', { scriptContentLength: currentScriptContent.length });
    currentScriptContent = currentScriptContent.replace(expressionMcpInputRegex, (match, prefix, keyName) => {
        const replacementValue = inputData && keyName in inputData
                ? valueToAppleScriptLiteral(inputData[keyName])
                : "missing value";
        logSub('expressionMcpInputRegex replacing', { match, prefix, keyName, replacementValue });
        return prefix + replacementValue;
    });
    logSub('After expressionMcpInputRegex', { scriptContentLength: currentScriptContent.length });

    const expressionMcpArgRegex = /([(,=]\s*)--MCP_ARG_(\d+)\b/g;
    logSub('Before expressionMcpArgRegex', { scriptContentLength: currentScriptContent.length });
    currentScriptContent = currentScriptContent.replace(expressionMcpArgRegex, (match, prefix, argNumStr) => {
        const argIndex = Number.parseInt(argNumStr, 10) - 1;
        const replacementValue = args && argIndex >= 0 && argIndex < args.length
                ? valueToAppleScriptLiteral(args[argIndex])
                : "missing value";
        logSub('expressionMcpArgRegex replacing', { match, prefix, argNumStr, argIndex, replacementValue });
        return prefix + replacementValue;
    });
    logSub('After expressionMcpArgRegex', { scriptContentLength: currentScriptContent.length });

    return {
        substitutedScript: currentScriptContent,
        logs: substitutionLogs,
    };
} 