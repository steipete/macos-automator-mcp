// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ax", // Package name
    platforms: [
        .macOS(.v13) // macOS 13.0 or later
    ],
    products: [ // EXPLICITLY DEFINE THE EXECUTABLE PRODUCT
        .executable(name: "ax", targets: ["ax"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "ax", // Target name, product will be 'ax'
            path: "Sources/AXHelper", // Specify the path to the source files
            sources: [ // Explicitly list all source files
                "main.swift",
                // Core
                "Core/AccessibilityConstants.swift",
                "Core/Models.swift",
                "Core/Element.swift",
                "Core/Element+Properties.swift",
                "Core/Element+Hierarchy.swift",
                "Core/Attribute.swift",
                "Core/AccessibilityError.swift",
                "Core/AccessibilityPermissions.swift",
                "Core/ProcessUtils.swift",
                // Values
                "Values/ValueHelpers.swift",
                "Values/ValueUnwrapper.swift",
                "Values/ValueParser.swift",
                "Values/ValueFormatter.swift",
                "Values/Scannable.swift",
                // Search
                "Search/ElementSearch.swift",
                "Search/AttributeMatcher.swift",
                "Search/PathUtils.swift",
                "Search/AttributeHelpers.swift",
                // Commands
                "Commands/QueryCommandHandler.swift",
                "Commands/CollectAllCommandHandler.swift",
                "Commands/PerformCommandHandler.swift",
                "Commands/ExtractTextCommandHandler.swift",
                // Utils
                "Utils/Logging.swift",
                "Utils/Scanner.swift",
                "Utils/CustomCharacterSet.swift",
                "Utils/String+HelperExtensions.swift",
                "Utils/TextExtraction.swift",
                "Utils/GeneralParsingUtils.swift"
            ]
            // swiftSettings for framework linking removed, relying on Swift imports.
        ),
    ]
)