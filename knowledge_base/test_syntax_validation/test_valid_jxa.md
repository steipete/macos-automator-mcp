---
title: "Test Valid JXA"
category: "test_syntax_validation"
description: "A valid JavaScript for Automation file for testing syntax validation."
keywords: ["test", "validation", "jxa", "javascript", "syntax"]
language: javascript
---

This is a test file with valid JXA syntax.

```javascript
// This is a valid JXA file
var app = Application.currentApplication();
app.includeStandardAdditions = true;

app.displayDialog("Hello, world!");

// Return a result
"JXA syntax is valid.";
```