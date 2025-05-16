---
id: things_review_automation
title: Automated Review System for Things
description: Script to automate daily and weekly reviews in Things
author: steipete
language: applescript
tags: things, productivity, task management, review, gtd, automation
keywords: [gtd, daily-review, weekly-review, productivity-report, task-cleanup]
version: 1.0.0
updated: 2024-05-16
---

# Automated Review System for Things

This script implements an automated review system for Things, following GTD (Getting Things Done) principles, to help maintain organization and focus.

## Example Usage

```applescript
-- Run daily review
runDailyReview()

-- Run weekly review
runWeeklyReview()

-- Generate productivity report
generateProductivityReport("2024-05-01", "2024-05-15")

-- Clean up completed tasks
cleanupCompletedTasks(30)
```

## Script Details

This script automates the review process in Things to ensure consistent task management.

```applescript
-- Automated review system for Things

-- Run daily review
on runDailyReview()
    tell application "Things3"
        -- First, check if there's already a daily review to-do for today
        set todayDate to current date
        set todayString to short date string of todayDate
        
        set reviewToDos to to dos of list "Today" where name contains "Daily Review"
        if (count of reviewToDos) > 0 then
            set existingReview to item 1 of reviewToDos
            if status of existingReview is not completed then
                -- Update existing review
                set notes of existingReview to generateDailyReviewNotes()
                return "Updated existing daily review for " & todayString
            end if
        end if
        
        -- Create new daily review to-do
        set reviewProperties to {name:"Daily Review - " & todayString, notes:generateDailyReviewNotes(), tags:{"Review"}}
        set newReview to make new to do with properties reviewProperties
        
        -- Move to Today list
        set list of newReview to list "Today"
        
        -- Return summary
        return "Created daily review for " & todayString
    end tell
end runDailyReview

-- Generate notes for daily review
on generateDailyReviewNotes()
    tell application "Things3"
        set reviewNotes to "# Daily Review
Generated: " & (current date as string) & "

## Today's Tasks
"
        -- List today's tasks
        set todayToDos to to dos of list "Today" where name does not contain "Daily Review"
        set todayCount to count of todayToDos
        
        -- Count completions
        set completedCount to 0
        repeat with t in todayToDos
            if status of t is completed then
                set completedCount to completedCount + 1
            end if
        end repeat
        
        set reviewNotes to reviewNotes & "- Total: " & todayCount & " tasks
- Completed: " & completedCount & " tasks
- Remaining: " & (todayCount - completedCount) & " tasks

## Tasks Requiring Attention
"
        
        -- Find overdue tasks
        set overdueToDos to to dos where due date < current date and status is open
        set overdueCount to count of overdueToDos
        
        if overdueCount > 0 then
            set reviewNotes to reviewNotes & "### Overdue Tasks (" & overdueCount & ")
"
            repeat with t in overdueToDos
                set taskName to name of t
                set taskDue to due date of t as string
                set taskProject to "none"
                
                if project of t is not missing value then
                    set taskProject to name of project of t
                end if
                
                set reviewNotes to reviewNotes & "- " & taskName & " (Due: " & taskDue & ", Project: " & taskProject & ")
"
            end repeat
        else
            set reviewNotes to reviewNotes & "### Overdue Tasks
None! 🎉
"
        end if
        
        -- Find tasks in inbox
        set inboxToDos to to dos of list "Inbox"
        set inboxCount to count of inboxToDos
        
        set reviewNotes to reviewNotes & "
### Inbox Items (" & inboxCount & ")
" & (if inboxCount > 5 then "Consider processing these items!" else "")
        
        if inboxCount > 0 then
            set maxToShow to 5
            set shownCount to 0
            
            repeat with t in inboxToDos
                if shownCount < maxToShow then
                    set reviewNotes to reviewNotes & "- " & name of t & "
"
                    set shownCount to shownCount + 1
                end if
            end repeat
            
            if inboxCount > maxToShow then
                set reviewNotes to reviewNotes & "- ...and " & (inboxCount - maxToShow) & " more items
"
            end if
        end if
        
        -- Add review checklist
        set reviewNotes to reviewNotes & "
## Daily Review Checklist
- [ ] Review completed tasks and celebrate progress
- [ ] Process inbox items
- [ ] Review today's remaining tasks
- [ ] Adjust priorities if needed
- [ ] Check calendar for tomorrow's events
- [ ] Plan tomorrow's tasks

## Notes
"
        
        return reviewNotes
    end tell
end generateDailyReviewNotes

-- Run weekly review
on runWeeklyReview()
    tell application "Things3"
        -- Determine the week number and year
        set currentDate to current date
        set weekOfYear to week of currentDate
        set yearNumber to year of currentDate
        
        -- Check if there's already a weekly review for this week
        set reviewToDos to to dos where name contains "Weekly Review - Week " & weekOfYear
        if (count of reviewToDos) > 0 then
            set existingReview to item 1 of reviewToDos
            if status of existingReview is not completed then
                -- Update existing review
                set notes of existingReview to generateWeeklyReviewNotes(weekOfYear, yearNumber)
                return "Updated existing weekly review for Week " & weekOfYear
            end if
        end if
        
        -- Create new weekly review to-do
        set reviewProperties to {name:"Weekly Review - Week " & weekOfYear & " (" & yearNumber & ")", notes:generateWeeklyReviewNotes(weekOfYear, yearNumber), tags:{"Review", "Weekly"}}
        set newReview to make new to do with properties reviewProperties
        
        -- Set to weekend
        set theDate to current date
        -- Set to upcoming Friday
        repeat while weekday of theDate is not Friday
            set theDate to theDate + days
        end repeat
        set list of newReview to list "Anytime"
        set due date of newReview to theDate
        
        -- Return summary
        return "Created weekly review for Week " & weekOfYear
    end tell
end runWeeklyReview

-- Generate notes for weekly review
on generateWeeklyReviewNotes(weekNumber, yearNumber)
    tell application "Things3"
        set reviewNotes to "# Weekly Review - Week " & weekNumber & " (" & yearNumber & ")
Generated: " & (current date as string) & "

## Project Status Overview
"
        -- Get all projects
        set allProjects to projects
        set activeProjects to 0
        set completedProjects to 0
        
        -- Track project status
        repeat with p in allProjects
            if status of p is open then
                set activeProjects to activeProjects + 1
            else if status of p is completed then
                set completedProjects to completedProjects + 1
            end if
        end repeat
        
        set reviewNotes to reviewNotes & "- Active Projects: " & activeProjects & "
- Completed Projects: " & completedProjects & "

### Active Projects
"
        
        -- List active projects with task counts
        repeat with p in allProjects
            if status of p is open then
                set projectName to name of p
                set projectToDos to to dos of p
                set totalTasks to count of projectToDos
                set completedTasks to 0
                
                repeat with t in projectToDos
                    if status of t is completed then
                        set completedTasks to completedTasks + 1
                    end if
                end repeat
                
                set progress to 0
                if totalTasks > 0 then
                    set progress to (completedTasks / totalTasks) * 100
                end if
                
                set reviewNotes to reviewNotes & "- " & projectName & " (" & round progress & "% complete, " & completedTasks & "/" & totalTasks & " tasks)
"
            end if
        end repeat
        
        -- Upcoming tasks
        set reviewNotes to reviewNotes & "
## Upcoming Deadlines
"
        
        -- Get date for next two weeks
        set twoWeeksFromNow to current date
        set day of twoWeeksFromNow to day of twoWeeksFromNow + 14
        
        -- Find tasks due in the next two weeks
        set upcomingToDos to to dos where due date ≤ twoWeeksFromNow and due date ≥ current date and status is open
        
        if (count of upcomingToDos) > 0 then
            -- Sort by due date
            set sortedToDos to {}
            repeat with t in upcomingToDos
                set end of sortedToDos to {theToDo:t, dueDate:due date of t}
            end repeat
            
            -- Simple bubble sort by due date
            set n to count of sortedToDos
            repeat with i from 1 to n - 1
                repeat with j from 1 to n - i
                    if dueDate of item j of sortedToDos > dueDate of item (j + 1) of sortedToDos then
                        set temp to item j of sortedToDos
                        set item j of sortedToDos to item (j + 1) of sortedToDos
                        set item (j + 1) of sortedToDos to temp
                    end if
                end repeat
            end repeat
            
            -- List sorted tasks
            repeat with taskInfo in sortedToDos
                set t to theToDo of taskInfo
                set taskName to name of t
                set taskDue to due date of t as string
                set taskProject to "none"
                
                if project of t is not missing value then
                    set taskProject to name of project of t
                end if
                
                set reviewNotes to reviewNotes & "- " & taskName & " (Due: " & taskDue & ", Project: " & taskProject & ")
"
            end repeat
        else
            set reviewNotes to reviewNotes & "No upcoming deadlines in the next two weeks.
"
        end if
        
        -- Stuck projects
        set reviewNotes to reviewNotes & "
## Stalled Projects
"
        
        set stalledCount to 0
        
        repeat with p in allProjects
            if status of p is open then
                set projectToDos to to dos of p
                set hasOpenTasks to false
                
                repeat with t in projectToDos
                    if status of t is open then
                        set hasOpenTasks to true
                        exit repeat
                    end if
                end repeat
                
                if not hasOpenTasks and (count of projectToDos) > 0 then
                    set stalledCount to stalledCount + 1
                    set reviewNotes to reviewNotes & "- " & name of p & " (No active to-dos)
"
                end if
            end if
        end repeat
        
        if stalledCount is 0 then
            set reviewNotes to reviewNotes & "No stalled projects found.
"
        end if
        
        -- Add review checklist
        set reviewNotes to reviewNotes & "
## Weekly Review Checklist
- [ ] Process all inbox items
- [ ] Review upcoming calendar events
- [ ] Review all projects for next actions
- [ ] Review 'Someday/Maybe' list
- [ ] Update project statuses and deadlines
- [ ] Archive completed projects
- [ ] Set goals for next week
- [ ] Clear mind of any open loops

## Reflections
### What went well this week?

### What could have gone better?

### What to focus on next week?

"
        
        return reviewNotes
    end tell
end generateWeeklyReviewNotes

-- Generate productivity report
on generateProductivityReport(startDateStr, endDateStr)
    tell application "Things3"
        -- Parse dates
        set startDate to date startDateStr
        set endDate to date endDateStr
        
        -- Prepare report
        set reportNotes to "# Productivity Report
Period: " & startDateStr & " to " & endDateStr & "
Generated: " & (current date as string) & "

## Task Completion Summary
"
        
        -- Find completed tasks in date range
        set completedToDos to completed to dos where completion date ≥ startDate and completion date ≤ endDate
        set completedCount to count of completedToDos
        
        -- Group by day
        set dateMap to {}
        repeat with t in completedToDos
            set completionDate to short date string of (completion date of t)
            
            -- Check if date exists in map
            set dateExists to false
            set dateIndex to 0
            repeat with i from 1 to count of dateMap
                if item 1 of item i of dateMap is completionDate then
                    set dateExists to true
                    set dateIndex to i
                    exit repeat
                end if
            end repeat
            
            if dateExists then
                -- Increment count for this date
                set item 2 of item dateIndex of dateMap to (item 2 of item dateIndex of dateMap) + 1
            else
                -- Add new date entry
                set end of dateMap to {completionDate, 1}
            end if
        end repeat
        
        -- Sort dates
        set sortedDates to {}
        repeat with dateEntry in dateMap
            set end of sortedDates to dateEntry
        end repeat
        
        -- Simple bubble sort by date
        set n to count of sortedDates
        repeat with i from 1 to n - 1
            repeat with j from 1 to n - i
                if item 1 of item j of sortedDates > item 1 of item (j + 1) of sortedDates then
                    set temp to item j of sortedDates
                    set item j of sortedDates to item (j + 1) of sortedDates
                    set item (j + 1) of sortedDates to temp
                end if
            end repeat
        end repeat
        
        -- Add total completion count
        set reportNotes to reportNotes & "Total tasks completed: " & completedCount & "

## Daily Breakdown
"
        
        -- Graph and list daily completions
        set maxCompletions to 0
        repeat with dateEntry in sortedDates
            set count to item 2 of dateEntry
            if count > maxCompletions then
                set maxCompletions to count
            end if
        end repeat
        
        repeat with dateEntry in sortedDates
            set dateStr to item 1 of dateEntry
            set count to item 2 of dateEntry
            
            -- Create simple bar graph
            set graphWidth to 20
            set barWidth to 0
            if maxCompletions > 0 then
                set barWidth to round ((count / maxCompletions) * graphWidth)
            end if
            
            set bar to ""
            repeat with i from 1 to barWidth
                set bar to bar & "█"
            end repeat
            
            set reportNotes to reportNotes & dateStr & ": " & count & " " & bar & "
"
        end repeat
        
        -- Project breakdown
        set reportNotes to reportNotes & "
## Project Breakdown
"
        
        -- Count completions by project
        set projectMap to {}
        repeat with t in completedToDos
            if project of t is not missing value then
                set projectName to name of project of t
                
                -- Check if project exists in map
                set projectExists to false
                set projectIndex to 0
                repeat with i from 1 to count of projectMap
                    if item 1 of item i of projectMap is projectName then
                        set projectExists to true
                        set projectIndex to i
                        exit repeat
                    end if
                end repeat
                
                if projectExists then
                    -- Increment count for this project
                    set item 2 of item projectIndex of projectMap to (item 2 of item projectIndex of projectMap) + 1
                else
                    -- Add new project entry
                    set end of projectMap to {projectName, 1}
                end if
            else
                -- No project (standalone task)
                set projectExists to false
                set projectIndex to 0
                repeat with i from 1 to count of projectMap
                    if item 1 of item i of projectMap is "No Project" then
                        set projectExists to true
                        set projectIndex to i
                        exit repeat
                    end if
                end repeat
                
                if projectExists then
                    -- Increment count for No Project
                    set item 2 of item projectIndex of projectMap to (item 2 of item projectIndex of projectMap) + 1
                else
                    -- Add new No Project entry
                    set end of projectMap to {"No Project", 1}
                end if
            end if
        end repeat
        
        -- Sort projects by completion count (descending)
        set sortedProjects to {}
        repeat with projectEntry in projectMap
            set end of sortedProjects to projectEntry
        end repeat
        
        -- Simple bubble sort by count
        set n to count of sortedProjects
        repeat with i from 1 to n - 1
            repeat with j from 1 to n - i
                if item 2 of item j of sortedProjects < item 2 of item (j + 1) of sortedProjects then
                    set temp to item j of sortedProjects
                    set item j of sortedProjects to item (j + 1) of sortedProjects
                    set item (j + 1) of sortedProjects to temp
                end if
            end repeat
        end repeat
        
        -- List projects and counts
        repeat with projectEntry in sortedProjects
            set projectName to item 1 of projectEntry
            set count to item 2 of projectEntry
            set percentage to round ((count / completedCount) * 100)
            
            set reportNotes to reportNotes & "- " & projectName & ": " & count & " tasks (" & percentage & "%)
"
        end repeat
        
        -- Tag analysis
        set reportNotes to reportNotes & "
## Tag Analysis
"
        
        -- Count completions by tag
        set tagMap to {}
        repeat with t in completedToDos
            if (count of tags of t) > 0 then
                repeat with aTag in tags of t
                    set tagName to name of aTag
                    
                    -- Check if tag exists in map
                    set tagExists to false
                    set tagIndex to 0
                    repeat with i from 1 to count of tagMap
                        if item 1 of item i of tagMap is tagName then
                            set tagExists to true
                            set tagIndex to i
                            exit repeat
                        end if
                    end repeat
                    
                    if tagExists then
                        -- Increment count for this tag
                        set item 2 of item tagIndex of tagMap to (item 2 of item tagIndex of tagMap) + 1
                    else
                        -- Add new tag entry
                        set end of tagMap to {tagName, 1}
                    end if
                end repeat
            else
                -- No tags
                set tagExists to false
                set tagIndex to 0
                repeat with i from 1 to count of tagMap
                    if item 1 of item i of tagMap is "Untagged" then
                        set tagExists to true
                        set tagIndex to i
                        exit repeat
                    end if
                end repeat
                
                if tagExists then
                    -- Increment count for Untagged
                    set item 2 of item tagIndex of tagMap to (item 2 of item tagIndex of tagMap) + 1
                else
                    -- Add new Untagged entry
                    set end of tagMap to {"Untagged", 1}
                end if
            end if
        end repeat
        
        -- Sort tags by count
        set sortedTags to {}
        repeat with tagEntry in tagMap
            set end of sortedTags to tagEntry
        end repeat
        
        -- Simple bubble sort by count
        set n to count of sortedTags
        repeat with i from 1 to n - 1
            repeat with j from 1 to n - i
                if item 2 of item j of sortedTags < item 2 of item (j + 1) of sortedTags then
                    set temp to item j of sortedTags
                    set item j of sortedTags to item (j + 1) of sortedTags
                    set item (j + 1) of sortedTags to temp
                end if
            end repeat
        end repeat
        
        -- List top tags
        set maxTagsToShow to 10
        set tagsToShow to min of maxTagsToShow and (count of sortedTags)
        
        repeat with i from 1 to tagsToShow
            set tagEntry to item i of sortedTags
            set tagName to item 1 of tagEntry
            set count to item 2 of tagEntry
            set percentage to round ((count / completedCount) * 100)
            
            set reportNotes to reportNotes & "- " & tagName & ": " & count & " tasks (" & percentage & "%)
"
        end repeat
        
        if (count of sortedTags) > maxTagsToShow then
            set reportNotes to reportNotes & "- ... and " & ((count of sortedTags) - maxTagsToShow) & " more tags
"
        end if
        
        -- Create to-do with the report
        set reportTitle to "Productivity Report: " & startDateStr & " to " & endDateStr
        set reportProperties to {name:reportTitle, notes:reportNotes, tags:{"Report", "Productivity"}}
        set reportToDo to make new to do with properties reportProperties
        
        return reportNotes
    end tell
end generateProductivityReport

-- Clean up completed tasks
on cleanupCompletedTasks(daysToKeep)
    tell application "Things3"
        -- Calculate cutoff date
        set cutoffDate to current date
        set day of cutoffDate to day of cutoffDate - daysToKeep
        
        -- Find old completed tasks
        set oldTasks to completed to dos where completion date < cutoffDate
        set taskCount to count of oldTasks
        
        -- Prepare list of tasks to archive
        set taskNames to {}
        repeat with t in oldTasks
            set end of taskNames to name of t
        end repeat
        
        -- Create archive note
        set archiveNotes to "# Tasks Archived on " & (current date as string) & "
"
        repeat with taskName in taskNames
            set archiveNotes to archiveNotes & "- " & taskName & "
"
        end repeat
        
        -- Create archive note in logbook
        if taskCount > 0 then
            set archiveTitle to "Archived " & taskCount & " tasks older than " & daysToKeep & " days"
            set archiveProperties to {name:archiveTitle, notes:archiveNotes, status:completed, tags:{"Archive"}}
            make new to do with properties archiveProperties
            
            -- Clean up tasks (actually delete)
            repeat with t in oldTasks
                delete t
            end repeat
            
            return "Archived " & taskCount & " tasks completed before " & (cutoffDate as string)
        else
            return "No tasks found to archive"
        end if
    end tell
end cleanupCompletedTasks

-- Example call based on which function to run
on run argv
    set functionName to item 1 of argv
    
    if functionName is "daily-review" then
        return runDailyReview()
    else if functionName is "weekly-review" then
        return runWeeklyReview()
    else if functionName is "report" then
        return generateProductivityReport(item 2 of argv, item 3 of argv)
    else if functionName is "cleanup" then
        return cleanupCompletedTasks(item 2 of argv as number)
    else
        return "Error: Unknown function. Use 'daily-review', 'weekly-review', 'report', or 'cleanup'."
    end if
end run
```

## Notes

- Things 3 must be installed on the system.
- This script automates the review process in Things following GTD principles.
- Functions:
  - `runDailyReview`: Creates or updates a daily review to-do with task summaries
  - `runWeeklyReview`: Creates or updates a weekly review to-do with project status
  - `generateProductivityReport`: Creates a detailed report of completed tasks with graphs
  - `cleanupCompletedTasks`: Archives old completed tasks to reduce clutter
- The daily review includes:
  - Summary of today's tasks and completion status
  - List of overdue tasks
  - Inbox item summary
  - Review checklist
- The weekly review includes:
  - Project status overview with progress percentages
  - Upcoming deadlines
  - Stalled projects (projects with no active to-dos)
  - Weekly review checklist
  - Reflection prompts
- The productivity report includes:
  - Daily breakdown with simple bar graphs
  - Project completion analysis
  - Tag analysis
- This script helps maintain an organized system and provides insights into productivity patterns.
- Consider scheduling these reviews to run automatically using macOS's Calendar app or Automator.