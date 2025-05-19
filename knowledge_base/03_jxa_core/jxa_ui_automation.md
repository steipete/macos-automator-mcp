---
title: JXA UI Automation
category: 03_jxa_core
id: jxa_ui_automation
description: >-
  Overview of UI automation capabilities for interacting with macOS applications
  using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - automation
  - ui
  - accessibility
  - systemevents
  - click
  - button
  - interaction
  - form
---

# JXA UI Automation

This document provides an overview of UI automation capabilities using JavaScript for Automation (JXA). The functionality has been split into separate, specialized scripts for better organization and maintainability.

## Available UI Automation Scripts

The following scripts provide detailed functionality for UI automation:

1. [UI Automation Base](ui_automation/jxa_ui_base.md) - Core functionality and parameter handling
2. [Click Element](ui_automation/jxa_ui_click.md) - Clicking UI elements
3. [Get & Set Values](ui_automation/jxa_ui_element_values.md) - Getting and setting values of UI elements
4. [Window Information](ui_automation/jxa_ui_window_info.md) - Getting information about application windows
5. [UI Hierarchy](ui_automation/jxa_ui_hierarchy.md) - Exploring UI element hierarchies
6. [Menu Actions](ui_automation/jxa_ui_menu_actions.md) - Performing menu actions
7. [Wait For Element](ui_automation/jxa_ui_wait_element.md) - Waiting for UI elements to appear
8. [Scroll Element](ui_automation/jxa_ui_scroll.md) - Scrolling UI elements
9. [Drag and Drop](ui_automation/jxa_ui_drag_drop.md) - Performing drag and drop operations
10. [Find UI Element](ui_automation/jxa_ui_find_element.md) - Helper for finding UI elements by various criteria

## General Usage

Each script provides specialized functionality and can be used independently or in combination. Refer to the individual script documentation for detailed usage instructions and examples.

## Accessibility Requirements

Note that UI automation requires appropriate accessibility permissions for your application:

1. Go to System Settings > Privacy & Security > Accessibility
2. Enable your script execution environment (e.g., Script Editor, Terminal)

These scripts integrate deeply with macOS's accessibility features to provide robust UI automation capabilities beyond what traditional AppleScript can offer.