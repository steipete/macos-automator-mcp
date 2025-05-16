---
title: 'JXA: Browser Automation'
category: 03_jxa_core
id: jxa_browser_automation
description: >-
  Examples of automating Safari, Chrome, and other browsers using JXA to control
  tabs, perform web actions, and extract content.
keywords:
  - jxa
  - javascript
  - safari
  - chrome
  - browser automation
  - web scripting
  - tabs
  - url
language: javascript
notes: >-
  Browser scripting capabilities may change with browser updates. Safari offers
  the most reliable automation experience on macOS.
---

# Browser Automation with JXA

JavaScript for Automation (JXA) provides powerful capabilities to automate and control web browsers on macOS. This document provides an overview of browser automation techniques using JXA.

## Available Scripts

The following scripts provide detailed functionality for working with browsers:

1. [Safari Basic Operations](browser/jxa_safari_basic_operations.md) - Control Safari windows, tabs, and navigation
2. [Chrome Operations](browser/jxa_chrome_operations.md) - Control Google Chrome windows and tabs
3. [Safari Content Extraction](browser/jxa_safari_content_extraction.md) - Extract data from web pages using Safari
4. [Multi-browser Tab Management](browser/jxa_multi_browser_tab_management.md) - Work with tabs across multiple browsers

## Prerequisites

For all browser automation scripts, it's important to have the appropriate permissions set up for your script to control browsers. Access to automation must be granted in System Settings → Privacy & Security → Automation.

## General Usage

Each script provides specialized functionality and can be used independently or in combination. Refer to the individual script documentation for detailed usage instructions and examples.

## Compatibility Notes

- Safari offers the most reliable automation experience on macOS
- Chrome's JavaScript execution support via JXA may be limited in some versions
- Browser automation capabilities may change with browser updates