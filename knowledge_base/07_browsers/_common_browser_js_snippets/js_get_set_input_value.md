---
title: 'JS Snippet: Get/Set Input Field Value'
category: 07_browsers
id: js_get_set_input_value
description: >-
  JavaScript to get or set the value of an HTML input field, textarea, or
  select.
keywords:
  - javascript
  - dom
  - input value
  - form fill
  - textarea
  - select
language: javascript
notes: The 'inputElement' variable must hold a reference to the form field.
---

**Get Value:**
```javascript
// Assume 'inputElement' is a reference to an <input>, <textarea>, or <select>
inputElement ? inputElement.value : null;
```

**Set Value:**
```javascript
// Assume 'inputElement' is a reference to an <input> or <textarea>
// Replace 'New Value Here' with the desired text.
if (inputElement) {
  inputElement.value = 'New Value Here';
}
```
END_TIP 
