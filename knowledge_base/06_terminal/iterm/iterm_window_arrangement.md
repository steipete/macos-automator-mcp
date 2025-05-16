---
id: iterm_window_arrangement
title: iTerm2 Window and Tab Arrangement
description: >-
  Arranges iTerm2 windows and tabs according to predefined layouts or custom
  specifications
language: applescript
author: Claude
keywords:
  - terminal
  - window-management
  - layout
  - multi-monitor
  - workspace-organization
usage_examples:
  - Arrange iTerm2 windows in a grid pattern
  - Create side-by-side windows for different projects
  - Position windows in custom configurations across multiple monitors
parameters:
  - name: layout
    description: 'Layout pattern to use - grid, cascade, horizontal, vertical, or custom'
    required: true
  - name: gridRows
    description: Number of rows for grid layout (default 2)
    required: false
  - name: gridColumns
    description: Number of columns for grid layout (default 2)
    required: false
  - name: positions
    description: 'Array of position objects for custom layout {x, y, width, height}'
    required: false
category: 06_terminal/iterm
---

# iTerm2 Window and Tab Arrangement

This script arranges iTerm2 windows according to various layout patterns, helping you organize your terminal workspace efficiently and consistently.

```applescript
on run {input, parameters}
    set layout to "--MCP_INPUT:layout"
    set gridRows to "--MCP_INPUT:gridRows"
    set gridColumns to "--MCP_INPUT:gridColumns"
    set positions to "--MCP_INPUT:positions"
    
    -- Validate and set defaults for parameters
    if layout is "" or layout is missing value then
        set layout to "grid"
    end if
    
    -- Convert layout to lowercase for case-insensitive comparison
    set layout to my toLowerCase(layout)
    
    -- Set defaults for grid dimensions
    if gridRows is "" or gridRows is missing value then
        set gridRows to 2
    else
        try
            set gridRows to gridRows as integer
            if gridRows < 1 then set gridRows to 1
        on error
            set gridRows to 2
        end try
    end if
    
    if gridColumns is "" or gridColumns is missing value then
        set gridColumns to 2
    else
        try
            set gridColumns to gridColumns as integer
            if gridColumns < 1 then set gridColumns to 1
        on error
            set gridColumns to 2
        end try
    end if
    
    -- Check if positions is a valid list for custom layout
    set hasValidPositions to false
    if layout is "custom" then
        if positions is not "" and positions is not missing value then
            try
                -- Check if it's a list of position objects
                if class of positions is list then
                    set hasValidPositions to true
                end if
            on error
                set hasValidPositions to false
            end try
        end if
        
        if not hasValidPositions then
            return "Error: Custom layout requires valid position specifications."
        end if
    end if
    
    -- Get screen dimensions
    set screenDimensions to getScreenDimensions()
    set screenWidth to item 1 of screenDimensions
    set screenHeight to item 2 of screenDimensions
    
    -- Check if iTerm2 is running
    tell application "System Events"
        if not (exists process "iTerm2") then
            tell application "iTerm2" to activate
            delay 1 -- Give iTerm2 time to launch
        end if
    end tell
    
    -- Apply the selected layout
    tell application "iTerm2"
        -- Check if any windows are open
        if (count of windows) is 0 then
            create window with default profile
            delay 0.5
        end if
        
        set windowCount to count of windows
        
        -- Create additional windows if needed for the layout
        if layout is "grid" then
            set neededWindows to gridRows * gridColumns
        else if layout is "cascade" then
            set neededWindows to 4 -- Default cascade count
        else if layout is "horizontal" then
            set neededWindows to 3 -- Default horizontal count
        else if layout is "vertical" then
            set neededWindows to 3 -- Default vertical count
        else if layout is "custom" then
            set neededWindows to count of positions
        end if
        
        -- Create additional windows if needed
        repeat while windowCount < neededWindows
            create window with default profile
            delay 0.3
            set windowCount to count of windows
        end repeat
        
        -- Apply the selected layout
        if layout is "grid" then
            arrangeInGrid(gridRows, gridColumns, screenWidth, screenHeight)
            return "Arranged " & windowCount & " iTerm2 windows in a " & gridRows & "×" & gridColumns & " grid."
            
        else if layout is "cascade" then
            arrangeInCascade(screenWidth, screenHeight)
            return "Arranged " & windowCount & " iTerm2 windows in a cascade pattern."
            
        else if layout is "horizontal" then
            arrangeHorizontally(screenWidth, screenHeight)
            return "Arranged " & windowCount & " iTerm2 windows horizontally."
            
        else if layout is "vertical" then
            arrangeVertically(screenWidth, screenHeight)
            return "Arranged " & windowCount & " iTerm2 windows vertically."
            
        else if layout is "custom" then
            arrangeCustom(positions)
            return "Applied custom arrangement to iTerm2 windows."
            
        else
            return "Error: Invalid layout type. Use 'grid', 'cascade', 'horizontal', 'vertical', or 'custom'."
        end if
    end tell
end run

-- Arrange windows in a grid
on arrangeInGrid(rows, columns, screenWidth, screenHeight)
    tell application "iTerm2"
        set windowCount to count of windows
        set windowIndex to 1
        
        set marginX to 20
        set marginY to 20
        set usableWidth to screenWidth - (2 * marginX)
        set usableHeight to screenHeight - (2 * marginY)
        
        set cellWidth to usableWidth / columns
        set cellHeight to usableHeight / rows
        
        -- Calculate window dimensions with spacing
        set spacingX to 10
        set spacingY to 10
        set windowWidth to cellWidth - spacingX
        set windowHeight to cellHeight - spacingY
        
        repeat with row from 1 to rows
            repeat with col from 1 to columns
                if windowIndex > windowCount then exit repeat
                
                set winX to marginX + ((col - 1) * cellWidth)
                set winY to marginY + ((row - 1) * cellHeight)
                
                tell window windowIndex
                    set bounds to {winX, winY, winX + windowWidth, winY + windowHeight}
                end tell
                
                set windowIndex to windowIndex + 1
            end repeat
            if windowIndex > windowCount then exit repeat
        end repeat
    end tell
end arrangeInGrid

-- Arrange windows in a cascade pattern
on arrangeInCascade(screenWidth, screenHeight)
    tell application "iTerm2"
        set windowCount to count of windows
        
        set baseWidth to (screenWidth * 0.75)
        set baseHeight to (screenHeight * 0.75)
        set offsetStep to 30
        
        repeat with i from 1 to windowCount
            set winX to 50 + ((i - 1) * offsetStep)
            set winY to 50 + ((i - 1) * offsetStep)
            
            -- Ensure the window doesn't go off screen
            if winX + baseWidth > screenWidth then
                set winX to 50
            end if
            if winY + baseHeight > screenHeight then
                set winY to 50
            end if
            
            tell window i
                set bounds to {winX, winY, winX + baseWidth, winY + baseHeight}
            end tell
        end repeat
    end tell
end arrangeInCascade

-- Arrange windows horizontally (side by side)
on arrangeHorizontally(screenWidth, screenHeight)
    tell application "iTerm2"
        set windowCount to count of windows
        
        set marginX to 20
        set marginY to 50
        set usableWidth to screenWidth - (2 * marginX)
        
        -- Calculate window width with spacing
        set spacingX to 10
        set windowWidth to (usableWidth / windowCount) - spacingX
        set windowHeight to screenHeight - (2 * marginY)
        
        repeat with i from 1 to windowCount
            set winX to marginX + ((i - 1) * (windowWidth + spacingX))
            set winY to marginY
            
            tell window i
                set bounds to {winX, winY, winX + windowWidth, winY + windowHeight}
            end tell
        end repeat
    end tell
end arrangeHorizontally

-- Arrange windows vertically (stacked)
on arrangeVertically(screenWidth, screenHeight)
    tell application "iTerm2"
        set windowCount to count of windows
        
        set marginX to 50
        set marginY to 20
        set usableHeight to screenHeight - (2 * marginY)
        
        -- Calculate window height with spacing
        set spacingY to 10
        set windowHeight to (usableHeight / windowCount) - spacingY
        set windowWidth to screenWidth - (2 * marginX)
        
        repeat with i from 1 to windowCount
            set winX to marginX
            set winY to marginY + ((i - 1) * (windowHeight + spacingY))
            
            tell window i
                set bounds to {winX, winY, winX + windowWidth, winY + windowHeight}
            end tell
        end repeat
    end tell
end arrangeVertically

-- Apply custom window positions
on arrangeCustom(positionsList)
    tell application "iTerm2"
        set windowCount to count of windows
        set positionCount to count of positionsList
        
        -- Apply as many positions as we have windows
        repeat with i from 1 to (min of windowCount and positionCount)
            set positionData to item i of positionsList
            
            -- Extract position data
            set winX to 0
            set winY to 0
            set winWidth to 800
            set winHeight to 600
            
            try
                if positionData contains {x:0} then
                    set winX to x of positionData as integer
                end if
                if positionData contains {y:0} then
                    set winY to y of positionData as integer
                end if
                if positionData contains {width:0} then
                    set winWidth to width of positionData as integer
                end if
                if positionData contains {height:0} then
                    set winHeight to height of positionData as integer
                end if
            on error
                -- Skip invalid position data
                return "Error: Invalid position data for window " & i
            end try
            
            -- Apply the position
            tell window i
                set bounds to {winX, winY, winX + winWidth, winY + winHeight}
            end tell
        end repeat
    end tell
end arrangeCustom

-- Helper function to get screen dimensions
on getScreenDimensions()
    tell application "Finder"
        set screenSize to bounds of window of desktop
        set screenWidth to item 3 of screenSize
        set screenHeight to item 4 of screenSize
    end tell
    return {screenWidth, screenHeight}
end getScreenDimensions

-- Helper function to convert text to lowercase
on toLowerCase(theText)
    return do shell script "echo " & quoted form of theText & " | tr '[:upper:]' '[:lower:]'"
end toLowerCase
```

## Window Arrangements for iTerm2

Organizing your iTerm2 windows can significantly improve your workflow productivity, especially when working with multiple terminal sessions. This script provides several layout options to help you arrange iTerm2 windows efficiently.

### Layout Options

#### 1. Grid Layout

The grid layout organizes windows in a structured matrix pattern:

- Divides the screen into equal cells based on specified rows and columns
- Provides balanced visibility for all windows
- Ideal for comparing output or running related processes

**Example Use Case**: Development environment with API server, database, frontend, and logs windows arranged in a 2×2 grid.

#### 2. Cascade Layout

The cascade layout arranges windows in a staggered pattern:

- Each window is offset slightly from the previous
- Shows window titles and makes each window accessible
- Creates a visual hierarchy

**Example Use Case**: Multiple SSH sessions to different servers where you need to quickly identify and access each connection.

#### 3. Horizontal Layout

The horizontal layout arranges windows side by side across the screen:

- Maximizes horizontal screen space usage
- Perfect for wide or ultrawide monitors
- Good for comparing output between terminal sessions

**Example Use Case**: Running parallel tasks where you need to monitor output simultaneously, such as watching logs while running tests.

#### 4. Vertical Layout

The vertical layout stacks windows from top to bottom:

- Each window gets full screen width
- Good for tall or portrait-oriented screens
- Ideal for reading long command outputs

**Example Use Case**: Monitoring log files or executing commands that produce lengthy vertical output.

#### 5. Custom Layout

The custom layout provides precise control over window positioning:

- Specify exact coordinates and dimensions for each window
- Create asymmetrical layouts for different-priority tasks
- Position windows across multiple monitors

**Example Use Case**: Complex setups where some windows need more screen real estate than others.

### Multi-Monitor Considerations

When working with multiple monitors, the custom layout option is particularly useful:

1. **Spanning Displays**: Position windows across different screens
2. **Monitor-Specific Layouts**: Place specific windows on specific monitors
3. **Mixed-Use Setup**: Arrange windows based on monitor characteristics (size, orientation)

To determine screen coordinates for multi-monitor setups:

```applescript
on getMultiScreenInfo()
    tell application "System Events"
        set screenInfo to {}
        
        repeat with i from 1 to (count of desktops)
            set screenBounds to bounds of desktop i
            set end of screenInfo to {index:i, bounds:screenBounds}
        end repeat
        
        return screenInfo
    end tell
end getMultiScreenInfo
```

### Integration with iTerm2 Features

This window arrangement script works particularly well with other iTerm2 features:

#### Profile Integration

Assign different profiles to windows based on their position in your layout:

```applescript
tell application "iTerm2"
    tell window 1
        set current session to (create tab with profile "Production")
    end tell
    tell window 2
        set current session to (create tab with profile "Development")
    end tell
end tell
```

#### Window Naming

Add descriptive names to windows based on their function in your layout:

```applescript
tell application "iTerm2"
    tell window 1
        set name to "Server Monitor"
    end tell
    tell window 2
        set name to "Database"
    end tell
end tell
```

#### Session Saving

After arranging windows, save the arrangement using iTerm2's built-in functionality:

1. Create the perfect layout using this script
2. Save the window arrangement using the `Save Window Arrangement` command
3. Restore it later when needed

### Example Arrangements

#### Development Grid

```json
{
  "layout": "grid",
  "gridRows": 2,
  "gridColumns": 2
}
```

This creates a 2×2 grid suitable for:
- Top-left: API server
- Top-right: Database console
- Bottom-left: File editing
- Bottom-right: Build/test output

#### DevOps Horizontal Layout

```json
{
  "layout": "horizontal"
}
```

This creates a side-by-side arrangement for:
- Left: Production server monitoring
- Middle: Staging environment
- Right: Deployment scripts

#### Custom Multi-Monitor Setup

```json
{
  "layout": "custom",
  "positions": [
    {"x": 100, "y": 100, "width": 1000, "height": 800},  // Primary monitor
    {"x": 2020, "y": 100, "width": 1000, "height": 400}, // Secondary top
    {"x": 2020, "y": 550, "width": 1000, "height": 400}  // Secondary bottom
  ]
}
```

This creates a three-window setup spanning two monitors with a larger window on the primary display and two smaller windows on the secondary display.

### Advanced Customization

The script can be extended to support:

1. **Preset Layouts**: Create named presets for common tasks
2. **Auto-Execute Commands**: Run specific commands in each window after arrangement
3. **Profile Assignment**: Apply specific profiles based on window position
4. **Session Grouping**: Group windows by project or function

Example extension for auto-executing commands:

```applescript
on arrangeWithCommands(layout, commands)
    -- First arrange the windows using the standard function
    my arrangeInGrid(2, 2, 1440, 900)
    
    -- Then execute the commands in each window
    tell application "iTerm2"
        repeat with i from 1 to (count of commands)
            if i ≤ (count of windows) then
                tell window i
                    tell current session
                        write text (item i of commands)
                    end tell
                end tell
            end if
        end repeat
    end tell
end arrangeWithCommands
```
