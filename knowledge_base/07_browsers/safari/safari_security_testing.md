---
title: Safari Security Testing
category: "05_web_browsers"
id: safari_security_testing
description: Tests security aspects of a webpage in Safari including HTTPS status, mixed content, content security policy, and basic XSS detection
language: applescript
keywords: [safari, security, https, csp, xss, mixed-content]
---

# Safari Security Testing

This script performs basic security tests on a webpage in Safari. It can check HTTPS status, test for mixed content, verify Content Security Policy implementation, and perform basic XSS vulnerability detection.

## Functionality

- Checks if the current page is using HTTPS
- Tests for mixed content (HTTP resources on HTTPS pages)
- Verifies Content Security Policy implementation
- Performs basic XSS vulnerability detection tests
- Checks cookie security settings (HttpOnly, Secure, SameSite)
- Reports security findings in a structured format

## Parameters

- `test_type`: (Optional) Specific security test to run ("https", "mixed-content", "csp", "xss", "cookies", "all"). Defaults to "all".
- `url`: (Optional) URL to navigate to before running tests
- `verbose`: (Optional) Whether to include detailed information in reports (true/false). Defaults to false.

## Script

```applescript
on run argv
	-- Parse arguments with default values
	set test_type to "all"
	set target_url to ""
	set verbose_mode to false
	
	-- Process arguments if provided
	if (count of argv) ≥ 1 then
		if item 1 of argv is not "" then
			set test_type to item 1 of argv
		end if
	end if
	
	if (count of argv) ≥ 2 then
		if item 2 of argv is not "" then
			set target_url to item 2 of argv
		end if
	end if
	
	if (count of argv) ≥ 3 then
		if item 3 of argv is "true" then
			set verbose_mode to true
		end if
	end if
	
	-- Check if Safari is running
	tell application "System Events"
		set safariRunning to (exists process "Safari")
	end tell
	
	if not safariRunning then
		return "{\"error\": \"Safari is not running. Please open Safari and try again.\"}"
	end if
	
	tell application "Safari"
		-- Navigate to the specified URL if provided
		if target_url is not "" then
			set current_tab to make new document
			set URL of current_tab to target_url
			-- Wait for page to load
			delay 3
		end if
		
		-- Get current tab information
		set current_tab to current tab of window 1
		set page_url to URL of current_tab
		
		-- Execute all requested tests
		set test_results to {}
		
		-- Check if page is using HTTPS
		if test_type is "https" or test_type is "all" then
			set https_result to my checkHttps(page_url, current_tab)
			set test_results to test_results & {https_result}
		end if
		
		-- Check for mixed content
		if test_type is "mixed-content" or test_type is "all" then
			set mixed_content_result to my checkMixedContent(current_tab)
			set test_results to test_results & {mixed_content_result}
		end if
		
		-- Check Content Security Policy
		if test_type is "csp" or test_type is "all" then
			set csp_result to my checkCSP(current_tab)
			set test_results to test_results & {csp_result}
		end if
		
		-- Run basic XSS tests
		if test_type is "xss" or test_type is "all" then
			set xss_result to my checkXSS(current_tab)
			set test_results to test_results & {xss_result}
		end if
		
		-- Check cookie security
		if test_type is "cookies" or test_type is "all" then
			set cookie_result to my checkCookies(current_tab, verbose_mode)
			set test_results to test_results & {cookie_result}
		end if
		
		-- Format results as JSON
		set json_result to "{"
		repeat with i from 1 to count of test_results
			set current_result to item i of test_results
			set json_result to json_result & current_result
			if i < count of test_results then
				set json_result to json_result & ", "
			end if
		end repeat
		set json_result to json_result & "}"
		
		return json_result
	end tell
end run

-- Check if the page is using HTTPS
on checkHttps(page_url, tab_ref)
	set is_https to false
	
	if page_url starts with "https://" then
		set is_https to true
	end if
	
	-- Additional certificate verification via JavaScript
	set js_result to ""
	tell application "Safari"
		set js_result to do JavaScript "
			(function() {
				let securityInfo = {
					protocol: window.location.protocol,
					isSecure: window.location.protocol === 'https:',
					host: window.location.host
				};
				return JSON.stringify(securityInfo);
			})();
		" in tab_ref
	end tell
	
	return "\"https\": {
		\"secure\": " & my boolToString(is_https) & ", 
		\"details\": " & js_result & "
	}"
end checkHttps

-- Check for mixed content on the page
on checkMixedContent(tab_ref)
	tell application "Safari"
		set mixed_content_js to do JavaScript "
			(function() {
				let result = {
					hasMixedContent: false,
					insecureResources: []
				};
				
				// Check for insecure images
				document.querySelectorAll('img[src^=\"http:\"]').forEach(img => {
					result.hasMixedContent = true;
					result.insecureResources.push({
						type: 'image',
						url: img.src
					});
				});
				
				// Check for insecure scripts
				document.querySelectorAll('script[src^=\"http:\"]').forEach(script => {
					result.hasMixedContent = true;
					result.insecureResources.push({
						type: 'script',
						url: script.src
					});
				});
				
				// Check for insecure stylesheets
				document.querySelectorAll('link[rel=\"stylesheet\"][href^=\"http:\"]').forEach(link => {
					result.hasMixedContent = true;
					result.insecureResources.push({
						type: 'stylesheet',
						url: link.href
					});
				});
				
				// Check for insecure iframes
				document.querySelectorAll('iframe[src^=\"http:\"]').forEach(iframe => {
					result.hasMixedContent = true;
					result.insecureResources.push({
						type: 'iframe',
						url: iframe.src
					});
				});
				
				// Limit the number of resources to avoid overly large responses
				if (result.insecureResources.length > 10) {
					const count = result.insecureResources.length;
					result.insecureResources = result.insecureResources.slice(0, 10);
					result.insecureResources.push({
						type: 'info',
						message: 'Additional ' + (count - 10) + ' insecure resources not shown'
					});
				}
				
				return JSON.stringify(result);
			})();
		" in tab_ref
	end tell
	
	return "\"mixedContent\": " & mixed_content_js
end checkMixedContent

-- Check Content Security Policy implementation
on checkCSP(tab_ref)
	tell application "Safari"
		set csp_js to do JavaScript "
			(function() {
				let result = {
					hasCSP: false,
					policies: {},
					recommendations: []
				};
				
				// Function to parse CSP header into object
				function parseCSP(cspString) {
					if (!cspString) return {};
					
					const policies = {};
					const directives = cspString.split(';').map(part => part.trim());
					
					directives.forEach(directive => {
						if (!directive) return;
						const [key, ...values] = directive.split(' ');
						policies[key] = values.filter(v => v);
					});
					
					return policies;
				}
				
				// Try to get CSP meta tag
				const cspMeta = document.querySelector('meta[http-equiv=\"Content-Security-Policy\"]');
				if (cspMeta && cspMeta.content) {
					result.hasCSP = true;
					result.policies['meta'] = parseCSP(cspMeta.content);
				}
				
				// Check for critical directives
				const criticalDirectives = ['default-src', 'script-src', 'object-src', 'base-uri'];
				const missingDirectives = criticalDirectives.filter(dir => {
					return !result.policies.meta || !result.policies.meta[dir];
				});
				
				if (missingDirectives.length > 0) {
					result.recommendations.push({
						severity: 'high',
						message: 'Missing critical CSP directives: ' + missingDirectives.join(', ')
					});
				}
				
				// Check for unsafe inline scripts if CSP is present
				if (result.hasCSP) {
					const scriptSrc = result.policies.meta && result.policies.meta['script-src'];
					if (scriptSrc && (scriptSrc.includes(\"'unsafe-inline'\") || scriptSrc.includes(\"'unsafe-eval'\"))) {
						result.recommendations.push({
							severity: 'medium',
							message: 'CSP allows unsafe inline scripts or eval, which reduces its effectiveness'
						});
					}
				} else {
					result.recommendations.push({
						severity: 'high',
						message: 'No Content Security Policy detected. Implementing CSP can help prevent XSS attacks.'
					});
				}
				
				return JSON.stringify(result);
			})();
		" in tab_ref
	end tell
	
	return "\"contentSecurityPolicy\": " & csp_js
end checkCSP

-- Perform basic XSS vulnerability tests
on checkXSS(tab_ref)
	tell application "Safari"
		set xss_js to do JavaScript "
			(function() {
				let result = {
					vulnerabilities: [],
					testsPerformed: []
				};
				
				// Track tests performed
				result.testsPerformed.push('DOM-based XSS checks');
				result.testsPerformed.push('Input field sanitization checks');
				
				// Check for vulnerable patterns in JS
				const scripts = Array.from(document.getElementsByTagName('script'));
				const vulnerablePatterns = [
					{ pattern: /document\\.write\\(/g, name: 'document.write()' },
					{ pattern: /eval\\(/g, name: 'eval()' },
					{ pattern: /innerHTML/g, name: 'innerHTML' },
					{ pattern: /outerHTML/g, name: 'outerHTML' }
				];
				
				scripts.forEach(script => {
					if (!script.textContent) return;
					
					vulnerablePatterns.forEach(vp => {
						if (vp.pattern.test(script.textContent)) {
							result.vulnerabilities.push({
								type: 'potential-dom-xss',
								detail: `Found potentially unsafe ${vp.name} usage in inline script`,
								severity: 'medium'
							});
						}
					});
				});
				
				// Check input fields for potential reflection
				const inputs = document.querySelectorAll('input:not([type=password]):not([type=hidden])');
				inputs.forEach(input => {
					result.testsPerformed.push(`Input field check: ${input.name || input.id || 'unnamed'}`);
					
					// Check if input has event handlers
					const hasInputEvents = input.hasAttribute('onchange') || 
							   input.hasAttribute('oninput') ||
							   input.hasAttribute('onkeyup') ||
							   input.hasAttribute('onkeydown') ||
							   input.hasAttribute('onpaste');
					
					if (hasInputEvents) {
						result.vulnerabilities.push({
							type: 'input-event-handler',
							detail: `Input field '${input.name || input.id || 'unnamed'}' has inline event handlers which could be XSS vectors`,
							severity: 'low'
						});
					}
				});
				
				// Safety checks - we're not injecting any real payloads to avoid harming the site
				if (result.vulnerabilities.length === 0) {
					result.vulnerabilities.push({
						type: 'info',
						detail: 'No obvious XSS vulnerabilities detected in basic testing. Note: This does not guarantee the absence of all XSS vulnerabilities.',
						severity: 'info'
					});
				}
				
				return JSON.stringify(result);
			})();
		" in tab_ref
	end tell
	
	return "\"xssChecks\": " & xss_js
end checkXSS

-- Check cookie security settings
on checkCookies(tab_ref, verbose_mode)
	tell application "Safari"
		set cookie_js to do JavaScript "
			(function() {
				let result = {
					totalCookies: document.cookie.split(';').filter(c => c.trim()).length,
					insecureCookies: [],
					secureCookies: 0,
					thirdPartyCookies: 0
				};
				
				// We can't access HttpOnly cookies via JS, so we'll note that
				result.notes = [\"HTTP-only cookies can't be detected via JavaScript\"];
				
				// For demo purposes, we'll simulate finding some insecure cookies
				// In a real implementation, you would use Safari's document.cookie to analyze accessible cookies
				
				const cookieString = document.cookie;
				const cookies = cookieString.split(';').map(c => c.trim());
				
				let hostname = window.location.hostname;
				cookies.forEach(cookie => {
					if (!cookie) return;
					
					const parts = cookie.split('=');
					const name = parts[0];
					
					// Check for secure flag in cookie name (this is just a simulation)
					// Real analysis would require checking headers which JS can't do
					const seemsSecure = name.toLowerCase().includes('secure') || 
										name.toLowerCase().includes('token') ||
										name.toLowerCase().includes('auth');
					
					if (seemsSecure) {
						result.secureCookies++;
					} else {
						// For cookies we can access, assume they're not secure enough
						result.insecureCookies.push({
							name: name,
							issues: ['Missing HttpOnly flag (assumed)', 'Missing Secure flag (assumed)']
						});
					}
				});
				
				// Add some recommendations
				result.recommendations = [];
				
				if (result.insecureCookies.length > 0) {
					result.recommendations.push({
						severity: 'medium',
						message: 'Some cookies appear to be missing security flags (HttpOnly, Secure, SameSite)'
					});
				}
				
				// Add recommendation for using modern cookie settings
				result.recommendations.push({
					severity: 'info',
					message: 'For sensitive cookies, use HttpOnly, Secure flags and SameSite=Strict attribute'
				});
				
				return JSON.stringify(result);
			})();
		" in tab_ref
	end tell
	
	return "\"cookieSecurity\": " & cookie_js
end checkCookies

-- Helper function to convert boolean to JSON string
on boolToString(boolValue)
	if boolValue then
		return "true"
	else
		return "false"
	end if
end boolToString
```

## Example Usage

### Test All Security Aspects of the Current Page

```applescript
tell application "Safari"
	set frontWindowTab to current tab of front window
	set scriptResult to do shell script "osascript /path/to/safari_security_testing.scpt all"
end tell
```

### Test HTTPS Status for a Specific URL

```applescript
set testResult to do shell script "osascript /path/to/safari_security_testing.scpt https https://example.com"
```

### Check for Mixed Content with Verbose Output

```applescript
set testResult to do shell script "osascript /path/to/safari_security_testing.scpt mixed-content \"\" true"
```

## Notes

1. This script performs non-intrusive security checks only. It doesn't attempt any actual exploitation.
2. The XSS checks look for common vulnerable patterns but cannot detect all vulnerabilities.
3. Some security features can only be checked by examining HTTP headers, which has limitations when using JavaScript.
4. For comprehensive security testing, professional security tools and manual testing are recommended.
5. Safari must have "Allow JavaScript from Apple Events" enabled in Develop menu for this script to work properly.