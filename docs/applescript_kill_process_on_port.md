# AppleScript: Kill Process on Port

This document shows how to find and terminate a process that is listening on a specific network port using AppleScript. This is particularly useful for developers who need to free up ports being used by stalled or stuck processes.

## Basic Usage

```applescript
-- Script to find and kill a process on a specific port
on killProcessOnPort(targetPort)
  try
    -- Find the process ID for the port
    set lsofCommand to "lsof -nP -iTCP:" & targetPort & " -sTCP:LISTEN | awk 'NR==2 {print $2}'"
    set processIDString to do shell script lsofCommand
    
    if processIDString is "" then
      return "No process found listening on port " & targetPort & "."
    else
      set processID to processIDString as integer
      try
        do shell script "kill " & processID
        return "Sent kill signal to process " & processID & " on port " & targetPort & "."
      on error
        -- Try with sudo if regular kill fails
        do shell script "sudo kill " & processID with administrator privileges
        return "Sent kill signal (with sudo) to process " & processID & " on port " & targetPort & "."
      end try
    end if
  on error errorMsg
    return "Error: " & errorMsg
  end try
end killProcessOnPort

-- Usage example:
killProcessOnPort(8080)
```

## How It Works

1. The script uses `do shell script` to execute the Unix `lsof` command to find processes listening on the specified port
2. It then extracts the process ID (PID) from the `lsof` output
3. The process is terminated using the Unix `kill` command
4. If the standard kill fails (possibly due to permissions), it attempts to use sudo with administrator privileges

## Common Use Cases

- Freeing up ports used by development servers that didn't terminate properly
- Stopping web servers or API servers running on specific ports
- Troubleshooting network services that are occupying needed ports
- Automating the cleanup of stuck processes in development workflows

## Notes and Limitations

- The script uses SIGTERM by default. For a more forceful termination, you can modify to use `kill -9`
- Administrator privileges may be required if the process belongs to another user or to root
- Use with caution, as it terminates processes without any warning or save operations
- The script assumes standard `lsof` output format; variations in output could affect functionality