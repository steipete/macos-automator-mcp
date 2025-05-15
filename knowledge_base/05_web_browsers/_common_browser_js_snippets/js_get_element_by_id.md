---
title: "JS Snippet: Get Element by ID"
category: "04_web_browsers" # Subdir: _common_browser_js_snippets
id: js_get_element_by_id
description: "JavaScript to select an HTML element by its unique ID."
keywords: ["javascript", "dom", "getelementbyid", "select element"]
language: javascript # This tip's content is JS
notes: "This snippet is for use inside an AppleScript browser automation command. Returns the DOM element or null."
---

This JavaScript finds an element using its `id` attribute.

```javascript
// Replace 'yourElementId' with the actual ID
document.getElementById('yourElementId');
```
END_TIP 