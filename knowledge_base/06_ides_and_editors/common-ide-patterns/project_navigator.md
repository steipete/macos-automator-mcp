---
id: project_navigator
title: Quick Project Navigator
description: Creates a quick project navigation system with folder actions
language: applescript
author: Claude
usage_examples:
  - "Quickly open recent projects in preferred editor"
  - "Create a shortcut to navigate between development projects"
  - "Set up automated project tracking in Finder"
parameters:
  - name: projectsDir
    description: Directory containing your projects (POSIX path)
    required: true
  - name: preferredEditor
    description: "Editor to open projects with (vscode, jetbrains, xcode, sublime, default)"
    required: false
---

# Quick Project Navigator

This script creates a system for quickly navigating between development projects using folder actions and a Finder sidebar shortcut.

```applescript
on run {input, parameters}
    set projectsDir to "--MCP_INPUT:projectsDir"
    set preferredEditor to "--MCP_INPUT:preferredEditor"
    
    if projectsDir is "" or projectsDir is missing value then
        -- Try to use a common projects directory if none specified
        set projectsDir to POSIX path of (path to home folder) & "Projects"
        
        -- Check if it exists
        try
            do shell script "test -d " & quoted form of projectsDir
        on error
            -- Second try: Documents/Projects
            set projectsDir to POSIX path of (path to documents folder) & "Projects"
            try
                do shell script "test -d " & quoted form of projectsDir
            on error
                -- Create Projects directory if none exists
                set createChoice to display dialog "No projects directory found. Would you like to create one at ~/Projects?" buttons {"Cancel", "Create"} default button "Create" with icon note
                if button returned of createChoice is "Create" then
                    set projectsDir to POSIX path of (path to home folder) & "Projects"
                    do shell script "mkdir -p " & quoted form of projectsDir
                else
                    display dialog "Please specify an existing projects directory." buttons {"OK"} default button "OK" with icon stop
                    return
                end if
            end try
        end try
    end if
    
    -- Ensure projectsDir has trailing slash
    if character -1 of projectsDir is not "/" then
        set projectsDir to projectsDir & "/"
    end if
    
    -- Set default editor if not specified
    if preferredEditor is "" or preferredEditor is missing value then
        set preferredEditor to "vscode"
    end if
    
    -- Step 1: Create the Projects folder if it doesn't exist
    do shell script "mkdir -p " & quoted form of projectsDir
    
    -- Step 2: Create the recents directory
    set recentsDir to POSIX path of (path to home folder) & "Library/Application Support/ProjectNavigator"
    do shell script "mkdir -p " & quoted form of recentsDir
    
    -- Step 3: Add to Finder sidebar favorites
    tell application "Finder"
        try
            if not (exists folder projectsDir as POSIX file) then
                do shell script "mkdir -p " & quoted form of projectsDir
            end if
            
            -- Add to sidebar if not already there
            try
                set sidebar to get sidebar
                if sidebar does not contain (POSIX file projectsDir) then
                    add POSIX file projectsDir to sidebar
                end if
            on error
                -- Cannot check or add to sidebar due to permissions or API limits
                -- This should be rare in modern macOS versions
            end try
        on error errMsg
            display dialog "Error adding to sidebar: " & errMsg buttons {"OK"} default button "OK" with icon caution
        end try
    end tell
    
    -- Step 4: Create the folder action script for tracking project access
    set folderActionScript to "
        on opening folder this_folder
            tell application \"Finder\"
                set folderPath to POSIX path of (this_folder as alias)
                
                -- Get parent directory
                set parentDir to do shell script \"dirname \" & quoted form of folderPath
                
                -- Check if this is a project directory
                if parentDir ends with \"" & text 1 thru -2 of projectsDir & "\" then
                    -- This is a direct child of the projects directory - track it
                    set projectName to do shell script \"basename \" & quoted form of folderPath
                    set recentsDir to (POSIX path of (path to home folder)) & \"Library/Application Support/ProjectNavigator\"
                    
                    -- Update recents file
                    set recentsFile to recentsDir & \"/recent_projects.txt\"
                    
                    -- Create file if it doesn't exist
                    do shell script \"touch \" & quoted form of recentsFile
                    
                    -- Read current recent projects
                    set recentProjects to paragraphs of (do shell script \"cat \" & quoted form of recentsFile)
                    
                    -- Create new recents list with current project at top
                    set newRecents to projectName
                    
                    -- Add other recent projects (up to 9 total)
                    set count to 1
                    repeat with proj in recentProjects
                        if proj is not \"\" and proj is not projectName and count < 9 then
                            set newRecents to newRecents & return & proj
                            set count to count + 1
                        end if
                    end repeat
                    
                    -- Write updated recents
                    do shell script \"echo \" & quoted form of newRecents & \" > \" & quoted form of recentsFile
                end if
            end tell
        end opening folder
    "
    
    -- Write the folder action script
    set folderActionScriptPath to recentsDir & "/ProjectTracker.scpt"
    do shell script "echo " & quoted form of folderActionScript & " > " & quoted form of folderActionScriptPath & ".txt"
    do shell script "osacompile -o " & quoted form of folderActionScriptPath & " " & quoted form of (folderActionScriptPath & ".txt")
    do shell script "rm " & quoted form of (folderActionScriptPath & ".txt")
    
    -- Step 5: Create the project launcher script
    set launcherScript to "
        on run
            set recentsDir to (POSIX path of (path to home folder)) & \"Library/Application Support/ProjectNavigator\"
            set recentsFile to recentsDir & \"/recent_projects.txt\"
            set projectsDir to \"" & projectsDir & "\"
            set preferredEditor to \"" & preferredEditor & "\"
            
            try
                set recentProjects to paragraphs of (do shell script \"cat \" & quoted form of recentsFile)
            on error
                set recentProjects to {}
            end try
            
            -- Get all projects
            set allProjects to paragraphs of (do shell script \"find \" & quoted form of projectsDir & \" -type d -depth 1 -not -path '*/\\.*' | sort | xargs -I{} basename {}\")
            
            -- Combine lists for display
            set menuItems to {}
            
            -- Add recent projects section if available
            if (count of recentProjects) > 0 then
                set end of menuItems to \"Recent Projects:\"
                repeat with proj in recentProjects
                    if proj is not \"\" then
                        set end of menuItems to \"  \" & proj
                    end if
                end repeat
                set end of menuItems to \"---\"
            end if
            
            -- Add all projects
            set end of menuItems to \"All Projects:\"
            repeat with proj in allProjects
                if proj is not \"\" then
                    set end of menuItems to proj
                end if
            end repeat
            
            -- Add new project option
            set end of menuItems to \"---\"
            set end of menuItems to \"Create New Project...\"
            
            -- Ask user to choose
            set selectedItem to choose from list menuItems with prompt \"Select a project:\" default items item 2 of menuItems
            
            if selectedItem is false then
                return
            end if
            
            set selectedString to item 1 of selectedItem
            
            if selectedString starts with \"  \" then
                -- This is a recent project
                set projectName to text 3 thru -1 of selectedString
            else if selectedString is \"Create New Project...\" then
                -- Create new project
                set projectName to text returned of (display dialog \"Enter new project name:\" default answer \"\" buttons {\"Cancel\", \"Create\"} default button \"Create\")
                if projectName is \"\" then
                    return
                end if
                do shell script \"mkdir -p \" & quoted form of (projectsDir & projectName)
            else if selectedString contains \":\" or selectedString contains \"---\" then
                -- This is a header, ignore
                return
            else
                -- Regular project
                set projectName to selectedString
            end if
            
            -- Open the project in preferred editor
            set projectPath to projectsDir & projectName
            
            if preferredEditor is \"vscode\" then
                do shell script \"open -a 'Visual Studio Code' \" & quoted form of projectPath
            else if preferredEditor is \"jetbrains\" then
                tell application \"Finder\"
                    set ideList to name of every application file whose name contains \"IntelliJ\" or name contains \"WebStorm\" or name contains \"PyCharm\" or name contains \"PhpStorm\" or name contains \"Rider\" or name contains \"CLion\" or name contains \"GoLand\" or name contains \"RubyMine\"
                end tell
                
                if (count of ideList) > 0 then
                    do shell script \"open -a '\" & item 1 of ideList & \"' \" & quoted form of projectPath
                else
                    -- Fallback to VS Code if no JetBrains IDE found
                    do shell script \"open -a 'Visual Studio Code' \" & quoted form of projectPath
                end if
            else if preferredEditor is \"xcode\" then
                -- Look for xcodeproj or xcworkspace
                try
                    set hasXcodeProj to (do shell script \"find \" & quoted form of projectPath & \" -maxdepth 1 -name '*.xcodeproj' | wc -l\") > 0
                    set hasXcworkspace to (do shell script \"find \" & quoted form of projectPath & \" -maxdepth 1 -name '*.xcworkspace' | wc -l\") > 0
                    
                    if hasXcworkspace then
                        set xcodeProjPath to do shell script \"find \" & quoted form of projectPath & \" -maxdepth 1 -name '*.xcworkspace' | head -n 1\"
                        do shell script \"open \" & quoted form of xcodeProjPath
                    else if hasXcodeProj then
                        set xcodeProjPath to do shell script \"find \" & quoted form of projectPath & \" -maxdepth 1 -name '*.xcodeproj' | head -n 1\"
                        do shell script \"open \" & quoted form of xcodeProjPath
                    else
                        do shell script \"open -a 'Xcode' \" & quoted form of projectPath
                    end if
                on error
                    do shell script \"open -a 'Xcode' \" & quoted form of projectPath
                end try
            else if preferredEditor is \"sublime\" then
                do shell script \"open -a 'Sublime Text' \" & quoted form of projectPath
            else
                -- Default to Finder
                do shell script \"open \" & quoted form of projectPath
            end if
        end run
    "
    
    -- Write the launcher script
    set launcherScriptPath to recentsDir & "/ProjectLauncher.app"
    
    -- Remove existing app if it exists
    do shell script "rm -rf " & quoted form of launcherScriptPath
    
    -- Create and compile the app
    do shell script "mkdir -p " & quoted form of (recentsDir & "/temp")
    do shell script "echo " & quoted form of launcherScript & " > " & quoted form of (recentsDir & "/temp/launcher.applescript")
    do shell script "osacompile -o " & quoted form of launcherScriptPath & " " & quoted form of (recentsDir & "/temp/launcher.applescript")
    do shell script "rm -rf " & quoted form of (recentsDir & "/temp")
    
    -- Step 6: Set up folder action
    try
        tell application "System Events"
            -- Enable folder actions
            set folder actions enabled to true
            
            -- Attach script to projects dir
            try
                make new folder action at end of folder actions with properties {path:projectsDir}
            on error
                -- Folder action might already exist
            end try
            
            -- Attach the script
            tell folder action projectsDir
                make new script at end of scripts with properties {path:folderActionScriptPath}
            end tell
            
            -- Launch the Project Navigator app (to show it to the user)
            do shell script "open " & quoted form of launcherScriptPath
        end tell
    on error errMsg
        display dialog "Error setting up folder action: " & errMsg & return & return & "You may need to give permission in System Preferences > Security & Privacy > Privacy > Automation." buttons {"OK"} default button "OK" with icon caution
    end try
    
    return "Project Navigator set up successfully with Projects directory at " & projectsDir & " and launcher at " & launcherScriptPath
end run
```

## How the Project Navigator Works

This script creates a complete project navigation system:

1. **Folder Action Tracking**: Automatically logs which projects you open
2. **Recent Projects List**: Maintains a list of recently opened projects
3. **Quick Launcher**: Provides a menu to quickly open any project
4. **Finder Integration**: Adds your projects folder to the Finder sidebar

## Using the Project Navigator

After setup:

1. **Find in Applications**: The Project Launcher app will be in `~/Library/Application Support/ProjectNavigator/ProjectLauncher.app`
2. **Add to Dock**: Drag the launcher app to your Dock for quick access
3. **Launch**: Click the launcher to see a list of recent and all projects
4. **Create New Projects**: Option to create new projects directly from the launcher

## Editor Integration

The navigator supports different code editors:

1. **Visual Studio Code**: Default option, opens projects directly
2. **JetBrains IDEs**: Auto-detects available JetBrains editors
3. **Xcode**: Smart detection of `.xcodeproj` and `.xcworkspace` files
4. **Sublime Text**: Opens projects in Sublime
5. **Default**: Opens projects in Finder if no editor is specified

## Customization Options

To personalize your Project Navigator:

1. **Change Default Editor**: Modify `preferredEditor` parameter
2. **Custom Project Directory**: Set `projectsDir` to your preferred location
3. **Project Organization**: Create subdirectories in your projects folder
4. **Aliases**: Create aliases to your most-used projects in Finder

## System Requirements

This script requires:

1. macOS 10.13 (High Sierra) or later
2. Permission to use Automation (System Preferences > Security & Privacy)
3. Your preferred code editor(s) installed