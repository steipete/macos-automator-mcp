---
id: sublime_text_package_management
title: Manage Sublime Text packages
description: 'Install, list, or remove Sublime Text packages using Package Control'
language: applescript
author: Claude
keywords:
  - Package Control
  - extensions
  - plugin management
  - package installation
  - package removal
usage_examples:
  - Install a new package in Sublime Text
  - List installed packages
  - Remove a package from Sublime Text
parameters:
  - name: action
    description: 'The action to perform (''install'', ''list'', ''remove'')'
    required: true
  - name: packageName
    description: The name of the package to install or remove
    required: false
category: 08_editors
---

# Manage Sublime Text packages

This script provides functionality for managing Sublime Text packages via Package Control. It can install new packages, list installed packages, or remove existing packages.

```applescript
on run {input, parameters}
    set action to "--MCP_INPUT:action"
    set packageName to "--MCP_INPUT:packageName"
    
    -- Validate action
    if action is not "install" and action is not "list" and action is not "remove" then
        return "Error: Invalid action. Use 'install', 'list', or 'remove'."
    end if
    
    -- Check if Package Control is required but package name is missing
    if (action is "install" or action is "remove") and (packageName is "" or packageName is missing value) then
        return "Error: Package name is required for '" & action & "' action."
    end if
    
    -- Check if Sublime Text is running
    tell application "System Events"
        set isRunning to (exists process "Sublime Text")
    end tell
    
    if not isRunning then
        tell application "Sublime Text" to activate
        delay 1 -- Give time for Sublime Text to start
    end if
    
    -- Activate Sublime Text
    tell application "Sublime Text"
        activate
        delay 0.5
    end tell
    
    -- Check if Package Control is installed
    if not my isPackageControlInstalled() then
        return "Error: Package Control is not installed in Sublime Text. Please install it first."
    end if
    
    -- Perform the requested action
    if action is "install" then
        return my installPackage(packageName)
    else if action is "list" then
        return my listPackages()
    else if action is "remove" then
        return my removePackage(packageName)
    end if
end run

-- Check if Package Control is installed
on isPackageControlInstalled()
    -- Try to open Package Control through the command palette
    -- If it's not found, it will not appear in the results
    
    tell application "System Events"
        tell process "Sublime Text"
            -- Open command palette
            keystroke "p" using {command down, shift down}
            delay 0.3
            
            -- Start typing "Package Control:"
            keystroke "Package Control:"
            delay 0.5
            
            -- Check if any menu items appeared
            try
                -- Check if there's at least one Package Control menu item
                if exists menu item 1 of menu 1 of window 1 then
                    -- Cancel the command palette
                    keystroke escape
                    return true
                end if
            on error
                -- No menu items found
                keystroke escape
                return false
            end try
        end tell
    end tell
    
    -- Cancel the command palette if it's still open
    tell application "System Events"
        keystroke escape
    end tell
    
    return false
end isPackageControlInstalled

-- Install a package using Package Control
on installPackage(packageName)
    tell application "System Events"
        tell process "Sublime Text"
            -- Open command palette
            keystroke "p" using {command down, shift down}
            delay 0.3
            
            -- Type "Package Control: Install Package"
            keystroke "Package Control: Install Package"
            delay 0.3
            
            -- Execute the command
            keystroke return
            
            -- Wait for the package list to load
            delay 2
            
            -- Type the package name
            keystroke packageName
            delay 0.5
            
            -- Wait for search results to narrow down
            -- At this point, the user needs to select the specific package and press Return
            -- Since we can't programmatically determine which package is the correct one in the list,
            -- we'll provide instructions to the user
        end tell
    end tell
    
    return "Package search executed for '" & packageName & "'. Please select the package from the list and press Return to install."
end installPackage

-- List installed packages
on listPackages()
    tell application "System Events"
        tell process "Sublime Text"
            -- Open command palette
            keystroke "p" using {command down, shift down}
            delay 0.3
            
            -- Type "Package Control: List Packages"
            keystroke "Package Control: List Packages"
            delay 0.3
            
            -- Execute the command
            keystroke return
        end tell
    end tell
    
    return "Listing installed packages in Sublime Text."
end listPackages

-- Remove a package using Package Control
on removePackage(packageName)
    tell application "System Events"
        tell process "Sublime Text"
            -- Open command palette
            keystroke "p" using {command down, shift down}
            delay 0.3
            
            -- Type "Package Control: Remove Package"
            keystroke "Package Control: Remove Package"
            delay 0.3
            
            -- Execute the command
            keystroke return
            
            -- Wait for the package list to load
            delay 1
            
            -- Type the package name
            keystroke packageName
            delay 0.5
            
            -- Since we can't programmatically determine which package is the correct one in the list,
            -- we'll provide instructions to the user
        end tell
    end tell
    
    return "Package removal dialog opened for '" & packageName & "'. Please select the package from the list and press Return to remove it."
end removePackage
```
