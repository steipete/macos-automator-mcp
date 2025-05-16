---
title: System Backup Script
category: 05_files
id: system_backup_script
description: >-
  Creates customizable backups of important files and folders with scheduling,
  compression, encryption, and retention options
keywords:
  - backup
  - rsync
  - archive
  - incremental
  - compression
  - encryption
  - schedule
  - restoration
language: applescript
notes: >-
  Some operations require administrator privileges. Uses rsync for efficient
  incremental backups and optionally supports encrypted disk images.
---

# System Backup Script

This document provides an overview of the System Backup Script, which offers comprehensive backup capabilities for files and folders on macOS. The script combines powerful backup features with a user-friendly interface to help users protect their important data.

## Available Components

The System Backup Script is divided into several specialized components:

1. [Core Components](system_backup/backup_core.md) - Core functionality, initialization, and logging
2. [Backup Engine](system_backup/backup_engine.md) - Main backup and restoration functionality
3. [Scheduler](system_backup/backup_scheduler.md) - Scheduling and automation features
4. [Cleanup and Retention](system_backup/backup_cleanup.md) - Managing backup sets and retention policies
5. [User Interface](system_backup/backup_ui.md) - Interactive dialogs for backup configuration and control

## Key Features

### Customizable Backup Options
- Multiple source folders
- Configurable backup destination
- Incremental backup for speed
- Compression for space efficiency
- Optional encryption for security
- Retention policy for managing backup history

### Efficient Backup Engine
- Uses `rsync` for fast, efficient file copying
- Only transfers changed files when using incremental mode
- Includes pattern-based exclusions for temporary files
- Detailed logging of all operations

### Restore Functionality
- Restores from any saved backup set
- Handles encrypted backups with password protection
- Preserves file attributes and permissions

### Schedule Management
- Sets up scheduled backups using macOS launchd
- Supports daily, weekly, or monthly schedules
- Easy removal of scheduled tasks

### User Interface
- Interactive menu for all backup operations
- Guided configuration wizard
- Backup history viewer
- Progress and status reporting

## Prerequisites

The script requires:
- macOS with `rsync` installed (included in macOS by default)
- For encrypted backups: disk utility functionality
- For scheduled backups: launchd system (included in macOS)
- Some operations may require administrator privileges

## General Usage

Each component provides specialized functionality and can be used independently or in combination. Refer to the individual component documentation for detailed usage instructions and examples.