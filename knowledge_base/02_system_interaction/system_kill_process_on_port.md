---
title: "System Interaction: Kill Process Listening on a Specific Port"
category: "02_system_interaction"
id: system_kill_process_on_port
description: "Finds and terminates a process that is listening on a specified network port. Useful for stopping web servers or other network services."
keywords: ["kill", "process", "port", "network", "lsof", "terminate", "developer"]
language: applescript
isComplex: true
argumentsPrompt: "Provide the port number as 'portNumber' in inputData (e.g., { \"portNumber\": 8080 })."
notes: |
  - This script uses `do shell script` with `lsof` and `kill`. It may require administrator privileges if the target process is owned by another user or root.
  - `kill` sends SIGTERM by default. For a more forceful kill, change `kill ` to `kill -9 `.
  - Use with caution, as it abruptly terminates processes.
---

This script identifies and attempts to kill a process by the TCP port it's listening on.

```applescript
--MCP_INPUT:portNumber

on killProcessOnPort(targetPort)
  if targetPort is missing value or targetPort is "" then
    return "error: Port number not provided."
  end if
  
  try
    -- Get PID of process listening on the port. -iTCP ensures only TCP, -sTCP:LISTEN ensures it's a listening socket.
    -- awk 'NR==2 {print $2}' assumes the second line of lsof output has the PID in the second column. This might need adjustment.
    set lsofCommand to "lsof -nP -iTCP:" & targetPort & " -sTCP:LISTEN | awk 'NR==2 {print $2}'"
    set processIDString to do shell script lsofCommand
    
    if processIDString is "" then
      return "No process found listening on port " & targetPort & "."
    else
      set processID to processIDString as integer
      try
        do shell script "kill " & processID -- Default SIGTERM
        return "Sent kill signal to process " & processID & " on port " & targetPort & "."
      on error killErrMsg
        -- Attempt with sudo if initial kill fails and we suspect permission issues
        try
          do shell script "sudo kill " & processID with administrator privileges
          return "Sent kill signal (with sudo) to process " & processID & " on port " & targetPort & "."
        on error sudoKillErrMsg
          return "Found process " & processID & " on port " & targetPort & ", but failed to kill (even with sudo): " & sudoKillErrMsg
        end try
      end try
    end if
  on error lsofErrMsg
    if lsofErrMsg contains "No such file or directory" or lsofErrMsg = "" then
      return "No process found listening on port " & targetPort & " (lsof found nothing)."
    else
      return "Error finding process on port " & targetPort & ": " & lsofErrMsg
    end if
  end try
end killProcessOnPort

-- This script is designed to be run by ID with inputData.
-- For direct execution or testing in Script Editor, you would call:
-- my killProcessOnPort(8080) -- where 8080 is the port number
return my killProcessOnPort(--MCP_INPUT:portNumber)

```
END_TIP