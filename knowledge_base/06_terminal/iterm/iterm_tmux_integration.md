---
id: iterm_tmux_integration
title: iTerm2 tmux Integration
description: Sets up and manages tmux integration with iTerm2
language: applescript
author: Claude
keywords:
  - terminal
  - tmux
  - session-persistence
  - remote-connection
  - collaboration
usage_examples:
  - Connect to a remote tmux session with native iTerm2 interface
  - Set up a local tmux environment with multiple windows
  - Attach to an existing tmux session
parameters:
  - name: host
    description: Optional hostname for remote tmux (leave empty for local)
    required: false
  - name: sessionName
    description: Name of the tmux session to create or attach to
    required: true
  - name: createNew
    description: Whether to create a new session if it doesn't exist (true/false)
    required: false
category: 06_terminal
---

# iTerm2 tmux Integration

This script manages the integration between iTerm2 and tmux, allowing you to use iTerm2's native interface with tmux's session persistence capabilities.

```applescript
on run {input, parameters}
    set host to "--MCP_INPUT:host"
    set sessionName to "--MCP_INPUT:sessionName"
    set createNew to "--MCP_INPUT:createNew"
    
    if sessionName is "" or sessionName is missing value then
        display dialog "Please provide a tmux session name." buttons {"OK"} default button "OK" with icon stop
        return
    end if
    
    -- Set defaults if not provided
    if createNew is "" or createNew is missing value then
        set createNew to "true"
    end if
    
    -- Check if this is a local or remote session
    set isRemote to (host is not "" and host is not missing value)
    
    -- Build the tmux command
    set tmuxCommand to "tmux -CC "
    
    if createNew is "true" then
        -- Command to attach if exists or create new
        set tmuxCommand to tmuxCommand & "new-session -A -s " & quoted form of sessionName
    else
        -- Command to attach only, will fail if session doesn't exist
        set tmuxCommand to tmuxCommand & "attach-session -t " & quoted form of sessionName
    end if
    
    tell application "iTerm"
        -- Create a new window and run the appropriate command
        create window with default profile
        
        tell current window
            tell current session
                if isRemote then
                    -- For remote sessions, first SSH to the host
                    set sshCommand to "ssh " & host & " -t " & quoted form of tmuxCommand
                    write text sshCommand
                else
                    -- For local sessions, run tmux directly
                    write text tmuxCommand
                end if
            end tell
        end tell
    end tell
    
    return "Connected to " & (if isRemote then "remote" else "local") & " tmux session: " & sessionName
end run
```

## Understanding iTerm2-tmux Integration

iTerm2's tmux integration provides a powerful combination of tmux's session persistence with iTerm2's native UI features. This integration allows you to:

1. **Preserve your terminal sessions** even if you disconnect or your computer crashes
2. **Use iTerm2's interface** rather than the standard tmux command interface
3. **Take advantage of iTerm2 features** like native scrolling, split panes, and mouse support
4. **Connect to remote tmux sessions** with the same native interface

## How the Integration Works

When you run `tmux -CC` (Control Center mode), tmux and iTerm2 establish a special control connection that allows iTerm2 to render the tmux session using its native UI components. In this mode:

- Each tmux window becomes an iTerm2 tab
- Each tmux pane becomes an iTerm2 split pane
- iTerm2 features like unlimited scrollback, mouse reporting, and drag-and-drop work normally

## Use Cases

### Local Development with Persistence

For local development, iTerm2-tmux integration provides a safety net against terminal crashes or accidental closures. Your terminal state is preserved inside tmux.

### Remote Server Management

When managing remote servers, you can establish a tmux session that persists even if your connection drops. This is especially valuable for:

- Long-running processes
- Servers with unreliable connections
- Working from multiple locations
- Collaborative development (multiple people can attach to the same tmux session)

## Advanced Script Modifications

### Creating a Multi-Window tmux Setup

To extend this script to create a predefined tmux workspace with multiple windows:

```applescript
on setupDevelopmentEnvironment(sessionName)
    tell application "iTerm"
        create window with default profile
        tell current window
            tell current session
                -- Create new tmux session with development layout
                set tmuxSessionSetup to "tmux -CC new-session -A -s " & quoted form of sessionName & " \\; "
                set tmuxSessionSetup to tmuxSessionSetup & "rename-window 'server' \\; "
                set tmuxSessionSetup to tmuxSessionSetup & "new-window -n 'client' \\; "
                set tmuxSessionSetup to tmuxSessionSetup & "new-window -n 'database' \\; "
                set tmuxSessionSetup to tmuxSessionSetup & "new-window -n 'logs' \\; "
                set tmuxSessionSetup to tmuxSessionSetup & "select-window -t 'server'"
                
                write text tmuxSessionSetup
            end tell
        end tell
    end tell
end setupDevelopmentEnvironment
```

### Monitoring Remote Servers

To use this script for managing multiple servers:

```applescript
on connectToServers()
    set servers to {{"web1", "web-server-1.example.com"}, {"db", "db-server.example.com"}, {"staging", "staging.example.com"}}
    
    repeat with serverInfo in servers
        set sessionName to item 1 of serverInfo
        set hostName to item 2 of serverInfo
        
        tell application "iTerm"
            create window with default profile
            tell current window
                tell current session
                    set sshCommand to "ssh " & hostName & " -t 'tmux -CC new-session -A -s monitoring'"
                    write text sshCommand
                end tell
            end tell
        end tell
        
        -- Add a slight delay between connections
        delay 2
    end repeat
end connectToServers
```

## Troubleshooting Tips

1. **Control Mode Issues**: If iTerm2 doesn't properly integrate with tmux, ensure you're using the `-CC` flag.
2. **Remote Connection Problems**: For remote connections, make sure your SSH connection is stable and tmux is installed on the remote server.
3. **Version Compatibility**: iTerm2's tmux integration works best with tmux 2.1 and newer.
4. **Session Already Exists**: If a session exists, the script will attach to it instead of creating a new one (with `-A` flag).
