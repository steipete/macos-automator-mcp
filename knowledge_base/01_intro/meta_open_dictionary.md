---
title: "Meta: Exploring Application Scriptability (Open Dictionary)"
category: "00_readme_and_conventions"
id: meta_open_dictionary
description: "Explains how to use Script Editor's 'Open Dictionary...' feature to discover an application's scriptable commands, objects, and properties."
keywords: ["script editor", "dictionary", "scriptable", "automation", "discover", "sdef"]
language: applescript # Language is context for the tip, not the script block here
---

The key to automating any macOS application with AppleScript is understanding its "scripting dictionary." This dictionary lists all the commands the application understands and all the objects it can work with.

**How to Open an Application's Dictionary:**

1.  Launch **Script Editor** (usually found in `/Applications/Utilities/`).
2.  Go to the **File** menu.
3.  Select **Open Dictionary...**
4.  A list of scriptable applications on your Mac will appear. Select the application you want to explore (e.g., "Finder", "Safari", "Mail", "Calendar") and click "Choose".

**What You'll See:**
The dictionary window opens, typically showing:
-   **Suites:** Groups of related commands and objects (e.g., "Standard Suite", "Text Suite", application-specific suites).
-   **Commands:** Verbs or actions the application can perform (e.g., `open`, `close`, `make new`, `get`, `set`, `delete`). Each command will list its parameters and what it returns.
-   **Classes (Objects):** Nouns or things the application works with (e.g., `window`, `document`, `tab`, `event`, `message`, `file`, `folder`). Each class will list:
    -   `Elements`: Other objects it can contain (e.g., a `window` contains `tabs`).
    -   `Properties`: Attributes of the object (e.g., a `tab` has a `URL` property and a `name` property).

**Using the Dictionary:**
-   Click on a command or class to see its detailed description, parameters (for commands), and properties/elements (for classes).
-   This is your primary reference for figuring out *how* to tell an application to do something.

```applescript
(*
  This is not a runnable script, but a conceptual guide.
  You would use the information found in a dictionary like this:
*)

-- After looking at Safari's dictionary, you might find:
-- Class: document
--   Properties:
--     URL (text) : The URL of the document.
--     name (text) : The title of the document.

-- So, you could write:
(*
tell application "Safari"
  if (count of documents) > 0 then
    set docName to name of front document
    set docURL to URL of front document
    display dialog "Page: " & docName & "\\nURL: " & docURL
  end if
end tell
*)
```
**Note:** Not all applications are scriptable, and some have more extensive dictionaries than others. "System Events" has a very large dictionary for UI scripting and process control.
END_TIP 