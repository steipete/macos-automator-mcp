---
title: 'JS Snippet: Click Element'
category: 07_browsers
id: js_click_element
description: JavaScript to programmatically click an HTML element.
keywords:
  - javascript
  - dom
  - click
  - interaction
language: javascript
notes: >-
  The 'element' variable must first be obtained (e.g., via getElementById or
  querySelector).
---

This JavaScript simulates a click on a previously selected DOM element.

```javascript
// Assume 'element' is a variable holding a reference to a DOM element
if (element) {
  element.click();
}
```
END_TIP 
