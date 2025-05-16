---
title: Mail Automation Script
category: 09_productivity
id: mail_automation_script
description: >-
  Automates various email tasks in Apple Mail including sending, filtering,
  organizing, searching, and template-based responses
keywords:
  - email
  - mail
  - automation
  - templates
  - filter
  - organize
  - search
  - attachment
  - Apple Mail
  - message
language: applescript
notes: >-
  Works with Apple Mail application on macOS. Some operations require Mail to be
  the frontmost application.
---

# Mail Automation Script

This document provides an overview of the Mail Automation Script, which offers comprehensive automation capabilities for Apple Mail on macOS. The script combines powerful email management features with a user-friendly interface to help users handle their email more efficiently.

## Available Components

The Mail Automation Script is divided into several specialized components:

1. [Core Components and Setup](automation/mail_automation_core.md) - Core functionality, initialization, and logging
2. [Email Composition and Sending](automation/mail_email_composition.md) - Creating and sending emails with formatting options
3. [Template System](automation/mail_template_system.md) - Creating and managing reusable email templates
4. [Email Search and Organization](automation/mail_search_organization.md) - Finding and organizing emails with various criteria
5. [User Interface Components](automation/mail_ui_components.md) - Interactive dialog interfaces for the automation system

## Key Features

### Email Composition and Sending
- Create and send emails with full formatting options
- Support for CC and BCC recipients
- File attachments
- Multiple account and signature selection
- Draft management

### Template System
- Create and manage reusable email templates
- Customizable placeholders for personalization
- Save drafts as templates for future use
- Template editing and organization
- Placeholder auto-detection and filling

### Email Search and Organization
- Advanced search with multiple criteria (subject, sender, recipient, content)
- Date-based filtering
- Account and folder specific searches
- Limit search results for performance

### Batch Email Operations
- Move messages between folders
- Mark messages as read/unread
- Archive messages automatically
- Apply operations to search results

### Account and Folder Management
- Support for multiple mail accounts
- Folder navigation and selection
- Signature management
- Cross-account operations

## Prerequisites

The script requires:
- macOS with Apple Mail installed
- Appropriate permissions to control Mail
- For some operations, Mail needs to be the frontmost application

## General Usage

Each component provides specialized functionality and can be used independently or in combination. Refer to the individual component documentation for detailed usage instructions and examples.