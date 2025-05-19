import Foundation
import ApplicationServices     // AXUIElement*
import AppKit                 // NSRunningApplication, NSWorkspace
import CoreGraphics          // CGPoint, CGSize, etc.

// Define missing accessibility constants
let kAXActionsAttribute = "AXActions"
let kAXWindowsAttribute = "AXWindows"
let kAXPressAction = "AXPress" 

// Helper function to get AXUIElement type ID
func AXUIElementGetTypeID() -> CFTypeID {
    return AXUIElementGetTypeID_Impl()
}

// Bridging to the private function
@_silgen_name("AXUIElementGetTypeID")
func AXUIElementGetTypeID_Impl() -> CFTypeID

// Enable verbose debugging
let DEBUG = true

func debug(_ message: String) {
    if DEBUG {
        fputs("DEBUG: \(message)\n", stderr)
    }
}

// Check accessibility permissions
func checkAccessibilityPermissions() {
    debug("Checking accessibility permissions...")

    // Check without prompting. The prompt can cause issues for command-line tools.
    let accessEnabled = AXIsProcessTrusted() 

    if !accessEnabled {
        // Output to stderr so it can be captured by the calling process
        fputs("ERROR: Accessibility permissions are not granted for the application running this tool.\n", stderr)
        fputs("Please ensure the application that executes 'ax' (e.g., Terminal, your IDE, or the Node.js process) has 'Accessibility' permissions enabled in:\n", stderr)
        fputs("System Settings > Privacy & Security > Accessibility.\n", stderr)
        fputs("After granting permissions, you may need to restart the application that runs this tool.\n", stderr)

        // Also print a more specific hint if we can identify the parent process name
        if let parentName = getParentProcessName() {
            fputs("Hint: Grant accessibility permissions to '\(parentName)'.\n", stderr)
        }

        // Attempt a benign accessibility call to encourage the OS to show the permission prompt
        // for the parent application. The ax tool will still exit with an error for this run.
        fputs("Info: Attempting a minimal accessibility interaction to help trigger the system permission prompt if needed...\n", stderr)
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        _ = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        // We don't use the result of the call above when permissions are missing;
        // its purpose is to signal macOS to check/prompt for the parent app's permissions.

        exit(1)
    } else {
        debug("Accessibility permissions are granted.")
    }
}

// Helper function to get the name of the parent process
func getParentProcessName() -> String? {
    let parentPid = getppid() // Get parent process ID
    if let parentApp = NSRunningApplication(processIdentifier: parentPid) {
        return parentApp.localizedName ?? parentApp.bundleIdentifier
    }
    return nil
}

// MARK: - Codable command envelopes -------------------------------------------------

struct CommandEnvelope: Codable {
    enum Verb: String, Codable { case query, perform }
    let cmd: Verb
    let locator: Locator
    let attributes: [String]?        // for query
    let action: String?              // for perform
    let multi: Bool?                 // NEW
    let requireAction: String?       // NEW  (e.g. "AXPress")
}

struct Locator: Codable {
    let app      : String            // bundle id or display name
    let role     : String            // e.g. "AXButton"
    let match    : [String:String]   // attribute→value to match
    let pathHint : [String]?         // optional array like ["window[1]","toolbar[1]"]
}

// MARK: - Codable response types -----------------------------------------------------

struct QueryResponse: Codable {
    let attributes: [String: AnyCodable]
    
    init(attributes: [String: Any]) {
        self.attributes = attributes.mapValues(AnyCodable.init)
    }
}

struct MultiQueryResponse: Codable {
    let elements: [[String: AnyCodable]]
    
    init(elements: [[String: Any]]) {
        self.elements = elements.map { element in
            element.mapValues(AnyCodable.init)
        }
    }
}

struct PerformResponse: Codable {
    let status: String
}

struct ErrorResponse: Codable {
    let error: String
}

// AnyCodable wrapper type for JSON encoding of Any values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable cannot decode value"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map(AnyCodable.init))
        case let dict as [String: Any]:
            try container.encode(dict.mapValues(AnyCodable.init))
        default:
            // Try to convert to string as a fallback
            try container.encode(String(describing: value))
        }
    }
}

// Simple intermediate type for element attributes
typealias ElementAttributes = [String: Any]

// Create a completely new helper function to safely extract attributes
func getElementAttributes(_ element: AXUIElement, attributes: [String]) -> ElementAttributes {
    var result = ElementAttributes()
    
    // First, discover all available attributes for this specific element
    var allAttributes = attributes
    var attrNames: CFArray?
    if AXUIElementCopyAttributeNames(element, &attrNames) == .success, let names = attrNames {
        let count = CFArrayGetCount(names)
        for i in 0..<count {
            if let ptr = CFArrayGetValueAtIndex(names, i), 
               let cfStr = unsafeBitCast(ptr, to: CFString.self) as String?,
               !allAttributes.contains(cfStr) {
                allAttributes.append(cfStr)
            }
        }
        debug("Element has \(count) available attributes")
    }
    
    // Keep track of all available actions
    var availableActions: [String] = []
    
    // Process all attributes
    for attr in allAttributes {
        // Get the raw value first
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, attr as CFString, &value)
        
        if err != .success || value == nil {
            // Only include requested attributes in the result
            if attributes.contains(attr) {
                result[attr] = "Not available"
            }
            continue
        }
        
        let unwrappedValue = value!
        let extractedValue: Any
        
        // Handle different types of values
        if CFGetTypeID(unwrappedValue) == CFStringGetTypeID() {
            // String value - most common for text, titles, etc.
            let cfString = unwrappedValue as! CFString
            extractedValue = cfString as String
        }
        else if CFGetTypeID(unwrappedValue) == CFBooleanGetTypeID() {
            // Boolean value
            let cfBool = unwrappedValue as! CFBoolean
            extractedValue = CFBooleanGetValue(cfBool)
        }
        else if CFGetTypeID(unwrappedValue) == CFNumberGetTypeID() {
            // Numeric value
            let cfNumber = unwrappedValue as! CFNumber
            var intValue: Int = 0
            if CFNumberGetValue(cfNumber, CFNumberType.intType, &intValue) {
                extractedValue = intValue
            } else {
                extractedValue = "Number (conversion failed)"
            }
        }
        else if CFGetTypeID(unwrappedValue) == CFArrayGetTypeID() {
            // Array values (like children or subroles)
            let cfArray = unwrappedValue as! CFArray
            let count = CFArrayGetCount(cfArray)
            
            // For actions, extract them into our list
            if attr == "AXActions" {
                for i in 0..<count {
                    if let actionPtr = CFArrayGetValueAtIndex(cfArray, i),
                       let actionStr = unsafeBitCast(actionPtr, to: CFString.self) as String? {
                        availableActions.append(actionStr)
                    }
                }
                extractedValue = availableActions
            } else {
                extractedValue = "Array with \(count) elements"
            }
        }
        else if attr == "AXPosition" || attr == "AXSize" {
            // Handle AXValue types (usually for position and size)
            // Safely check if it's an AXValue
            let axValueType = AXValueGetType(unwrappedValue as! AXValue)
            
            if attr == "AXPosition" && axValueType.rawValue == AXValueType.cgPoint.rawValue {
                // It's a position value
                var point = CGPoint.zero
                if AXValueGetValue(unwrappedValue as! AXValue, AXValueType.cgPoint, &point) {
                    extractedValue = ["x": Int(point.x), "y": Int(point.y)]
                } else {
                    extractedValue = ["error": "Position data (conversion failed)"]
                }
            } 
            else if attr == "AXSize" && axValueType.rawValue == AXValueType.cgSize.rawValue {
                // It's a size value
                var size = CGSize.zero
                if AXValueGetValue(unwrappedValue as! AXValue, AXValueType.cgSize, &size) {
                    extractedValue = ["width": Int(size.width), "height": Int(size.height)]
                } else {
                    extractedValue = ["error": "Size data (conversion failed)"]
                }
            }
            else {
                // It's some other kind of AXValue
                extractedValue = ["error": "AXValue type: \(axValueType.rawValue)"]
            }
        }
        else if attr == "AXTitleUIElement" || attr == "AXLabelUIElement" {
            // These are special attributes that point to other AXUIElements
            // Extract the text from them instead of just reporting the type
            let titleElement = unwrappedValue as! AXUIElement
            
            // Try to get its AXValue attribute which usually contains the text
            var titleValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(titleElement, "AXValue" as CFString, &titleValue) == .success, 
               let titleString = titleValue as? String {
                extractedValue = titleString
            }
            // If no AXValue, try AXTitle
            else if AXUIElementCopyAttributeValue(titleElement, "AXTitle" as CFString, &titleValue) == .success,
                   let titleString = titleValue as? String {
                extractedValue = titleString
            }
            // Fallback to indicating we found a title element but couldn't extract text
            else {
                extractedValue = "Title element (no extractable text)"
            }
        }
        else {
            // Try to get the type description for debugging
            let typeID = CFGetTypeID(unwrappedValue)
            if let typeDesc = CFCopyTypeIDDescription(typeID) {
                let typeString = typeDesc as String
                extractedValue = "Unknown type: \(typeString)"
            } else {
                extractedValue = "Unknown type: \(typeID)"
            }
        }
        
        // Only include explicitly requested attributes and useful ones in the final result
        if attributes.contains(attr) || 
           attr.hasPrefix("AXTitle") || 
           attr.hasPrefix("AXLabel") || 
           attr.hasPrefix("AXHelp") || 
           attr.hasPrefix("AXDescription") || 
           attr.hasPrefix("AXValue") || 
           attr.hasPrefix("AXRole") {
            result[attr] = extractedValue
        }
    }
    
    // Make sure actions are available as a proper array if requested
    if attributes.contains("AXActions") {
        if !availableActions.isEmpty {
            result["AXActions"] = availableActions
        } else if result["AXActions"] == nil {
            result["AXActions"] = "Not available"
        }
    }
    
    // Add a computed property to give the most descriptive name for this element
    // This combines multiple attributes in order of preference
    var computedName: String? = nil
    
    // Try all possible ways to get a meaningful name/title
    if let title = result["AXTitle"] as? String, title != "Not available" && !title.isEmpty {
        computedName = title
    }
    else if let titleUIElement = result["AXTitleUIElement"] as? String, 
            titleUIElement != "Not available" && titleUIElement != "Title element (no extractable text)" {
        computedName = titleUIElement
    }
    else if let value = result["AXValue"] as? String, value != "Not available" && !value.isEmpty {
        computedName = value
    }
    else if let description = result["AXDescription"] as? String, description != "Not available" && !description.isEmpty {
        computedName = description
    }
    else if let label = result["AXLabel"] as? String, label != "Not available" && !label.isEmpty {
        computedName = label
    }
    else if let help = result["AXHelp"] as? String, help != "Not available" && !help.isEmpty {
        computedName = help
    }
    else if let roleDesc = result["AXRoleDescription"] as? String, roleDesc != "Not available" {
        // Use role description as a last resort
        let role = result["AXRole"] as? String ?? "Unknown"
        computedName = "\(roleDesc) (\(role))"
    }
    
    // Add the computed name if we found one
    if let name = computedName {
        result["ComputedName"] = name
    }
    
    // Add a computed clickable status based on role and other properties
    let isButton = result["AXRole"] as? String == "AXButton"
    let hasClickAction = availableActions.contains("AXPress")
    if isButton || hasClickAction {
        result["IsClickable"] = true
    }
    
    return result
}

// MARK: - Helpers --------------------------------------------------------------------

enum AXErrorString: Error, CustomStringConvertible {
    case notAuthorised(AXError)
    case elementNotFound
    case actionFailed(AXError)

    var description: String {
        switch self {
        case .notAuthorised(let e): return "AX authorisation failed: \(e)"
        case .elementNotFound:      return "No element matches the locator"
        case .actionFailed(let e):  return "Action failed: \(e)"
        }
    }
}

/// Return the running app's PID given bundle id or localized name
func pid(forAppIdentifier ident: String) -> pid_t? {
    debug("Looking for app: \(ident)")
    
    // Handle Safari specifically - try both bundle ID and name
    if ident == "Safari" {
        debug("Special handling for Safari")
        
        // Try by bundle ID first
        if let safariApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari").first {
            debug("Found Safari by bundle ID, PID: \(safariApp.processIdentifier)")
            return safariApp.processIdentifier
        }
        
        // Try by name
        if let safariApp = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "Safari" }) {
            debug("Found Safari by name, PID: \(safariApp.processIdentifier)")
            return safariApp.processIdentifier
        }
    }
    
    if let byBundle = NSRunningApplication.runningApplications(withBundleIdentifier: ident).first {
        debug("Found by bundle ID: \(ident), PID: \(byBundle.processIdentifier)")
        return byBundle.processIdentifier
    }
    
    let app = NSWorkspace.shared.runningApplications
        .first { $0.localizedName == ident }
    
    if let app = app {
        debug("Found by name: \(ident), PID: \(app.processIdentifier)")
        return app.processIdentifier
    }
    
    // Also try searching without case sensitivity
    let appLowerCase = NSWorkspace.shared.runningApplications
        .first { $0.localizedName?.lowercased() == ident.lowercased() }
    
    if let app = appLowerCase {
        debug("Found by case-insensitive name: \(ident), PID: \(app.processIdentifier)")
        return app.processIdentifier
    }
    
    // Print running applications to help debug
    debug("All running applications:")
    for app in NSWorkspace.shared.runningApplications {
        debug("  - \(app.localizedName ?? "Unknown") (Bundle: \(app.bundleIdentifier ?? "Unknown"), PID: \(app.processIdentifier))")
    }
    
    debug("App not found: \(ident)")
    return nil
}

/// Fetch a single AX attribute as `T?`
func axValue<T>(of element: AXUIElement, attr: String) -> T? {
    var value: CFTypeRef?
    let err = AXUIElementCopyAttributeValue(element, attr as CFString, &value)
    guard err == .success, let unwrappedValue = value else { return nil }
    
    // For actions, try explicitly casting to CFArray of strings
    if attr == kAXActionsAttribute && T.self == [String].self {
        debug("Reading actions with special handling")
        guard CFGetTypeID(unwrappedValue) == CFArrayGetTypeID() else { return nil }
        
        let cfArray = unwrappedValue as! CFArray
        let count = CFArrayGetCount(cfArray)
        var actionStrings = [String]()
        
        for i in 0..<count {
            guard let actionPtr = CFArrayGetValueAtIndex(cfArray, i) else { continue }
            
            // Safely get the CFString
            let cfStr = Unmanaged<CFTypeRef>.fromOpaque(actionPtr).takeUnretainedValue()
            if CFGetTypeID(cfStr) == CFStringGetTypeID(), 
               let actionStr = (cfStr as! CFString) as String? {
                actionStrings.append(actionStr)
            }
        }
        
        if !actionStrings.isEmpty {
            debug("Found actions: \(actionStrings)")
            return actionStrings as? T
        }
    }
    
    // Safe casting with type checking for AXUIElement arrays
    if CFGetTypeID(unwrappedValue) == CFArrayGetTypeID() && T.self == [AXUIElement].self {
        let cfArray = unwrappedValue as! CFArray
        let count = CFArrayGetCount(cfArray)
        var result = [AXUIElement]()
        
        for i in 0..<count {
            guard let elementPtr = CFArrayGetValueAtIndex(cfArray, i) else { continue }
            
            // Create CFTypeRef and check if it's an AXUIElement
            let cfType = Unmanaged<CFTypeRef>.fromOpaque(elementPtr).takeUnretainedValue()
            if CFGetTypeID(cfType) == AXUIElementGetTypeID() {
                let axElement = cfType as! AXUIElement
                result.append(axElement)
            }
        }
        return result as? T
    } else if T.self == String.self {
        if CFGetTypeID(unwrappedValue) == CFStringGetTypeID() {
            return (unwrappedValue as! CFString) as? T
        }
        return nil
    }
    
    // For other types, use safer casting with type checking
    if T.self == Bool.self && CFGetTypeID(unwrappedValue) == CFBooleanGetTypeID() {
        let boolValue = CFBooleanGetValue((unwrappedValue as! CFBoolean))
        return boolValue as? T
    } else if T.self == Int.self && CFGetTypeID(unwrappedValue) == CFNumberGetTypeID() {
        var intValue: Int = 0
        if CFNumberGetValue((unwrappedValue as! CFNumber), CFNumberType.intType, &intValue) {
            return intValue as? T
        }
        return nil
    }
    
    // Special case for AXUIElement
    if T.self == AXUIElement.self {
        // Check if it's an AXUIElement
        if CFGetTypeID(unwrappedValue) == AXUIElementGetTypeID() {
            return unwrappedValue as? T
        }
        return nil
    }
    
    // If we can't safely cast, return nil instead of crashing
    debug("Couldn't safely cast \(attr) to requested type")
    return nil
}

/// Depth-first search for an element that matches the locator's role + attributes
func search(element: AXUIElement,
            locator: Locator,
            depth: Int = 0,
            maxDepth: Int = 200) -> AXUIElement? {

    if depth > maxDepth { return nil }

    // Check role
    if let role: String = axValue(of: element, attr: kAXRoleAttribute as String),
       role == locator.role {

        // Match all requested attributes
        var ok = true
        for (attr, want) in locator.match {
            let got: String? = axValue(of: element, attr: attr)
            if got != want { ok = false; break }
        }
        if ok { return element }
    }

    // Recurse into children
    if let children: [AXUIElement] = axValue(of: element, attr: kAXChildrenAttribute as String) {
        for child in children {
            if let hit = search(element: child, locator: locator, depth: depth + 1) {
                return hit
            }
        }
    }
    return nil
}

/// Parse a path hint like "window[1]" into (role, index)
func parsePathComponent(_ path: String) -> (role: String, index: Int)? {
    let pattern = #"(\w+)\[(\d+)\]"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(path.startIndex..<path.endIndex, in: path)
    
    guard let match = regex.firstMatch(in: path, range: range) else { return nil }
    
    let roleRange = Range(match.range(at: 1), in: path)!
    let indexRange = Range(match.range(at: 2), in: path)!
    
    let role = String(path[roleRange])
    let index = Int(path[indexRange])!
    
    return (role: role, index: index - 1) // Convert to 0-based index
}

/// Navigate to an element based on a path hint
func navigateToElement(from root: AXUIElement, pathHint: [String]) -> AXUIElement? {
    var currentElement = root
    
    debug("Starting navigation with path hint: \(pathHint)")
    
    for (i, pathComponent) in pathHint.enumerated() {
        debug("Processing path component \(i+1)/\(pathHint.count): \(pathComponent)")
        
        guard let (role, index) = parsePathComponent(pathComponent) else { 
            debug("Failed to parse path component: \(pathComponent)")
            return nil 
        }
        
        debug("Parsed as role: \(role), index: \(index) (0-based)")
        
        // Special handling for window (direct access without complicated navigation)
        if role.lowercased() == "window" {
            debug("Special handling for window role")
            guard let windows: [AXUIElement] = axValue(of: currentElement, attr: kAXWindowsAttribute as String) else {
                debug("No windows found for application")
                return nil
            }
            
            debug("Found \(windows.count) windows")
            if index >= windows.count {
                debug("Window index \(index+1) out of bounds (max: \(windows.count))")
                return nil
            }
            
            currentElement = windows[index]
            debug("Successfully navigated to window[\(index+1)]")
            continue
        }
        
        // Get all children matching the role
        let roleKey = "AX\(role.prefix(1).uppercased() + role.dropFirst())"
        debug("Looking for elements with role key: \(roleKey)")
        
        // First try to get children by specific role attribute
        if let roleSpecificChildren: [AXUIElement] = axValue(of: currentElement, attr: roleKey) {
            debug("Found \(roleSpecificChildren.count) elements with role \(roleKey)")
            
            // Make sure index is in bounds
            guard index < roleSpecificChildren.count else {
                debug("Index out of bounds: \(index+1) > \(roleSpecificChildren.count) for \(pathComponent)")
                return nil
            }
            
            currentElement = roleSpecificChildren[index]
            debug("Successfully navigated to \(roleKey)[\(index+1)]")
            continue
        }
        
        debug("No elements found with specific role \(roleKey), trying with children")
        
        // If we can't find by specific role, try getting all children
        guard let allChildren: [AXUIElement] = axValue(of: currentElement, attr: kAXChildrenAttribute as String) else {
            debug("No children found for element at path component: \(pathComponent)")
            return nil
        }
        
        debug("Found \(allChildren.count) children, filtering by role: \(role)")
        
        // Filter by role
        let matchingChildren = allChildren.filter { element in
            guard let elementRole: String = axValue(of: element, attr: kAXRoleAttribute as String) else { 
                return false 
            }
            let matches = elementRole.lowercased() == role.lowercased()
            if matches {
                debug("Found element with matching role: \(elementRole)")
            }
            return matches
        }
        
        if matchingChildren.isEmpty {
            debug("No children with role '\(role)' found")
            
            // List available roles for debugging
            debug("Available roles among children:")
            for child in allChildren {
                if let childRole: String = axValue(of: child, attr: kAXRoleAttribute as String) {
                    debug("  - \(childRole)")
                }
            }
            
            return nil
        }
        
        debug("Found \(matchingChildren.count) children with role '\(role)'")
        
        // Make sure index is in bounds
        guard index < matchingChildren.count else {
            debug("Index out of bounds: \(index+1) > \(matchingChildren.count) for \(pathComponent)")
            return nil
        }
        
        currentElement = matchingChildren[index]
        debug("Successfully navigated to \(role)[\(index+1)]")
    }
    
    debug("Path hint navigation completed successfully")
    return currentElement
}

/// Collect all elements that match the locator's role + attributes
func collectAll(element: AXUIElement,
                locator: Locator,
                requireAction: String?,
                hits: inout [AXUIElement],
                depth: Int = 0,
                maxDepth: Int = 200) {

    // Safety limit on matches - increased to handle larger web pages
    if hits.count > 100000 {
        debug("Safety limit of 100000 matching elements reached, stopping search")
        return
    }

    if depth > maxDepth { 
        debug("Max depth (\(maxDepth)) reached")
        return 
    }

    // role test
    let wildcardRole = locator.role == "*" || locator.role.isEmpty
    let elementRole = axValue(of: element, attr: kAXRoleAttribute as String) as String?
    let roleMatches = wildcardRole || elementRole == locator.role
    
    if wildcardRole {
        debug("Using wildcard role match (*) at depth \(depth)")
    } else if let role = elementRole {
        debug("Element role at depth \(depth): \(role), looking for: \(locator.role)")
    }
    
    if roleMatches {
        // attribute match
        var ok = true
        for (attr, want) in locator.match {
            let got = axValue(of: element, attr: attr) as String?
            if got != want { 
                debug("Attribute mismatch at depth \(depth): \(attr)=\(got ?? "nil") (wanted \(want))")
                ok = false 
                break 
            }
        }
        
        // Check action requirement using safer method
        if ok, let required = requireAction {
            debug("Checking for required action: \(required) at depth \(depth)")
            
            // For web elements, prioritize interactive elements even if we can't verify action support
            let isInteractiveWebElement = elementRole == "AXLink" || 
                                         elementRole == "AXButton" ||
                                         elementRole == "AXMenuItem" ||
                                         elementRole == "AXRadioButton" ||
                                         elementRole == "AXCheckBox"
                                         
            if isInteractiveWebElement {
                // Use our more robust action check instead of just assuming
                if elementSupportsAction(element, action: required) {
                    debug("Web element at depth \(depth) supports \(required) - high priority match")
                    ok = true
                } else {
                    // For web elements, if we can't verify support but it's a naturally interactive element,
                    // still mark it as ok but with lower priority
                    debug("Interactive web element at depth \(depth) assumed to support \(required)")
                    ok = true
                }
            } else if !elementSupportsAction(element, action: required) {
                debug("Element at depth \(depth) doesn't support \(required)")
                ok = false
            } else {
                debug("Element at depth \(depth) supports \(required)")
                ok = true
            }
        }
        
        if ok { 
            debug("Found matching element at depth \(depth), role: \(elementRole ?? "unknown")")
            hits.append(element) 
        }
    }

    // Only recurse into children if we're not at the max depth - avoid potential crashes
    if depth < maxDepth {
        // Use multiple approaches to get children for better discovery
        var childrenToCheck: [AXUIElement] = []
        
        // 1. First try standard children - using safer approach to get children
        if let children: [AXUIElement] = axValue(of: element, attr: kAXChildrenAttribute as String) {
            // Make a safe copy of the children array
            childrenToCheck.append(contentsOf: children)
        }
        
        // 2. For web content, try specific attributes that contain more elements
        let isWebContent = elementRole?.contains("AXWeb") == true || 
                          elementRole == "AXGroup" || 
                          elementRole?.contains("HTML") == true ||
                          elementRole == "AXApplication" // For Safari root element
        
        if isWebContent {
            // Expanded web-specific attributes that often contain interactive elements
            let webAttributes = [
                "AXLinks", "AXButtons", "AXControls", "AXRadioButtons", 
                "AXStaticTexts", "AXTextFields", "AXImages", "AXTables", 
                "AXLists", "AXMenus", "AXMenuItems", "AXTabs",
                "AXDisclosureTriangles", "AXGroups", "AXCheckBoxes",
                "AXComboBoxes", "AXPopUpButtons", "AXSliders", "AXValueIndicators",
                "AXLabels", "AXMenuButtons", "AXIncrementors", "AXProgressIndicators",
                "AXCells", "AXColumns", "AXRows", "AXOutlines", "AXHeadings",
                "AXWebArea", "AXWebContent", "AXScrollArea", "AXLandmarkRegion"
            ]
                                
            for webAttr in webAttributes {
                // Use safer approach to retrieve elements
                if let webElements: [AXUIElement] = axValue(of: element, attr: webAttr) {
                    // Make a safe copy of the elements
                    for webElement in webElements {
                        childrenToCheck.append(webElement)
                    }
                    debug("Found \(webElements.count) elements in \(webAttr)")
                }
            }
            
            // Special handling for Safari to find DOM elements
            if axValue(of: element, attr: "AXDOMIdentifier") != nil || 
               axValue(of: element, attr: "AXDOMClassList") != nil {
                debug("Found web DOM element, checking children more thoroughly")
                
                // Try to get DOM children specifically
                if let domChildren: [AXUIElement] = axValue(of: element, attr: "AXDOMChildren") {
                    // Make a safe copy of the DOM children
                    for domChild in domChildren {
                        childrenToCheck.append(domChild)
                    }
                    debug("Found \(domChildren.count) DOM children")
                }
            }
        }
        
        // 3. Try other common containers for UI elements
        let containerAttributes = [
            "AXContents", "AXVisibleChildren", "AXRows", "AXColumns", 
            "AXVisibleRows", "AXTabs", "AXTabContents", "AXUnknown",
            "AXSelectedChildren", "AXDisclosedRows", "AXDisclosedByRow",
            "AXHeader", "AXDrawer", "AXDetails", "AXDialog"
        ]
                                  
        for contAttr in containerAttributes {
            if let containers: [AXUIElement] = axValue(of: element, attr: contAttr) {
                // Make a safe copy of the containers
                for container in containers {
                    childrenToCheck.append(container)
                }
                debug("Found \(containers.count) elements in \(contAttr)")
            }
        }
        
        // Use a simpler approach to deduplication
        // We'll just track if we've seen the same element before
        var uniqueElements: [AXUIElement] = []
        var seen = Set<ObjectIdentifier>()
        
        for child in childrenToCheck {
            // Create a safer identifier
            let id = ObjectIdentifier(child as AnyObject)
            if !seen.contains(id) {
                seen.insert(id)
                uniqueElements.append(child)
            }
        }
        
        // Check if we found any children
        if !uniqueElements.isEmpty {
            debug("Found total of \(uniqueElements.count) unique children to explore at depth \(depth)")
            
            // Process all children with a higher limit for web content
            // Increased from 100 to 500 children per element for web content
            let maxChildrenToProcess = min(uniqueElements.count, 500)
            if uniqueElements.count > maxChildrenToProcess {
                debug("Limiting processing to \(maxChildrenToProcess) of \(uniqueElements.count) children at depth \(depth)")
            }
            
            let childrenToProcess = uniqueElements.prefix(maxChildrenToProcess)
            for (i, child) in childrenToProcess.enumerated() {
                if hits.count > 100000 { break } // Safety check
                
                // Safety check - skip this step instead of validating type
                // The AXUIElement type was already validated during collection
                
                debug("Exploring child \(i+1)/\(maxChildrenToProcess) at depth \(depth)")
                collectAll(element: child, locator: locator, requireAction: requireAction,
                           hits: &hits, depth: depth + 1, maxDepth: maxDepth)
            }
        } else {
            debug("No children at depth \(depth)")
        }
    }
}

// MARK: - Core verbs -----------------------------------------------------------------

func handleQuery(cmd: CommandEnvelope) throws -> Codable {
    debug("Processing query: \(cmd.cmd), app: \(cmd.locator.app), role: \(cmd.locator.role), multi: \(cmd.multi ?? false)")
    
    guard let pid = pid(forAppIdentifier: cmd.locator.app) else {
        debug("Failed to find app: \(cmd.locator.app)")
        throw AXErrorString.elementNotFound
    }
    
    debug("Creating application element for PID: \(pid)")
    let appElement = AXUIElementCreateApplication(pid)
    
    // Apply path hint if provided
    var startElement = appElement
    if let pathHint = cmd.locator.pathHint, !pathHint.isEmpty {
        debug("Path hint provided: \(pathHint)")
        guard let navigatedElement = navigateToElement(from: appElement, pathHint: pathHint) else {
            debug("Failed to navigate using path hint")
            throw AXErrorString.elementNotFound
        }
        startElement = navigatedElement
        debug("Successfully navigated to element using path hint")
    }

    // Define the attributes to query - add more useful attributes
    var attributesToQuery = cmd.attributes ?? [
        "AXRole", "AXTitle", "AXIdentifier", 
        "AXDescription", "AXValue", "AXHelp",
        "AXSubrole", "AXRoleDescription", "AXLabel",
        "AXActions", "AXPosition", "AXSize"
    ]
    
    // Check if the client explicitly asked for a limited set of attributes
    let shouldExpandAttributes = cmd.attributes == nil || cmd.attributes!.isEmpty
    
    // If using default attributes, try to get additional attributes for the element
    if shouldExpandAttributes {
        // Query all available attributes for the starting element
        var attrNames: CFArray?
        if AXUIElementCopyAttributeNames(startElement, &attrNames) == .success, let names = attrNames {
            let count = CFArrayGetCount(names)
            for i in 0..<count {
                if let ptr = CFArrayGetValueAtIndex(names, i), 
                   let cfStr = unsafeBitCast(ptr, to: CFString.self) as String?,
                   !attributesToQuery.contains(cfStr) {
                    attributesToQuery.append(cfStr)
                }
            }
            debug("Expanded to include \(attributesToQuery.count) attributes")
        }
    }

    // Handle multi-element query
    if cmd.multi == true {
        debug("Performing multi-element query")
        
        // Collect elements without action requirement first
        var initialHits: [AXUIElement] = []
        collectAll(element: startElement, locator: cmd.locator,
                  requireAction: nil, hits: &initialHits)
        
        debug("Found \(initialHits.count) elements without action filter")
        
        // Create a new array for storing filtered elements
        var matchingElements: [AXUIElement] = []
        
        // If action required, filter the elements
        if let requiredAction = cmd.requireAction {
            debug("Filtering for action: \(requiredAction)")
            
            // Manually check each element for action support
            var matchCount = 0
            for element in initialHits {
                if elementSupportsAction(element, action: requiredAction) {
                    matchingElements.append(element)
                    matchCount += 1
                }
            }
            
            debug("After filtering, found \(matchCount) elements with action: \(requiredAction)")
            
            // If no matches but we found elements, return a subset with warning
            if matchingElements.isEmpty && !initialHits.isEmpty {
                debug("Returning elements without required action")
                
                // Manually build result array
                var resultArray: [ElementAttributes] = []
                let maxElements = min(initialHits.count, 10)
                
                for i in 0..<maxElements {
                    var attributes = getElementAttributes(initialHits[i], attributes: attributesToQuery)
                    attributes["_warning"] = "Element doesn't support \(requiredAction) action"
                    resultArray.append(attributes)
                }
                
                return MultiQueryResponse(elements: resultArray)
            }
        } else {
            // No action required, use all elements
            matchingElements = initialHits
        }
        
        debug("Processing final results")
        
        // If no matches found, throw error
        if matchingElements.isEmpty {
            debug("No elements matched criteria")
            throw AXErrorString.elementNotFound
        }
        
        // Manually build result array with a hard limit
        var resultArray: [ElementAttributes] = []
        let maxElements = min(matchingElements.count, 200)
        
        for i in 0..<maxElements {
            let attributes = getElementAttributes(matchingElements[i], attributes: attributesToQuery)
            resultArray.append(attributes)
        }
        
        return MultiQueryResponse(elements: resultArray)
    }
    
    // Single element query (original behavior)
    guard let element = search(element: startElement, locator: cmd.locator) else {
        throw AXErrorString.elementNotFound
    }

    // Get attributes for the single element
    let attributes = getElementAttributes(element, attributes: attributesToQuery)
    return QueryResponse(attributes: attributes)
}

func handlePerform(cmd: CommandEnvelope) throws -> PerformResponse {
    guard let pid = pid(forAppIdentifier: cmd.locator.app),
          let action = cmd.action else {
        throw AXErrorString.elementNotFound
    }
    let appElement = AXUIElementCreateApplication(pid)
    guard let element = search(element: appElement, locator: cmd.locator) else {
        throw AXErrorString.elementNotFound
    }
    let err = AXUIElementPerformAction(element, action as CFString)
    guard err == .success else {
        throw AXErrorString.actionFailed(err)
    }
    return PerformResponse(status: "ok")
}

// MARK: - Main loop ------------------------------------------------------------------

let decoder = JSONDecoder()
let encoder = JSONEncoder()
if #available(macOS 10.15, *) {
    encoder.outputFormatting = [.withoutEscapingSlashes]
}

// Check for accessibility permissions before starting
checkAccessibilityPermissions()

while let line = readLine(strippingNewline: true) {
    do {
        let data = Data(line.utf8)
        let cmd = try decoder.decode(CommandEnvelope.self, from: data)

        switch cmd.cmd {
        case .query:
            let result = try handleQuery(cmd: cmd)
            let reply = try encoder.encode(result)
            FileHandle.standardOutput.write(reply)
            FileHandle.standardOutput.write("\n".data(using: .utf8)!)

        case .perform:
            let status = try handlePerform(cmd: cmd)
            let reply = try encoder.encode(status)
            FileHandle.standardOutput.write(reply)
            FileHandle.standardOutput.write("\n".data(using: .utf8)!)
        }
    } catch {
        let errorResponse = ErrorResponse(error: "\(error)")
        if let errorData = try? encoder.encode(errorResponse) {
            FileHandle.standardError.write(errorData)
            FileHandle.standardError.write("\n".data(using: .utf8)!)
        } else {
            fputs("{\"error\":\"\(error)\"}\n", stderr)
        }
    }
}

// Add a safer action checking function
func elementSupportsAction(_ element: AXUIElement, action: String) -> Bool {
    // Get the list of actions directly with proper error handling
    var actionNames: CFArray?
    let err = AXUIElementCopyActionNames(element, &actionNames)
    
    if err != .success {
        debug("Failed to get action names: \(err)")
        return false
    }
    
    guard let actions = actionNames else {
        debug("No actions array")
        return false
    }
    
    // Check if the specific action exists in the array
    let count = CFArrayGetCount(actions)
    debug("Element has \(count) actions")
    
    // Safety check
    if count == 0 {
        debug("Element has no actions")
        return false
    }
    
    // Actually check for the specific action
    for i in 0..<count {
        if let actionPtr = CFArrayGetValueAtIndex(actions, i),
           let actionStr = unsafeBitCast(actionPtr, to: CFString.self) as String? {
            if actionStr == action {
                debug("Element supports action: \(action)")
                return true
            }
        }
    }
    
    debug("Element doesn't support action: \(action)")
    return false
}

