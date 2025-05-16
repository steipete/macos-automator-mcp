---
title: 'Image Events: Get Image Dimensions'
category: 10_creative/image_events_app
id: image_events_get_dimensions
description: >-
  Uses Image Events to open an image and retrieve its width and height in
  pixels.
keywords:
  - Image Events
  - image
  - dimensions
  - size
  - width
  - height
  - metadata
language: applescript
isComplex: true
argumentsPrompt: Absolute POSIX path to the image file as 'imagePath' in inputData.
---

```applescript
--MCP_INPUT:imagePath

on getImageDimensions(posixImagePath)
  if posixImagePath is missing value or posixImagePath is "" then return "error: Image path not provided."
  
  try
    set imageFile to POSIX file posixImagePath as alias
    
    tell application "Image Events"
      launch -- Make sure it's running (usually launches silently)
      try
        set img to open imageFile
        set {imgWidth, imgHeight} to dimensions of img
        close img
        return "{width:" & imgWidth & ", height:" & imgHeight & "}" -- Return as a string resembling a record
      on error errMsgImg
        return "error: Image Events could not process file '" & posixImagePath & "': " & errMsgImg
      end try
    end tell
  on error fileErr
    return "error: File not found or invalid path '" & posixImagePath & "': " & fileErr
  end try
end getImageDimensions

return my getImageDimensions("--MCP_INPUT:imagePath")
``` 
