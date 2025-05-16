---
title: Weather App
description: AppleScripts for interacting with weather data and services
order: 1
---

# Weather App Scripts

These scripts provide methods to access weather data on macOS. macOS Ventura introduced a native Weather app, but it doesn't offer direct AppleScript support. These scripts use a weather API service to provide weather information for any location.

## Available Scripts

- **Get Current Weather Conditions**: Retrieve current weather conditions for a specific location
- **Get Weather Forecast**: Get a multi-day weather forecast for a specific location

## Required Setup

These scripts require an API key from [WeatherAPI.com](https://www.weatherapi.com/). You'll need to:

1. Register for a free account at WeatherAPI.com
2. Obtain an API key
3. Replace `YOUR_API_KEY` in the scripts with your actual API key

## Usage Notes

1. The scripts use macOS built-in tools (`curl`, `plutil`, etc.) to avoid external dependencies.
2. Temperature units can be specified as Celsius (default) or Fahrenheit.
3. For better security in production use, consider storing the API key in macOS Keychain instead of hardcoding it in the script.
4. The scripts include helper functions for URL encoding and JSON parsing.

## Script Return Values

The scripts return human-readable text with the requested weather information. You can modify the scripts to return JSON, property lists, or other formats if needed for specific automation workflows.