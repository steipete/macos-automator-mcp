---
title: "JS Snippet: Extract All Links from Page"
category: "04_web_browsers" # Subdir: _common_browser_js_snippets
id: js_extract_all_links
description: "JavaScript to find all <a> tags on a page and return their href attributes."
keywords: ["javascript", "dom", "extract links", "scrape", "href", "anchor tags"]
language: javascript
notes: "Returns an array of URL strings. AppleScript will receive this as a single string, often newline-separated if the JS uses `join('\\n')`."
---

```javascript
(() => {
  const links = [];
  const all_a_tags = document.getElementsByTagName('a');
  for (let i = 0; i < all_a_tags.length; i++) {
    if (all_a_tags[i].href) {
      links.push(all_a_tags[i].href);
    }
  }
  return links.join('\\n'); // Join with newlines for AppleScript to parse easily
})();
```
END_TIP 