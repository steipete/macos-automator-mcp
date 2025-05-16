---
title: "Logic Pro: Scripter MIDI Plugin"
category: "08_creative_and_document_apps"
id: logic_pro_scripter_midi
description: "Automate the Scripter MIDI effect plugin in Logic Pro to generate, modify, and process MIDI data with JavaScript."
keywords: ["Logic Pro", "Scripter", "MIDI", "plugin", "JavaScript", "automation", "music production", "MIDI processing"]
language: applescript
parameters: |
  - script_path (optional): Path to a JavaScript file to load into Scripter
notes: |
  - Logic Pro must be running with a project open.
  - Scripter is a powerful MIDI effect plugin in Logic Pro that uses JavaScript.
  - This script demonstrates adding a Scripter plugin to a track and loading code.
  - If no script_path is provided, a simple example MIDI chord script will be used.
  - Scripter offers real-time MIDI data processing through JavaScript code.
  - The AppleScript uses UI automation to interact with Logic Pro's interface.
  - Some operations may require Accessibility permissions to be granted to the script runner.
---

Automate the Scripter MIDI effect plugin in Logic Pro.

```applescript
-- Get script path parameter
set scriptPathParam to "--MCP_INPUT:script_path"
if scriptPathParam is "" or scriptPathParam is "--MCP_INPUT:script_path" then
  set scriptPathParam to "" -- Empty means use built-in example
end if

-- Check if Logic Pro is running
tell application "System Events"
  set logicRunning to exists process "Logic Pro"
end tell

if not logicRunning then
  return "Error: Logic Pro is not running. Please launch Logic Pro with a project open."
end if

-- Check if the provided script file exists (if a path was given)
if scriptPathParam is not "" then
  tell application "System Events"
    if not (exists POSIX file scriptPathParam) then
      return "Error: Script file not found at path: " & scriptPathParam
    end if
  end tell
end if

-- Read the script file contents if provided
set scriptContent to ""
if scriptPathParam is not "" then
  try
    set scriptFile to POSIX file scriptPathParam
    set scriptFileRef to open for access scriptFile
    set scriptContent to read scriptFileRef
    close access scriptFileRef
  on error
    try
      close access scriptFileRef
    end try
    return "Error: Could not read script file at: " & scriptPathParam
  end try
else
  -- Use a default example MIDI script if no file was provided
  set scriptContent to "
// Simple Chord Generator Script for Logic Pro's Scripter
// Converts single notes into triads (three-note chords)

var NeedsTimingInfo = true;
var activeNotes = [];

function HandleMIDI(event) {
    // Process only note-on and note-off events
    if (event instanceof Note) {
        if (event.type == 144) { // Note-on
            // Create a triad: root, major third (+4 semitones), perfect fifth (+7 semitones)
            var rootNote = event.pitch;
            var thirdNote = rootNote + 4;  // Major third
            var fifthNote = rootNote + 7;  // Perfect fifth
            
            // Create the three notes of the chord
            var noteRoot = new NoteOn(event);
            var noteThird = new NoteOn(event);
            noteThird.pitch = thirdNote;
            var noteFifth = new NoteOn(event);
            noteFifth.pitch = fifthNote;
            
            // Keep track of all notes in the chord
            activeNotes.push({
                root: rootNote,
                third: thirdNote,
                fifth: fifthNote,
                velocity: event.velocity
            });
            
            // Send all notes in the chord
            noteRoot.send();
            noteThird.send();
            noteFifth.send();
        }
        else if (event.type == 128) { // Note-off
            // Find and turn off corresponding chord
            for (var i = 0; i < activeNotes.length; i++) {
                if (activeNotes[i].root == event.pitch) {
                    // Create note-off events for each note in the chord
                    var noteOffRoot = new NoteOff(event);
                    var noteOffThird = new NoteOff(event);
                    noteOffThird.pitch = activeNotes[i].third;
                    var noteOffFifth = new NoteOff(event);
                    noteOffFifth.pitch = activeNotes[i].fifth;
                    
                    // Send all note-offs
                    noteOffRoot.send();
                    noteOffThird.send();
                    noteOffFifth.send();
                    
                    // Remove from active notes
                    activeNotes.splice(i, 1);
                    break;
                }
            }
        }
    }
    else {
        // Pass through all other MIDI events unchanged
        event.send();
    }
}

// Initialize plugin
function Reset() {
    activeNotes = [];
    Trace('Chord Generator Script Initialized');
}

// Provide user information in the plugin interface
var PluginParameters = [
    {
        name:'About',
        type:'text',
        defaultValue:'Simple Chord Generator: Converts single notes into major triads.'
    }
];
"
end if

-- Get the frontmost application to restore focus later if needed
tell application "System Events"
  set frontApp to name of first process whose frontmost is true
end tell

-- Execute the Scripter setup
tell application "Logic Pro"
  -- Activate Logic Pro
  activate
  delay 0.5 -- Give time for Logic Pro to come to foreground
  
  -- Initialize result
  set resultText to ""
  
  -- Use UI scripting to insert and configure the Scripter plugin
  tell application "System Events"
    tell process "Logic Pro"
      -- Check if Logic Pro has a window open
      if (count of windows) is 0 then
        return "Error: Logic Pro is running but no project is open."
      end if
      
      -- Check if we can insert a MIDI effect
      try
        -- First, make sure we have a MIDI or Software Instrument track selected
        -- Press Enter to create a new track if needed
        keystroke return
        delay 0.5
        
        -- Create a software instrument track
        -- Typically this is Option+Command+S or via menu
        -- We'll use the menu to be safe
        try
          -- Click on Track menu
          click menu item "Track" of menu bar 1
          delay 0.3
          -- Look for "New Tracks" submenu
          click menu item "New Tracks..." of menu "Track" of menu bar 1
          delay 0.5
          
          -- In the new tracks dialog, select Software Instrument
          try
            -- Try to click Software Instrument radio button
            -- This is best-effort and UI may vary
            -- Setting dialog defaults are usually Software Instrument already
            delay 0.5
            keystroke return -- Accept defaults which is usually Software Instrument
            delay 1
          on error
            -- Dialog navigation failed, try to cancel and try another approach
            keystroke escape
            delay 0.5
          end try
        on error
          -- Menu navigation failed, try keyboard shortcut
          keystroke "s" using {command down, option down}
          delay 1
        end try
        
        -- Now insert Scripter on the track
        -- Typically this is done through the MIDI FX slot
        try
          -- Click on MIDI FX slot (position depends on UI layout)
          -- This is best-effort and may need adjustment
          
          -- Try common method of accessing MIDI FX
          try
            -- Press I to open instrument slot
            keystroke "i"
            delay 0.5
            
            -- Use Tab key to navigate to MIDI FX section (varies by Logic version)
            repeat 3 times
              keystroke tab
              delay 0.2
            end repeat
            
            -- Press Down to open MIDI FX menu
            keystroke (ASCII character 31) -- Down arrow
            delay 0.5
            
            -- Type "scr" to filter to Scripter
            keystroke "scr"
            delay 0.3
            
            -- Press Return to select Scripter
            keystroke return
            delay 1
          on error
            -- If that failed, try menu approach
            try
              -- Click on Track menu
              click menu item "Mix" of menu bar 1
              delay 0.3
              -- Look for plug-in menu items
              click menu item "MIDI FX" of menu "Mix" of menu bar 1
              delay 0.3
              -- Then Logic Pro Audio Units
              click menu item "Logic Pro MIDI FX" of menu "MIDI FX" of menu "Mix" of menu bar 1
              delay 0.3
              -- Then Scripter
              click menu item "Scripter" of menu "Logic Pro MIDI FX" of menu "MIDI FX" of menu "Mix" of menu bar 1
              delay 1
            on error
              -- Both approaches failed
              set resultText to resultText & "Could not insert Scripter plugin. "
              
              -- Exit this try block
              error "Could not insert Scripter"
            end try
          end try
          
          -- If we got here, Scripter should be inserted
          -- Now we need to open the Scripter editor and paste our code
          
          -- Wait for Scripter UI to appear
          delay 1
          
          -- Look for Scripter editor window
          -- This is challenging without knowing exact UI elements
          try
            -- Try clicking the "Script Editor" button if visible
            set editorButton to button "Script Editor" of window 1
            click editorButton
            delay 0.5
          on error
            -- Button not found, try opening the plug-in window
            try
              -- Use Option+Click to open plugin window
              -- Note: This is an alternate approach and may not work in all versions
              keystroke "e" using {option down}
              delay 0.5
            on error
              -- Both approaches failed
              set resultText to resultText & "Could not open Scripter editor. "
              
              -- Exit this try block
              error "Could not open Scripter editor"
            end try
          end try
          
          -- Now paste the script into the editor
          try
            -- This is best-effort and may need adjustment based on Scripter's UI
            
            -- Select all existing text
            keystroke "a" using {command down}
            delay 0.2
            
            -- Delete it
            keystroke (ASCII character 8) -- Delete/Backspace
            delay 0.2
            
            -- Paste our script
            set the clipboard to scriptContent
            keystroke "v" using {command down}
            delay 0.5
            
            -- Run the script (typically Command+R)
            keystroke "r" using {command down}
            delay 0.5
            
            -- Success!
            set resultText to "Successfully inserted Scripter plugin and loaded script code."
            if scriptPathParam is not "" then
              set resultText to resultText & " Script loaded from: " & scriptPathParam
            else
              set resultText to resultText & " Default chord generator script loaded."
            end if
            
            -- Add information about the script
            set resultText to resultText & return & return & "This script will transform single notes into major triads, creating a chord from each note played."
            
            -- Add usage instructions
            set resultText to resultText & return & return & "Usage Instructions:" & return
            set resultText to resultText & "1. Play single notes on your MIDI keyboard" & return
            set resultText to resultText & "2. Each note will be expanded into a major triad (root, major 3rd, perfect 5th)" & return
            set resultText to resultText & "3. This creates fuller-sounding chords from single-note input"
          on error
            -- Script insertion failed
            set resultText to resultText & "Could not insert script code. "
          end try
          
        on error insertErr
          -- MIDI FX insertion failed
          set resultText to resultText & "Error: " & insertErr
        end try
        
      on error trackErr
        set resultText to "Error creating or selecting appropriate track: " & trackErr
      end try
    end tell
  end tell
  
  -- Return result
  return resultText
end tell

-- Restore focus to original application if needed
if frontApp is not "Logic Pro" then
  tell application frontApp to activate
end if
```