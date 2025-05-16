---
id: jxa_clipboard_rich_text
title: JXA Clipboard Rich Text Operations
description: Working with styled text in the clipboard using JavaScript for Automation
language: javascript
keywords:
  - clipboard
  - rich text
  - rtf
  - styled text
  - formatting
  - bold
  - color
  - font
category: 03_jxa_core
---

# JXA Clipboard Rich Text Operations

This script provides functionality for working with styled (RTF) text in the clipboard using JavaScript for Automation (JXA).

## Prerequisites

First, make sure to include the Standard Additions library and import the necessary Objective-C frameworks:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Use Objective-C bridge
ObjC.import('AppKit');
```

## Set Rich Text to Clipboard

To set styled (RTF) text to the clipboard, you can use NSAttributedString:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Use Objective-C bridge
ObjC.import('AppKit');

// Create a mutable attributed string
const string = $.NSMutableAttributedString.alloc.initWithString('Hello, World!');

// Apply some styling
const range = $.NSMakeRange(0, 5); // Range for "Hello"
const boldFont = $.NSFont.boldSystemFontOfSize(16);
string.addAttributeValueRange($.NSFontAttributeName, boldFont, range);

// Red color for "Hello"
const redColor = $.NSColor.redColor;
string.addAttributeValueRange($.NSForegroundColorAttributeName, redColor, range);

// Set to pasteboard
const pasteboard = $.NSPasteboard.generalPasteboard;
pasteboard.clearContents;
pasteboard.writeObjectsForTypes([string], [$.NSPasteboardTypeRTF]);

console.log("Rich text set to clipboard");
```

## Check for Rich Text in Clipboard

To check if the clipboard contains rich text and read it:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Use Objective-C bridge
ObjC.import('AppKit');

function getRichTextFromClipboard() {
    const pasteboard = $.NSPasteboard.generalPasteboard;
    
    // Check if clipboard contains RTF
    if (pasteboard.dataForType($.NSPasteboardTypeRTF)) {
        // Get the RTF data
        const rtfData = pasteboard.dataForType($.NSPasteboardTypeRTF);
        
        // Create an attributed string from the RTF data
        const attributedString = $.NSAttributedString.alloc.initWithRTF_documentAttributes(
            rtfData, 
            $.NSMutableDictionary.alloc.init
        );
        
        if (attributedString) {
            // Extract the plain text
            const plainText = ObjC.unwrap(attributedString.string);
            console.log(`Rich text found in clipboard: "${plainText}"`);
            
            // Return both the plain text and the attributed string
            return {
                plainText: plainText,
                attributedString: attributedString
            };
        }
    }
    
    console.log("No rich text found in clipboard");
    return null;
}

// Use the function
const richText = getRichTextFromClipboard();
```

## Create Styled Text with Specific Formatting

To create more complex formatted text and set it to the clipboard:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Use Objective-C bridge
ObjC.import('AppKit');

function createStyledText() {
    // Create a mutable attributed string
    const string = $.NSMutableAttributedString.alloc.initWithString('Formatting Example:\n\n');
    
    // Add bold text
    const boldText = $.NSMutableAttributedString.alloc.initWithString('Bold text. ');
    const boldFont = $.NSFont.boldSystemFontOfSize(14);
    boldText.addAttributeValueRange($.NSFontAttributeName, boldFont, $.NSMakeRange(0, boldText.length));
    string.appendAttributedString(boldText);
    
    // Add italic text
    const italicText = $.NSMutableAttributedString.alloc.initWithString('Italic text. ');
    const italicFont = $.NSFont.fontWithName_size('Helvetica-Oblique', 14);
    italicText.addAttributeValueRange($.NSFontAttributeName, italicFont, $.NSMakeRange(0, italicText.length));
    string.appendAttributedString(italicText);
    
    // Add colored text
    const coloredText = $.NSMutableAttributedString.alloc.initWithString('Colored text.');
    const blueColor = $.NSColor.blueColor;
    coloredText.addAttributeValueRange($.NSForegroundColorAttributeName, blueColor, $.NSMakeRange(0, coloredText.length));
    string.appendAttributedString(coloredText);
    
    // Set to pasteboard
    const pasteboard = $.NSPasteboard.generalPasteboard;
    pasteboard.clearContents;
    pasteboard.writeObjectsForTypes([string], [$.NSPasteboardTypeRTF]);
    
    console.log("Styled text set to clipboard");
    return string;
}

// Create and set styled text to clipboard
createStyledText();
```

These examples show various ways to create, modify, and work with styled rich text in the macOS clipboard.