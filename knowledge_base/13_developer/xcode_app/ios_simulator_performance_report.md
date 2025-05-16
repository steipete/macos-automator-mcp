---
title: 'iOS Simulator: Generate Performance Report'
category: 13_developer
id: ios_simulator_performance_report
description: Generates a system performance report for an app running in iOS Simulator.
keywords:
  - iOS Simulator
  - Xcode
  - performance
  - profiling
  - memory
  - CPU
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  App bundle ID as 'bundleID' (required), duration in seconds as
  'durationSeconds' (default 10), and optional device identifier as
  'deviceIdentifier' (defaults to 'booted').
notes: |
  - Captures app performance data in simulator
  - Monitors CPU usage, memory consumption, and more
  - Runs for configurable duration to capture performance over time
  - Produces detailed report with performance metrics
  - Helps identify performance bottlenecks without Instruments
  - Useful for quick performance checks during development
---

```applescript
--MCP_INPUT:bundleID
--MCP_INPUT:durationSeconds
--MCP_INPUT:deviceIdentifier

on generatePerformanceReport(bundleID, durationSeconds, deviceIdentifier)
  if bundleID is missing value or bundleID is "" then
    return "error: Bundle ID not provided. Specify the app's bundle identifier."
  end if
  
  -- Default duration to 10 seconds if not specified
  if durationSeconds is missing value or durationSeconds is "" then
    set durationSeconds to 10
  else
    try
      set durationSeconds to durationSeconds as number
      if durationSeconds < 1 then
        set durationSeconds to 10
      end if
      if durationSeconds > 300 then -- cap at 5 minutes
        set durationSeconds to 300
      end if
    on error
      set durationSeconds to 10
    end try
  end if
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  try
    -- Check if device exists and is booted
    if deviceIdentifier is not "booted" then
      set checkDeviceCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "'"
      try
        do shell script checkDeviceCmd
      on error
        return "error: Device '" & deviceIdentifier & "' not found. Use 'booted' for the currently booted device, or check available devices."
      end try
    end if
    
    -- Check if the app is installed and running
    set checkAppCmd to "xcrun simctl get_app_container " & quoted form of deviceIdentifier & " " & quoted form of bundleID & " 2>/dev/null || echo 'not installed'"
    set appContainer to do shell script checkAppCmd
    
    if appContainer is "not installed" then
      return "error: App with bundle ID '" & bundleID & "' not installed on " & deviceIdentifier & " simulator."
    end if
    
    -- Make sure the app is running
    set isRunning to false
    try
      set pidCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " ps aux | grep " & quoted form of bundleID & " | grep -v grep"
      do shell script pidCmd
      set isRunning to true
    on error
      set isRunning to false
    end try
    
    if not isRunning then
      -- Try to launch the app
      try
        do shell script "xcrun simctl launch " & quoted form of deviceIdentifier & " " & quoted form of bundleID
        set isRunning to true
        delay 2 -- Give app time to fully launch
      on error launchErr
        return "error: Failed to launch app " & bundleID & ". Please launch it manually before running this script. Error: " & launchErr
      end try
    end if
    
    -- Create timestamp for unique log files
    set timeStamp to do shell script "date +%Y%m%d_%H%M%S"
    
    -- Create temp directory for performance data
    set tempDir to "/tmp/sim_perf_" & timeStamp
    do shell script "mkdir -p " & quoted form of tempDir
    
    -- Create script to sample the process at intervals
    set samplingScript to tempDir & "/sample_app.sh"
    
    -- Number of samples to collect (1 per second)
    set sampleCount to durationSeconds
    
    -- Create the sampling script content
    set scriptContent to "#!/bin/bash
BUNDLE_ID=\"" & bundleID & "\"
DEVICE=\"" & deviceIdentifier & "\"
OUTPUT_DIR=\"" & tempDir & "\"
SAMPLE_COUNT=" & sampleCount & "

echo \"Starting performance monitoring for $BUNDLE_ID for " & durationSeconds & " seconds...\"
echo \"Performance data will be saved to: $OUTPUT_DIR\"

# Function to get process stats
get_process_stats() {
    # Get process info using ps
    PROCESS_INFO=$(xcrun simctl spawn $DEVICE ps -o pid,%cpu,%mem,rss,vsz,state,time -p $1 2>/dev/null | tail -n 1)
    echo \"$PROCESS_INFO\"
}

# Get the PID of the app
APP_PID=$(xcrun simctl spawn $DEVICE ps aux | grep \"$BUNDLE_ID\" | grep -v grep | awk '{print $2}' | head -1)

if [ -z \"$APP_PID\" ]; then
    echo \"Error: App $BUNDLE_ID is not running\"
    exit 1
fi

echo \"Monitoring process ID: $APP_PID\"

# Get device information
DEVICE_INFO=$(xcrun simctl list devices | grep -A1 -B1 \"$DEVICE\")
echo \"Device Info:\"
echo \"$DEVICE_INFO\"
echo

# Create CSV header
echo \"Timestamp,CPU %,Memory %,RSS (KB),VSZ (KB),State,Runtime\" > \"$OUTPUT_DIR/performance.csv\"

# Sample the process every second
for ((i=1; i<=$SAMPLE_COUNT; i++)); do
    TIMESTAMP=$(date +\"%Y-%m-%d %H:%M:%S\")
    
    # Get process stats
    STATS=$(get_process_stats $APP_PID)
    
    # If we lost the process, try to find it again
    if [ -z \"$STATS\" ]; then
        APP_PID=$(xcrun simctl spawn $DEVICE ps aux | grep \"$BUNDLE_ID\" | grep -v grep | awk '{print $2}' | head -1)
        if [ -z \"$APP_PID\" ]; then
            echo \"Warning: App process terminated during monitoring at sample $i\"
            break
        fi
        STATS=$(get_process_stats $APP_PID)
    fi
    
    # Extract and format stats
    PID=$(echo \"$STATS\" | awk '{print $1}')
    CPU=$(echo \"$STATS\" | awk '{print $2}')
    MEM=$(echo \"$STATS\" | awk '{print $3}')
    RSS=$(echo \"$STATS\" | awk '{print $4}')
    VSZ=$(echo \"$STATS\" | awk '{print $5}')
    STATE=$(echo \"$STATS\" | awk '{print $6}')
    TIME=$(echo \"$STATS\" | awk '{print $7}')
    
    # Save to CSV
    echo \"$TIMESTAMP,$CPU,$MEM,$RSS,$VSZ,$STATE,$TIME\" >> \"$OUTPUT_DIR/performance.csv\"
    
    # Output progress
    if [ $((i % 5)) -eq 0 ] || [ $i -eq 1 ] || [ $i -eq $SAMPLE_COUNT ]; then
        echo \"Sample $i/$SAMPLE_COUNT: CPU: ${CPU}%, Memory: ${MEM}%, RSS: ${RSS}KB\"
    fi
    
    # Wait for next sample
    if [ $i -lt $SAMPLE_COUNT ]; then
        sleep 1
    fi
done

# Get memory info at the end
MEM_INFO=$(xcrun simctl spawn $DEVICE vmstat)
echo \"\\nMemory Statistics:\"
echo \"$MEM_INFO\"

# Get thread info
THREAD_INFO=$(xcrun simctl spawn $DEVICE ps -M $APP_PID)
echo \"\\nThread Information:\"
echo \"$THREAD_INFO\"

# Get network connections
NETWORK_INFO=$(xcrun simctl spawn $DEVICE netstat -an | grep -i estab)
echo \"\\nNetwork Connections:\"
if [ -z \"$NETWORK_INFO\" ]; then
    echo \"No active network connections detected\"
else
    echo \"$NETWORK_INFO\"
fi

echo \"\\nPerformance monitoring completed\"
echo \"Results saved to $OUTPUT_DIR/performance.csv\"

# Generate a simple performance summary
CPU_AVG=$(awk -F',' 'NR>1 { sum += $2; count++ } END { if (count > 0) print sum/count; else print 0 }' \"$OUTPUT_DIR/performance.csv\")
MEM_AVG=$(awk -F',' 'NR>1 { sum += $3; count++ } END { if (count > 0) print sum/count; else print 0 }' \"$OUTPUT_DIR/performance.csv\")
RSS_MAX=$(awk -F',' 'NR>1 { if ($4 > max) max = $4 } END { print max }' \"$OUTPUT_DIR/performance.csv\")
CPU_MAX=$(awk -F',' 'NR>1 { if ($2 > max) max = $2 } END { print max }' \"$OUTPUT_DIR/performance.csv\")

echo \"\\nPerformance Summary:\"
echo \"----------------------------------\"
echo \"Average CPU Usage: ${CPU_AVG}%\"
echo \"Maximum CPU Usage: ${CPU_MAX}%\"
echo \"Average Memory Usage: ${MEM_AVG}%\"
echo \"Maximum RSS Memory: ${RSS_MAX} KB ($(echo \"scale=2; ${RSS_MAX}/1024\" | bc) MB)\"
echo \"----------------------------------\"

# Create summary file
echo \"Performance Summary for $BUNDLE_ID\" > \"$OUTPUT_DIR/summary.txt\"
echo \"Duration: $SAMPLE_COUNT seconds\" >> \"$OUTPUT_DIR/summary.txt\"
echo \"Device: $DEVICE_INFO\" >> \"$OUTPUT_DIR/summary.txt\"
echo \"\\nMetrics:\" >> \"$OUTPUT_DIR/summary.txt\"
echo \"----------------------------------\" >> \"$OUTPUT_DIR/summary.txt\"
echo \"Average CPU Usage: ${CPU_AVG}%\" >> \"$OUTPUT_DIR/summary.txt\"
echo \"Maximum CPU Usage: ${CPU_MAX}%\" >> \"$OUTPUT_DIR/summary.txt\"
echo \"Average Memory Usage: ${MEM_AVG}%\" >> \"$OUTPUT_DIR/summary.txt\"
echo \"Maximum RSS Memory: ${RSS_MAX} KB ($(echo \"scale=2; ${RSS_MAX}/1024\" | bc) MB)\" >> \"$OUTPUT_DIR/summary.txt\"
echo \"----------------------------------\" >> \"$OUTPUT_DIR/summary.txt\"

exit 0"
    
    -- Write script to file and make executable
    do shell script "echo " & quoted form of scriptContent & " > " & quoted form of samplingScript
    do shell script "chmod +x " & quoted form of samplingScript
    
    -- Run the script in a Terminal window to show progress
    tell application "Terminal"
      do script quoted form of samplingScript & "; echo 'Press Enter to close this window'; read"
      activate
    end tell
    
    return "Started performance monitoring for " & bundleID & " on " & deviceIdentifier & " simulator.

Duration: " & durationSeconds & " seconds
Performance data will be saved to: " & tempDir & "

A Terminal window has opened to show the progress of the monitoring.
When complete, a summary will be displayed and the following files will be available:
- " & tempDir & "/performance.csv - Raw performance data
- " & tempDir & "/summary.txt - Performance summary

You can use this data to identify performance issues like:
- High CPU usage
- Memory leaks (steadily increasing memory usage)
- Excessive resource consumption
- Thread proliferation"
  on error errMsg number errNum
    return "error (" & errNum & ") generating performance report: " & errMsg
  end try
end generatePerformanceReport

return my generatePerformanceReport("--MCP_INPUT:bundleID", "--MCP_INPUT:durationSeconds", "--MCP_INPUT:deviceIdentifier")
```
