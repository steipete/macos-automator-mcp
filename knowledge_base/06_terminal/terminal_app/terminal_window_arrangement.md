---
title: "Terminal: Window and Tab Arrangement"
id: terminal_window_arrangement
category: "04_terminal_emulators"
description: "Arranges Terminal.app windows and tabs according to predefined layouts or custom specifications."
keywords: ["Terminal.app", "window", "tab", "arrange", "layout", "grid", "cascade", "position", "organize"]
language: applescript
argumentsPrompt: "Expects inputData with: { \"layout\": \"grid\", \"cascade\", \"horizontal\", \"vertical\", or \"custom\", \"positions\": [{\"x\": 0, \"y\": 0, \"width\": 800, \"height\": 600}], \"gridRows\": 2, \"gridColumns\": 2 } (specific parameters depend on selected layout)."
isComplex: true
---

This script arranges Terminal.app windows according to various layout patterns, helping you organize your workspace efficiently. It can arrange existing windows or create new ones in the desired configuration.

**Features:**
- Arrange windows in a grid pattern (rows and columns)
- Cascade windows diagonally across the screen
- Arrange windows horizontally (side by side)
- Arrange windows vertically (stacked)
- Apply custom window positions and sizes
- Works with existing windows or creates new ones as needed

```applescript
on runWithInput(inputData, legacyArguments)
    set defaultLayout to "grid"
    set defaultGridRows to 2
    set defaultGridColumns to 2
    set defaultPositions to {}
    
    -- Parse input parameters
    set theLayout to defaultLayout
    set gridRows to defaultGridRows
    set gridColumns to defaultGridColumns
    set customPositions to defaultPositions
    
    if inputData is not missing value then
        if inputData contains {layout:""} then
            set theLayout to layout of inputData
            --MCP_INPUT:layout
        end if
        
        if inputData contains {gridRows:""} then
            try
                set gridRows to gridRows of inputData as integer
                if gridRows < 1 then set gridRows to 1
                --MCP_INPUT:gridRows
            end try
        end if
        
        if inputData contains {gridColumns:""} then
            try
                set gridColumns to gridColumns of inputData as integer
                if gridColumns < 1 then set gridColumns to 1
                --MCP_INPUT:gridColumns
            end try
        end if
        
        if inputData contains {positions:""} then
            set customPositions to positions of inputData
            --MCP_INPUT:positions
        end if
    end if
    
    -- Convert layout to lowercase
    set theLayout to my toLower(theLayout)
    
    -- Get screen dimensions
    set screenDimensions to getScreenDimensions()
    set screenWidth to item 1 of screenDimensions
    set screenHeight to item 2 of screenDimensions
    
    tell application "Terminal"
        -- Check if Terminal.app is running and has open windows
        set windowCount to count of windows
        
        if windowCount is 0 then
            -- No windows open, ask if we should create new ones
            display dialog "No Terminal windows are open. Create new windows for arrangement?" buttons {"Cancel", "Create"} default button "Create"
            
            -- Create windows based on the layout
            if theLayout is "grid" then
                set windowCount to gridRows * gridColumns
            else if theLayout is "cascade" then
                set windowCount to 4 -- Default cascade count
            else if theLayout is "horizontal" then
                set windowCount to 3 -- Default horizontal count
            else if theLayout is "vertical" then
                set windowCount to 3 -- Default vertical count
            else if theLayout is "custom" then
                if class of customPositions is list then
                    set windowCount to count of customPositions
                else
                    set windowCount to 1
                end if
            end if
            
            -- Create the windows
            repeat windowCount times
                do script ""
                delay 0.3
            end repeat
            
            -- Get the updated window count
            set windowCount to count of windows
        end if
        
        -- Apply the selected layout
        if theLayout is "grid" then
            arrangeInGrid(gridRows, gridColumns, screenWidth, screenHeight)
            return "Arranged " & windowCount & " Terminal windows in a " & gridRows & "×" & gridColumns & " grid."
            
        else if theLayout is "cascade" then
            arrangeInCascade(screenWidth, screenHeight)
            return "Arranged " & windowCount & " Terminal windows in a cascade pattern."
            
        else if theLayout is "horizontal" then
            arrangeHorizontally(screenWidth, screenHeight)
            return "Arranged " & windowCount & " Terminal windows horizontally."
            
        else if theLayout is "vertical" then
            arrangeVertically(screenWidth, screenHeight)
            return "Arranged " & windowCount & " Terminal windows vertically."
            
        else if theLayout is "custom" then
            if class of customPositions is list and (count of customPositions) > 0 then
                arrangeCustom(customPositions)
                return "Applied custom arrangement to Terminal windows."
            else
                return "Error: Custom layout requires valid position specifications."
            end if
            
        else
            return "Error: Invalid layout type. Use 'grid', 'cascade', 'horizontal', 'vertical', or 'custom'."
        end if
    end tell
end runWithInput

-- Arrange windows in a grid
on arrangeInGrid(rows, columns, screenWidth, screenHeight)
    tell application "Terminal"
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
                
                set bounds of window windowIndex to {winX, winY, winX + windowWidth, winY + windowHeight}
                
                set windowIndex to windowIndex + 1
            end repeat
            if windowIndex > windowCount then exit repeat
        end repeat
    end tell
end arrangeInGrid

-- Arrange windows in a cascade pattern
on arrangeInCascade(screenWidth, screenHeight)
    tell application "Terminal"
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
            
            set bounds of window i to {winX, winY, winX + baseWidth, winY + baseHeight}
        end repeat
    end tell
end arrangeInCascade

-- Arrange windows horizontally (side by side)
on arrangeHorizontally(screenWidth, screenHeight)
    tell application "Terminal"
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
            
            set bounds of window i to {winX, winY, winX + windowWidth, winY + windowHeight}
        end repeat
    end tell
end arrangeHorizontally

-- Arrange windows vertically (stacked)
on arrangeVertically(screenWidth, screenHeight)
    tell application "Terminal"
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
            
            set bounds of window i to {winX, winY, winX + windowWidth, winY + windowHeight}
        end repeat
    end tell
end arrangeVertically

-- Apply custom window positions
on arrangeCustom(positionsList)
    tell application "Terminal"
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
            set bounds of window i to {winX, winY, winX + winWidth, winY + winHeight}
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
on toLower(theText)
    set lowercaseText to ""
    repeat with i from 1 to length of theText
        set currentChar to character i of theText
        if ASCII number of currentChar ≥ 65 and ASCII number of currentChar ≤ 90 then
            -- Convert uppercase letter to lowercase
            set lowercaseText to lowercaseText & (ASCII character ((ASCII number of currentChar) + 32))
        else
            -- Keep the character as is
            set lowercaseText to lowercaseText & currentChar
        end if
    end repeat
    return lowercaseText
end toLower
```

## Terminal Window Arrangement

Organizing your terminal windows effectively can significantly improve your productivity, especially when working with multiple sessions simultaneously. This script provides several layout options to help you arrange Terminal.app windows in a way that suits your workflow.

### Arrangement Patterns

#### Grid Layout

The grid layout arranges windows in rows and columns, creating a structured view of multiple terminal sessions:

- Perfect for monitoring multiple systems or processes simultaneously
- Provides equal visibility to all windows
- Customizable number of rows and columns

When to use:
- Server monitoring across multiple systems
- Running and viewing multiple processes side by side
- Comparing output from different commands

#### Cascade Layout

The cascade layout arranges windows in a diagonal pattern, with each window slightly offset from the previous one:

- Shows window titles for all windows simultaneously
- Allows quick access to any window by clicking its visible portion
- Creates a natural visual hierarchy

When to use:
- When you need to switch frequently between several windows
- When window titles are important for identification
- For workflows where one window might be primary but others need to remain accessible

#### Horizontal Layout

The horizontal layout arranges windows side by side across the screen:

- Maximizes horizontal space utilization
- Ideal for wide-screen monitors
- Perfect for comparing output across windows

When to use:
- Code comparison across different files or versions
- Log file monitoring with different log sources
- Command execution with side-by-side results

#### Vertical Layout

The vertical layout stacks windows from top to bottom:

- Works well on taller screens
- Each window gets full width of the screen
- Great for reading long output or logs

When to use:
- Reading through long command outputs
- Working with log files or text-heavy content
- When vertical space is more valuable than horizontal

#### Custom Layout

The custom layout allows precise control over window positions and sizes:

- Specify exact coordinates and dimensions for each window
- Create any arrangement pattern you can imagine
- Accommodate specific workflow requirements

When to use:
- Complex workflows with specific window placement needs
- When you want to save and reuse specific window arrangements
- When standard patterns don't fit your needs

### Working with Multi-Monitor Setups

When working with multiple monitors, you can use custom layouts to distribute windows across screens:

1. Determine the coordinates of your screens using System Information
2. Create custom positions that span your monitor setup
3. Apply the custom layout to spread windows across all available screens

For example, to span two side-by-side monitors:

```json
{
  "layout": "custom",
  "positions": [
    {"x": 50, "y": 50, "width": 800, "height": 600},
    {"x": 1970, "y": 50, "width": 800, "height": 600}
  ]
}
```

### Integration with Other Scripts

This window arrangement script works well in combination with other Terminal management scripts:

1. **Session Management**: Arrange windows, then save the arrangement for later restoration
2. **Title Management**: Set window titles based on their position in the arrangement
3. **Split Pane Management**: Arrange windows first, then create split panes within them

### Example Use Cases

#### Development Environment

```json
{
  "layout": "grid",
  "gridRows": 2,
  "gridColumns": 2
}
```

Create a 2×2 grid with:
- Top-left: Code editing
- Top-right: Server/application output
- Bottom-left: Git commands
- Bottom-right: Build/test output

#### System Monitoring

```json
{
  "layout": "horizontal"
}
```

Create side-by-side windows for:
- CPU/memory monitoring (htop)
- Network traffic
- Disk I/O
- Log file tailing

#### Custom Workspace

```json
{
  "layout": "custom",
  "positions": [
    {"x": 0, "y": 0, "width": 1200, "height": 800},
    {"x": 1220, "y": 0, "width": 700, "height": 400},
    {"x": 1220, "y": 420, "width": 700, "height": 400}
  ]
}
```

Create a primary window on the left and two smaller windows stacked on the right.