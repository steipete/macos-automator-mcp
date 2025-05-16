---
id: install_coding_fonts
title: Install Coding Fonts
description: Installs and configures programming fonts for code editors
language: applescript
author: Claude
usage_examples:
  - "Install JetBrains Mono font for coding"
  - "Set up Fira Code with ligatures in VS Code"
  - "Install multiple programming fonts at once"
parameters:
  - name: fontName
    description: "Name of the font to install (JetBrainsMono, FiraCode, Hack, SourceCodePro, CascadiaCode)"
    required: true
  - name: configureEditors
    description: "Whether to configure common editors to use the font (true/false)"
    required: false
---

# Install Coding Fonts

This script installs popular programming fonts and optionally configures common code editors to use them.

```applescript
on run {input, parameters}
    set fontName to "--MCP_INPUT:fontName"
    set configureEditors to "--MCP_INPUT:configureEditors"
    
    if fontName is "" or fontName is missing value then
        display dialog "Please specify a font to install (JetBrainsMono, FiraCode, Hack, SourceCodePro, or CascadiaCode)." buttons {"OK"} default button "OK" with icon stop
        return
    end if
    
    -- Set defaults if not provided
    if configureEditors is "" or configureEditors is missing value then
        set configureEditors to "true"
    end if
    
    -- Standardize the font name for internal use
    set standardizedName to standardizeFontName(fontName)
    
    -- Check if the font is already installed
    set fontInstalled to checkFontInstalled(standardizedName)
    
    if fontInstalled then
        set message to standardizedName & " is already installed. Do you want to proceed with editor configuration?"
        set userChoice to display dialog message buttons {"Cancel", "Configure Editors"} default button "Configure Editors" with icon note
        if button returned of userChoice is "Cancel" then
            return standardizedName & " is already installed. No changes were made."
        end if
    else
        -- Download and install the font
        set result to downloadAndInstallFont(standardizedName)
        if result begins with "Error" then
            display dialog result buttons {"OK"} default button "OK" with icon stop
            return result
        end if
    end if
    
    -- Configure editors if requested
    if configureEditors is "true" then
        configureEditorsToUseFont(standardizedName)
    end if
    
    return standardizedName & " has been " & (if fontInstalled then "configured" else "installed and configured") & " successfully."
end run

-- Helper function to standardize font name
on standardizeFontName(fontName)
    set lowercaseName to lower of fontName
    
    if lowercaseName contains "jetbrains" or lowercaseName contains "jet" then
        return "JetBrainsMono"
    else if lowercaseName contains "fira" or lowercaseName contains "fire" then
        return "FiraCode"
    else if lowercaseName contains "hack" then
        return "Hack"
    else if lowercaseName contains "source" or lowercaseName contains "code pro" then
        return "SourceCodePro"
    else if lowercaseName contains "cascadia" or lowercaseName contains "cascade" then
        return "CascadiaCode"
    else
        return fontName
    end if
end standardizeFontName

-- Check if font is already installed
on checkFontInstalled(fontName)
    set fontFolderPath to POSIX path of (path to library folder from user domain) & "Fonts/"
    set fontExtensions to {".ttf", ".otf"}
    set fontFound to false
    
    repeat with ext in fontExtensions
        set fontPath to fontFolderPath & fontName & ext
        try
            do shell script "test -f " & quoted form of fontPath
            set fontFound to true
            exit repeat
        on error
            -- Continue checking other extensions
        end try
    end repeat
    
    -- Check in Font Book
    if not fontFound then
        try
            tell application "Font Book"
                if exists font fontName then
                    set fontFound to true
                end if
            end tell
        on error
            -- Font Book couldn't find the font
        end try
    end if
    
    return fontFound
end checkFontInstalled

-- Download and install the font
on downloadAndInstallFont(fontName)
    set tempFolder to do shell script "mktemp -d"
    set zipPath to tempFolder & "/" & fontName & ".zip"
    
    -- Get download URL based on the font
    set downloadURL to getFontDownloadURL(fontName)
    if downloadURL is "not_supported" then
        return "Error: Font " & fontName & " is not supported."
    end if
    
    -- Download the font
    try
        do shell script "curl -sSL " & quoted form of downloadURL & " -o " & quoted form of zipPath
    on error errMsg
        return "Error downloading font: " & errMsg
    end try
    
    -- Extract the font
    try
        do shell script "unzip -q " & quoted form of zipPath & " -d " & quoted form of tempFolder
    on error errMsg
        return "Error extracting font: " & errMsg
    end try
    
    -- Find and install font files
    try
        do shell script "find " & quoted form of tempFolder & " -name \"*.ttf\" -o -name \"*.otf\" | xargs -I{} cp {} " & quoted form of ((POSIX path of (path to library folder from user domain)) & "Fonts/")
    on error errMsg
        return "Error installing font: " & errMsg
    end try
    
    -- Clean up temp folder
    do shell script "rm -rf " & quoted form of tempFolder
    
    return "Successfully installed " & fontName
end downloadAndInstallFont

-- Get download URL based on font name
on getFontDownloadURL(fontName)
    if fontName is "JetBrainsMono" then
        return "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"
    else if fontName is "FiraCode" then
        return "https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip"
    else if fontName is "Hack" then
        return "https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip"
    else if fontName is "SourceCodePro" then
        return "https://github.com/adobe-fonts/source-code-pro/archive/refs/heads/release.zip"
    else if fontName is "CascadiaCode" then
        return "https://github.com/microsoft/cascadia-code/releases/download/v2105.24/CascadiaCode-2105.24.zip"
    else
        return "not_supported"
    end if
end getFontDownloadURL

-- Configure common code editors to use the font
on configureEditorsToUseFont(fontName)
    -- VS Code
    try
        configureVSCode(fontName)
    on error errMsg
        log "Error configuring VS Code: " & errMsg
    end try
    
    -- JetBrains IDEs
    try
        configureJetBrains(fontName)
    on error errMsg
        log "Error configuring JetBrains IDEs: " & errMsg
    end try
    
    -- Xcode (if available)
    try
        configureXcode(fontName)
    on error errMsg
        log "Error configuring Xcode: " & errMsg
    end try
end configureEditorsToUseFont

-- Configure VS Code to use the font
on configureVSCode(fontName)
    set vscodeSettingsPath to POSIX path of (path to home folder) & "Library/Application Support/Code/User/settings.json"
    
    try
        -- Check if settings.json exists
        do shell script "test -f " & quoted form of vscodeSettingsPath
        
        -- Read current settings
        set currentSettings to do shell script "cat " & quoted form of vscodeSettingsPath
        
        -- Prepare settings update with proper JSON format
        if currentSettings contains "editor.fontFamily" then
            -- Update existing font setting
            set updatedSettings to do shell script "echo " & quoted form of currentSettings & " | perl -pe 's/(\"editor\\.fontFamily\"\\s*:\\s*\")[^\"]*(\")/$1" & fontName & ", Menlo, Monaco, \\'Courier New\\', monospace$2/'"
        else
            -- Add new font setting
            if currentSettings ends with "}" then
                -- Add before the last bracket
                set updatedSettings to do shell script "echo " & quoted form of currentSettings & " | perl -0pe 's/}$/,\\n  \"editor.fontFamily\": \"" & fontName & ", Menlo, Monaco, \\'Courier New\\', monospace\"\\n}\\n/'"
            else
                -- Fallback if JSON is malformed
                set updatedSettings to "{" & return & "  \"editor.fontFamily\": \"" & fontName & ", Menlo, Monaco, 'Courier New', monospace\"" & return & "}"
            end if
        end if
        
        -- Add ligatures setting for fonts that support it
        if fontName is in {"JetBrainsMono", "FiraCode", "CascadiaCode"} and not (currentSettings contains "editor.fontLigatures") then
            set updatedSettings to do shell script "echo " & quoted form of updatedSettings & " | perl -0pe 's/}$/,\\n  \"editor.fontLigatures\": true\\n}\\n/'"
        end if
        
        -- Write updated settings
        do shell script "echo " & quoted form of updatedSettings & " > " & quoted form of vscodeSettingsPath
    on error
        -- Create new settings.json if it doesn't exist
        set newSettings to "{" & return & "  \"editor.fontFamily\": \"" & fontName & ", Menlo, Monaco, 'Courier New', monospace\""
        
        if fontName is in {"JetBrainsMono", "FiraCode", "CascadiaCode"} then
            set newSettings to newSettings & "," & return & "  \"editor.fontLigatures\": true"
        end if
        
        set newSettings to newSettings & return & "}"
        
        -- Create directory if it doesn't exist
        do shell script "mkdir -p " & quoted form of (POSIX path of (path to home folder) & "Library/Application Support/Code/User/")
        
        -- Write new settings
        do shell script "echo " & quoted form of newSettings & " > " & quoted form of vscodeSettingsPath
    end try
end configureVSCode

-- Configure JetBrains IDEs to use the font
on configureJetBrains(fontName)
    -- Find JetBrains IDE config directories
    set jetbrainsConfigPath to POSIX path of (path to home folder) & "Library/Application Support/JetBrains"
    
    try
        -- Find all IntelliJ-based product directories
        set ideDirectories to paragraphs of (do shell script "find " & quoted form of jetbrainsConfigPath & " -maxdepth 1 -type d -name \"*20*\" | sort")
        
        repeat with ideDir in ideDirectories
            if ideDir is not "" then
                -- Create options directory if it doesn't exist
                do shell script "mkdir -p " & quoted form of ideDir & "/options"
                
                -- Create or update editor.xml
                set editorXmlPath to ideDir & "/options/editor.xml"
                
                try
                    do shell script "test -f " & quoted form of editorXmlPath
                    
                    -- Update existing font setting
                    do shell script "perl -i -pe 's/(<option name=\"FONT_FAMILY\" value=\")[^\"]*(\")/$1" & fontName & "$2/' " & quoted form of editorXmlPath
                on error
                    -- Create new editor.xml
                    set xmlContent to "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" & return
                    set xmlContent to xmlContent & "<application>" & return
                    set xmlContent to xmlContent & "  <component name=\"EditorSettings\">" & return
                    set xmlContent to xmlContent & "    <option name=\"FONT_FAMILY\" value=\"" & fontName & "\" />" & return
                    
                    if fontName is in {"JetBrainsMono", "FiraCode", "CascadiaCode"} then
                        set xmlContent to xmlContent & "    <option name=\"LIGATURES\" value=\"true\" />" & return
                    end if
                    
                    set xmlContent to xmlContent & "  </component>" & return
                    set xmlContent to xmlContent & "</application>"
                    
                    do shell script "echo " & quoted form of xmlContent & " > " & quoted form of editorXmlPath
                end try
            end if
        end repeat
    on error errMsg
        log "Error finding JetBrains IDEs: " & errMsg
    end try
end configureJetBrains

-- Configure Xcode to use the font if available
on configureXcode(fontName)
    -- Xcode preferences are more complex, and this is a simplified approach
    set xcodePrefsPath to POSIX path of (path to home folder) & "Library/Preferences/com.apple.dt.Xcode.plist"
    
    try
        do shell script "defaults write com.apple.dt.Xcode XCFontAndColorThemesLuminance -dict"
        do shell script "defaults write com.apple.dt.Xcode XCFontAndColorThemesLuminance 'Default (Light)' -dict"
        do shell script "defaults write com.apple.dt.Xcode XCFontAndColorThemesLuminance 'Default (Light)' 'Menlo-Regular' -string " & quoted form of fontName
        do shell script "defaults write com.apple.dt.Xcode XCFontAndColorThemesLuminance 'Default (Dark)' -dict"
        do shell script "defaults write com.apple.dt.Xcode XCFontAndColorThemesLuminance 'Default (Dark)' 'Menlo-Regular' -string " & quoted form of fontName
    on error errMsg
        log "Error configuring Xcode: " & errMsg
    end try
end configureXcode
```

## About Programming Fonts

Specialized programming fonts make code more readable through features like:

1. **Clear distinction** between similar characters (`0` vs `O`, `1` vs `l`, `{` vs `(`)
2. **Consistent monospacing** for better code alignment
3. **Ligatures** that combine multiple characters into single symbols (`=>`, `!=`, `>=`)
4. **Increased x-height** for better readability at small sizes

## Supported Fonts

This script supports five popular programming fonts:

### JetBrains Mono
- Developed by JetBrains specifically for coding
- Features increased height for lowercase letters
- Includes coding-specific ligatures
- [Official website](https://www.jetbrains.com/lp/mono/)

### Fira Code
- Based on Mozilla's Fira Mono
- Known for its extensive ligature support
- Very popular among web developers
- [GitHub repository](https://github.com/tonsky/FiraCode)

### Hack
- Designed for source code
- Focus on clarity without stylistic embellishments
- No ligatures, focusing on character distinction
- [GitHub repository](https://github.com/source-foundry/Hack)

### Source Code Pro
- Adobe's open-source monospaced font
- Clean design with good readability
- Multiple weights from extra-light to black
- [GitHub repository](https://github.com/adobe-fonts/source-code-pro)

### Cascadia Code
- Microsoft's monospaced font
- Used in Windows Terminal and VS Code
- Includes programming ligatures
- [GitHub repository](https://github.com/microsoft/cascadia-code)

## Editor Configuration

The script can automatically configure popular editors to use the installed font:

1. **Visual Studio Code**: Updates `settings.json` with the new font family and enables ligatures
2. **JetBrains IDEs**: Configures `editor.xml` in all installed JetBrains products
3. **Xcode**: Updates font preferences (basic support)

For other editors, you'll need to manually select the font in their settings.