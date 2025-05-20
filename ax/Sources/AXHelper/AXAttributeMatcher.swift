import Foundation
import ApplicationServices // For AXUIElement, CFTypeRef etc.

// debug() is assumed to be globally available from AXLogging.swift
// DEBUG_LOGGING_ENABLED is a global public var from AXLogging.swift

@MainActor
func attributesMatch(element: AXUIElement, matchDetails: [String: Any], depth: Int, isDebugLoggingEnabled: Bool) -> Bool {
    var allMatch = true

    for (key, expectedValueAny) in matchDetails {
        var perAttributeDebugMessages: [String]? = isDebugLoggingEnabled ? [] : nil
        var currentAttrMatch = false
        
        let actualValueRef: CFTypeRef? = copyAttributeValue(element: element, attribute: key)

        if actualValueRef == nil {
            if let expectedStr = expectedValueAny as? String,
               (expectedStr.lowercased() == "nil" || expectedStr.lowercased() == "!exists" || expectedStr.lowercased() == "not exists") {
                currentAttrMatch = true
                if isDebugLoggingEnabled {
                    perAttributeDebugMessages?.append("Attribute \'\\(key)\': Is nil, MATCHED criteria \'\\(expectedStr)\'.")
                }
            } else {
                currentAttrMatch = false
                if isDebugLoggingEnabled {
                    let expectedValDescText = String(describing: expectedValueAny)
                    perAttributeDebugMessages?.append("Attribute \'\\(key)\': Is nil, MISMATCHED criteria (expected \'\\(expectedValDescText)\').")
                }
            }
        } else {
            let valueRefTypeID = CFGetTypeID(actualValueRef)
            var actualValueSwift: Any?

            if valueRefTypeID == CFStringGetTypeID() {
                actualValueSwift = (actualValueRef as! CFString) as String
            } else if valueRefTypeID == CFAttributedStringGetTypeID() {
                actualValueSwift = (actualValueRef as! NSAttributedString).string
            } else if valueRefTypeID == CFBooleanGetTypeID() {
                actualValueSwift = (actualValueRef as! CFBoolean) == kCFBooleanTrue
            } else if valueRefTypeID == CFNumberGetTypeID() {
                actualValueSwift = actualValueRef as! NSNumber
            } else if valueRefTypeID == CFArrayGetTypeID() || valueRefTypeID == CFDictionaryGetTypeID() || valueRefTypeID == AXUIElementGetTypeID() {
                 actualValueSwift = actualValueRef
            } else {
                if isDebugLoggingEnabled {
                    let cfDesc = CFCopyDescription(actualValueRef) as String?
                    actualValueSwift = cfDesc ?? "UnknownCFTypeID:\\(valueRefTypeID)"
                } else {
                    actualValueSwift = "NonDebuggableCFType" // Placeholder if not debugging
                }
            }

            if let expectedStr = expectedValueAny as? String {
                let expectedStrLower = expectedStr.lowercased()

                if expectedStrLower == "exists" {
                    currentAttrMatch = true
                    if isDebugLoggingEnabled {
                        let actualValStr = String(describing: actualValueSwift ?? "nil")
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\': Value \'\\(actualValStr)\' exists, MATCHED criteria \'exists\'.")
                    }
                } else if expectedStr.starts(with: "!") {
                    let negatedExpectedStr = String(expectedStr.dropFirst())
                    let actualValStr = String(describing: actualValueSwift ?? "nil")
                    if let actualStrDirect = actualValueSwift as? String {
                        currentAttrMatch = actualStrDirect != negatedExpectedStr
                    } else {
                         currentAttrMatch = actualValStr != negatedExpectedStr
                    }
                    if isDebugLoggingEnabled {
                        let matchStatusText = currentAttrMatch ? "MATCH" : "MISMATCH"
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\': Expected NOT \'\\(negatedExpectedStr)\', Got \'\\(actualValStr)\' -> \\(matchStatusText)")
                    }
                } else if expectedStr.starts(with: "~") || expectedStr.starts(with: "*") || expectedStr.starts(with: "%") {
                    let pattern = String(expectedStr.dropFirst())
                    if let actualStrDirect = actualValueSwift as? String {
                        currentAttrMatch = actualStrDirect.localizedCaseInsensitiveContains(pattern)
                        if isDebugLoggingEnabled {
                            let matchStatusText = currentAttrMatch ? "MATCH" : "MISMATCH"
                            perAttributeDebugMessages?.append("Attribute \'\\(key)\' (String): Expected contains \'\\(pattern)\', Got \'\\(actualStrDirect)\' -> \\(matchStatusText)")
                        }
                    } else {
                        currentAttrMatch = false
                        if isDebugLoggingEnabled {
                            let actualValStr = String(describing: actualValueSwift ?? "nil")
                            perAttributeDebugMessages?.append("Attribute \'\\(key)\': Expected String pattern \'\\(expectedStr)\' for contains, Got non-String \'\\(actualValStr)\' -> MISMATCH")
                        }
                    }
                } else if let actualStrDirect = actualValueSwift as? String {
                    currentAttrMatch = actualStrDirect == expectedStr
                    if isDebugLoggingEnabled {
                        let matchStatusText = currentAttrMatch ? "MATCH" : "MISMATCH"
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\' (String): Expected \'\\(expectedStr)\', Got \'\\(actualStrDirect)\' -> \\(matchStatusText)")
                    }
                } else {
                    currentAttrMatch = false
                    if isDebugLoggingEnabled {
                        let actualTypeDescText = String(describing: type(of: actualValueSwift))
                        let actualValStr = String(describing: actualValueSwift ?? "nil")
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\': Expected String criteria \'\\(expectedStr)\', Got different type \'\\(actualTypeDescText)\':\'\\(actualValStr)\' -> MISMATCH")
                    }
                }
            } else if let expectedBool = expectedValueAny as? Bool {
                if let actualBool = actualValueSwift as? Bool {
                    currentAttrMatch = actualBool == expectedBool
                    if isDebugLoggingEnabled {
                        let matchStatusText = currentAttrMatch ? "MATCH" : "MISMATCH"
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\' (Bool): Expected \\(expectedBool), Got \\(actualBool) -> \\(matchStatusText)")
                    }
                } else {
                     currentAttrMatch = false
                     if isDebugLoggingEnabled {
                        let actualValStr = String(describing: actualValueSwift ?? "nil")
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\': Expected Bool criteria \'\\(expectedBool)\', Got non-Bool \'\\(actualValStr)\' -> MISMATCH")
                     }
                }
            } else if let expectedNumber = expectedValueAny as? NSNumber {
                 if let actualNumber = actualValueSwift as? NSNumber {
                    currentAttrMatch = actualNumber.isEqual(to: expectedNumber)
                    if isDebugLoggingEnabled {
                        let matchStatusText = currentAttrMatch ? "MATCH" : "MISMATCH"
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\' (Number): Expected \\(expectedNumber.stringValue), Got \\(actualNumber.stringValue) -> \\(matchStatusText)")
                    }
                } else {
                    currentAttrMatch = false
                    if isDebugLoggingEnabled {
                        let actualValStr = String(describing: actualValueSwift ?? "nil")
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\': Expected Number criteria \'\\(expectedNumber.stringValue)\', Got non-Number \'\\(actualValStr)\' -> MISMATCH")
                    }
                }
            } else if let expectedDouble = expectedValueAny as? Double {
                 if let actualNumber = actualValueSwift as? NSNumber {
                    currentAttrMatch = actualNumber.doubleValue == expectedDouble
                    if isDebugLoggingEnabled {
                        let matchStatusText = currentAttrMatch ? "MATCH" : "MISMATCH"
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\' (Number as Double): Expected \\(expectedDouble), Got \\(actualNumber.doubleValue) -> \\(matchStatusText)")
                    }
                 } else if let actualDouble = actualValueSwift as? Double {
                    currentAttrMatch = actualDouble == expectedDouble
                    if isDebugLoggingEnabled {
                        let matchStatusText = currentAttrMatch ? "MATCH" : "MISMATCH"
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\' (Double): Expected \\(expectedDouble), Got \\(actualDouble) -> \\(matchStatusText)")
                    }
                 } else {
                    currentAttrMatch = false
                    if isDebugLoggingEnabled {
                        let actualValStr = String(describing: actualValueSwift ?? "nil")
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\': Expected Double criteria \'\\(expectedDouble)\', Got non-Number \'\\(actualValStr)\' -> MISMATCH")
                    }
                 }
            }  else if let expectedInt = expectedValueAny as? Int {
                 if let actualNumber = actualValueSwift as? NSNumber {
                    currentAttrMatch = actualNumber.intValue == expectedInt
                    if isDebugLoggingEnabled {
                        let matchStatusText = currentAttrMatch ? "MATCH" : "MISMATCH"
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\' (Number as Int): Expected \\(expectedInt), Got \\(actualNumber.intValue) -> \\(matchStatusText)")
                    }
                 } else if let actualInt = actualValueSwift as? Int {
                    currentAttrMatch = actualInt == expectedInt
                    if isDebugLoggingEnabled {
                        let matchStatusText = currentAttrMatch ? "MATCH" : "MISMATCH"
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\' (Int): Expected \\(expectedInt), Got \\(actualInt) -> \\(matchStatusText)")
                    }
                 } else {
                    currentAttrMatch = false
                    if isDebugLoggingEnabled {
                        let actualValStr = String(describing: actualValueSwift ?? "nil")
                        perAttributeDebugMessages?.append("Attribute \'\\(key)\': Expected Int criteria \'\\(expectedInt)\', Got non-Number \'\\(actualValStr)\' -> MISMATCH")
                    }
                 }
            } else {
                // Fallback: compare string descriptions
                let actualDescText = String(describing: actualValueSwift ?? "nil")
                let expectedDescText = String(describing: expectedValueAny)
                currentAttrMatch = actualDescText == expectedDescText
                if isDebugLoggingEnabled {
                    let matchStatusText = currentAttrMatch ? "MATCH" : "MISMATCH"
                    perAttributeDebugMessages?.append("Attribute \'\\(key)\' (Fallback Comparison): Expected \'\\(expectedDescText)\', Got \'\\(actualDescText)\' -> \\(matchStatusText)")
                }
            }
        }

        if !currentAttrMatch {
            allMatch = false
            if isDebugLoggingEnabled {
                // roleDesc and detail are only used here for this debug message.
                let roleDescriptionForLog: String = axValue(of: element, attr: kAXRoleAttribute) ?? "N/A"
                let detailsForLog = perAttributeDebugMessages?.joined(separator: "; ") ?? "Debug details not collected or empty."
                let message = "attributesMatch [D\\(depth)]: Element for Role(\\(roleDescriptionForLog)): Attribute \'\\(key)\' MISMATCH. \\(detailsForLog)"
                debug(message, file: #file, function: #function, line: #line)
            }
            return false // Early exit if any attribute mismatches
        }
    }
    return allMatch
} 