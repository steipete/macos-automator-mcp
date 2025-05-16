---
title: 'StandardAdditions: do shell script Command'
category: 02_as_core
id: osax_do_shell_script
description: Executes a Unix shell command and returns its standard output as a string.
keywords:
  - StandardAdditions
  - do shell script
  - terminal command
  - unix
  - bash
  - zsh
  - execute
language: applescript
notes: >
  - Always use `quoted form of` for any AppleScript variables or dynamic text
  passed into the shell command string to prevent errors and security issues
  with spaces or special characters.

  - When working with file paths, ALWAYS convert AppleScript paths to POSIX
  paths before using them with shell commands using `POSIX path of myPath`.

  - Never use HFS paths (colon-separated) directly in shell commands, as the
  shell expects POSIX paths (slash-separated).

  - Can use `with administrator privileges` to run as root (prompts for
  password).

  - Errors from the shell command will raise an AppleScript error. Use `try`
  blocks.

  - Environment is minimal; full paths to executables often needed.
---

`do shell script` allows AppleScript to run command-line operations.

```applescript
-- Simple command
set whoAmI to do shell script "whoami"

-- Command with arguments and variable substitution
set targetFolder to POSIX path of (path to desktop)
set fileList to do shell script "ls -la " & quoted form of targetFolder

-- Command needing admin rights (example, use with caution)
(*
try
  do shell script "mkdir /opt/my_secure_folder" with administrator privileges
  set adminResult to "Created /opt/my_secure_folder with admin rights."
on error adminErr
  set adminResult to "Admin command failed: " & adminErr
end try
*)

return "User: " & whoAmI & "\\nDesktop Listing (first 100 chars):\\n" & (text 1 thru 100 of fileList) & "..."
-- & "\\nAdmin Result: " & adminResult
```
END_TIP 
