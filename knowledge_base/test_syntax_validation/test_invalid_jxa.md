---
title: "Test Invalid JXA"
category: "test_syntax_validation"
description: "An invalid JavaScript for Automation file for testing syntax validation."
keywords: ["test", "validation", "jxa", "javascript", "syntax", "error"]
language: javascript
---

This is a test file with invalid JXA syntax.

```javascript
// This JXA has a syntax error
var app = Application.currentApplication();
app.includeStandardAdditions = true;

app.displayDialog("Hello, world!" // Missing closing parenthesis

if (true) {
    // Missing closing brace

"This should fail validation.";
```