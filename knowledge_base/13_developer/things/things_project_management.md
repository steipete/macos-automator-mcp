---
id: things_project_management
title: Advanced Project Management with Things
description: Script for managing complex projects in Things with milestones and tracking
author: steipete
language: applescript
tags: 'things, productivity, task management, project management, milestones'
keywords:
  - milestones
  - templates
  - tracking
  - progress
  - reports
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer
---

# Advanced Project Management with Things

This advanced script provides project management capabilities for Things, including milestone tracking, progress reporting, and automated task generation.

## Example Usage

```applescript
-- Create a new managed project with milestones
createManagedProject("Website Redesign", "Redesign company website", "2024-08-15", "Work")

-- Add milestones and tasks to a project
addMilestoneToProject("Website Redesign", "Design Phase", "2024-06-01")
addTaskToMilestone("Website Redesign", "Design Phase", "Create wireframes", "2024-05-25")

-- Generate project report
generateProjectReport("Website Redesign")

-- Create a project from template
createProjectFromTemplate("Marketing Campaign", "Marketing", "2024-07-01")
```

## Script Details

This script extends Things with advanced project management capabilities.

```applescript
-- Advanced project management for Things

-- Create a new managed project with milestones
on createManagedProject(projectName, projectNotes, dueDate, areaName)
    tell application "Things3"
        -- Create the project
        set projectProperties to {name:projectName}
        
        -- Add notes
        if projectNotes is not equal to "" then
            set projectProperties to projectProperties & {notes:projectNotes}
        end if
        
        -- Add due date
        if dueDate is not equal to "" then
            set projectProperties to projectProperties & {due date:date dueDate}
        end if
        
        -- Add to area
        if areaName is not equal to "" then
            set projectProperties to projectProperties & {area:areaName}
        end if
        
        -- Add special tags for our managed projects
        set projectProperties to projectProperties & {tags:{"Managed Project", "PM-Script"}}
        
        -- Create the project
        set newProject to make new project with properties projectProperties
        
        -- Add metadata to project notes to track milestones
        set metadataNote to "Project Metadata:
----------
Created: " & (current date) & "
Status: Active
Progress: 0%
Milestones: 0
Tasks: 0
----------
"
        
        set notes of newProject to metadataNote & return & notes of newProject
        
        -- Create project headings for organization
        make new heading at end of newProject with properties {name:"Overview"}
        make new heading at end of newProject with properties {name:"Milestones"}
        make new heading at end of newProject with properties {name:"Resources"}
        
        -- Create a project kickoff to-do
        make new to do at end of newProject with properties {name:"Project Kickoff", tags:{"First Step"}}
        
        return "Created managed project: " & projectName
    end tell
end createManagedProject

-- Add a milestone to a project
on addMilestoneToProject(projectName, milestoneName, milestoneDate)
    tell application "Things3"
        -- Find the project
        set theProjects to projects where name is projectName and tag names contains "Managed Project"
        
        if (count of theProjects) is 0 then
            return "Error: Project not found or not a managed project"
        end if
        
        set theProject to item 1 of theProjects
        
        -- Find the Milestones heading
        set milestoneHeadings to headings of theProject where name is "Milestones"
        if (count of milestoneHeadings) is 0 then
            -- Create the heading if it doesn't exist
            make new heading at end of theProject with properties {name:"Milestones"}
            set milestoneHeadings to headings of theProject where name is "Milestones"
        end if
        
        set milestoneHeading to item 1 of milestoneHeadings
        
        -- Create the milestone to-do
        set milestoneProperties to {name:milestoneName, tags:{"Milestone"}}
        
        -- Add due date if provided
        if milestoneDate is not equal to "" then
            set milestoneProperties to milestoneProperties & {due date:date milestoneDate}
        end if
        
        -- Create the milestone
        make new to do at end of milestoneHeading with properties milestoneProperties
        
        -- Update milestone count in metadata
        set projectNotes to notes of theProject
        set milestoneCountPattern to "Milestones: ([0-9]+)"
        
        set AppleScript's text item delimiters to "Milestones: "
        set notesParts to text items of projectNotes
        
        if (count of notesParts) > 1 then
            set beforePart to item 1 of notesParts
            set afterPart to text items 2 through end of notesParts
            set afterText to afterPart as text
            
            set AppleScript's text item delimiters to return
            set afterLines to text items of afterText
            set currentCount to item 1 of afterLines
            set currentCount to currentCount as number
            set newCount to currentCount + 1
            
            set item 1 of afterLines to newCount as string
            set afterText to afterLines as text
            
            set notes of theProject to beforePart & "Milestones: " & afterText
        end if
        
        return "Added milestone '" & milestoneName & "' to project '" & projectName & "'"
    end tell
end addMilestoneToProject

-- Add a task to a milestone
on addTaskToMilestone(projectName, milestoneName, taskName, taskDueDate)
    tell application "Things3"
        -- Find the project
        set theProjects to projects where name is projectName and tag names contains "Managed Project"
        
        if (count of theProjects) is 0 then
            return "Error: Project not found or not a managed project"
        end if
        
        set theProject to item 1 of theProjects
        
        -- Find the milestone
        set milestones to to dos of theProject where name is milestoneName and tag names contains "Milestone"
        
        if (count of milestones) is 0 then
            return "Error: Milestone not found"
        end if
        
        set theMilestone to item 1 of milestones
        
        -- Create the task
        set taskProperties to {name:taskName, project:theProject}
        
        -- Add due date if provided
        if taskDueDate is not equal to "" then
            set taskProperties to taskProperties & {due date:date taskDueDate}
        end if
        
        -- Create the task
        set newTask to make new to do with properties taskProperties
        
        -- Update task count in metadata
        set projectNotes to notes of theProject
        
        set AppleScript's text item delimiters to "Tasks: "
        set notesParts to text items of projectNotes
        
        if (count of notesParts) > 1 then
            set beforePart to item 1 of notesParts
            set afterPart to text items 2 through end of notesParts
            set afterText to afterPart as text
            
            set AppleScript's text item delimiters to return
            set afterLines to text items of afterText
            set currentCount to item 1 of afterLines
            set currentCount to currentCount as number
            set newCount to currentCount + 1
            
            set item 1 of afterLines to newCount as string
            set afterText to afterLines as text
            
            set notes of theProject to beforePart & "Tasks: " & afterText
        end if
        
        return "Added task '" & taskName & "' to milestone '" & milestoneName & "'"
    end tell
end addTaskToMilestone

-- Generate project report
on generateProjectReport(projectName)
    tell application "Things3"
        -- Find the project
        set theProjects to projects where name is projectName and tag names contains "Managed Project"
        
        if (count of theProjects) is 0 then
            return "Error: Project not found or not a managed project"
        end if
        
        set theProject to item 1 of theProjects
        
        -- Calculate project statistics
        set allToDos to to dos of theProject
        set totalTasks to count of allToDos
        set completedTasks to 0
        set overdueTasks to 0
        set milestoneToDos to to dos of theProject where tag names contains "Milestone"
        set totalMilestones to count of milestoneToDos
        set completedMilestones to 0
        
        -- Count completed tasks and milestones
        repeat with t in allToDos
            if status of t is completed then
                set completedTasks to completedTasks + 1
                
                if tag names of t contains "Milestone" then
                    set completedMilestones to completedMilestones + 1
                end if
            end if
            
            -- Check for overdue tasks
            if status of t is open and due date of t is not missing value then
                if due date of t < current date then
                    set overdueTasks to overdueTasks + 1
                end if
            end if
        end repeat
        
        -- Calculate progress percentages
        set taskProgress to 0
        if totalTasks > 0 then
            set taskProgress to (completedTasks / totalTasks) * 100
        end if
        
        set milestoneProgress to 0
        if totalMilestones > 0 then
            set milestoneProgress to (completedMilestones / totalMilestones) * 100
        end if
        
        -- Generate report text
        set reportText to "Project Report: " & projectName & "
====================
Generated: " & (current date) & "

Project Status Summary:
- Overall Progress: " & round taskProgress & "%
- Milestone Progress: " & round milestoneProgress & "%
- Total Tasks: " & totalTasks
        
        if totalTasks > 0 then
            set reportText to reportText & " (" & completedTasks & " completed, " & (totalTasks - completedTasks) & " remaining)"
        end if
        
        set reportText to reportText & "
- Total Milestones: " & totalMilestones
        
        if totalMilestones > 0 then
            set reportText to reportText & " (" & completedMilestones & " completed, " & (totalMilestones - completedMilestones) & " remaining)"
        end if
        
        set reportText to reportText & "
- Overdue Tasks: " & overdueTasks
        
        -- Add milestone details
        set reportText to reportText & "

Milestone Details:
------------------"
        
        repeat with m in milestoneToDos
            set milestoneName to name of m
            set milestoneStatus to "Pending"
            if status of m is completed then
                set milestoneStatus to "Completed"
            end if
            
            set milestoneDue to "No due date"
            if due date of m is not missing value then
                set milestoneDue to due date of m as string
            end if
            
            set reportText to reportText & "
* " & milestoneName & " (" & milestoneStatus & ") - Due: " & milestoneDue
        end repeat
        
        -- Update project metadata
        set projectNotes to notes of theProject
        
        set AppleScript's text item delimiters to "Progress: "
        set notesParts to text items of projectNotes
        
        if (count of notesParts) > 1 then
            set beforePart to item 1 of notesParts
            set afterPart to text items 2 through end of notesParts
            set afterText to afterPart as text
            
            set AppleScript's text item delimiters to "%"
            set progressParts to text items of afterText
            set afterProgress to text items 2 through end of progressParts
            set afterProgressText to afterProgress as text
            
            set newProgressText to round taskProgress as string
            
            set notes of theProject to beforePart & "Progress: " & newProgressText & "%" & afterProgressText
        end if
        
        return reportText
    end tell
end generateProjectReport

-- Create a project from template
on createProjectFromTemplate(projectName, templateName, startDate)
    tell application "Things3"
        -- Check if template exists
        set templates to projects where name is templateName and tag names contains "Template"
        
        if (count of templates) is 0 then
            return "Error: Template '" & templateName & "' not found"
        end if
        
        set templateProject to item 1 of templates
        
        -- Create new project based on template name
        set newProject to make new project with properties {name:projectName}
        
        -- Copy template tasks
        set templateToDos to to dos of templateProject
        set templateHeadings to headings of templateProject
        
        -- Add headings first
        repeat with h in templateHeadings
            set headingName to name of h
            make new heading at end of newProject with properties {name:headingName}
        end repeat
        
        -- Add tasks
        repeat with t in templateToDos
            -- Get task properties
            set taskName to name of t
            set taskNotes to notes of t
            set taskTags to tags of t
            
            -- Calculate dates based on template offsets
            set taskOffset to 0
            if taskNotes contains "OFFSET:" then
                try
                    set AppleScript's text item delimiters to "OFFSET:"
                    set offsetParts to text items of taskNotes
                    set offsetText to item 2 of offsetParts
                    set AppleScript's text item delimiters to return
                    set offsetLine to item 1 of text items of offsetText
                    set taskOffset to offsetLine as number
                end try
            end if
            
            -- Create the task in the new project
            set taskProperties to {name:taskName, notes:taskNotes, project:newProject}
            
            -- Add due date if template has offset
            if startDate is not equal to "" and taskOffset > 0 then
                set taskDueDate to date startDate
                set day of taskDueDate to day of taskDueDate + taskOffset
                set taskProperties to taskProperties & {due date:taskDueDate}
            end if
            
            -- Add tags
            if (count of taskTags) > 0 then
                set taskTagNames to {}
                repeat with aTag in taskTags
                    set end of taskTagNames to name of aTag
                end repeat
                set taskProperties to taskProperties & {tags:taskTagNames}
            end if
            
            -- Create the task
            make new to do with properties taskProperties
        end repeat
        
        return "Created project '" & projectName & "' from template '" & templateName & "'"
    end tell
end createProjectFromTemplate

-- Example call based on which function to run
on run argv
    set functionName to item 1 of argv
    
    if functionName is "create-project" then
        return createManagedProject(item 2 of argv, item 3 of argv, item 4 of argv, item 5 of argv)
    else if functionName is "add-milestone" then
        return addMilestoneToProject(item 2 of argv, item 3 of argv, item 4 of argv)
    else if functionName is "add-task" then
        return addTaskToMilestone(item 2 of argv, item 3 of argv, item 4 of argv, item 5 of argv)
    else if functionName is "report" then
        return generateProjectReport(item 2 of argv)
    else if functionName is "from-template" then
        return createProjectFromTemplate(item 2 of argv, item 3 of argv, item 4 of argv)
    else
        return "Error: Unknown function. Use 'create-project', 'add-milestone', 'add-task', 'report', or 'from-template'."
    end if
end run
```

## Notes

- Things 3 must be installed on the system.
- This script extends Things with project management capabilities not natively available.
- Functions:
  - `createManagedProject`: Creates a structured project with metadata and organization
  - `addMilestoneToProject`: Adds a milestone (key deliverable) to a project
  - `addTaskToMilestone`: Adds tasks associated with specific milestones
  - `generateProjectReport`: Creates a detailed report of project progress
  - `createProjectFromTemplate`: Uses template projects to create new projects with consistent structure
- Project metadata is stored in the project notes and updated automatically.
- Special tags are used to identify managed projects, milestones, and templates.
- The script tracks progress percentages, completion status, and overdue tasks.
- Template projects can include offset values (in days) to automatically calculate due dates for tasks.
- This is useful for managing complex projects with multiple milestones and dependencies.
- For production use, consider adding error handling for edge cases.
