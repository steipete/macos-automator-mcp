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
                "Core/AXConstants.swift",
                "Core/AXModels.swift",
                "Core/AXElement.swift",
                "Core/AXElement+Properties.swift",
                "Core/AXElement+Hierarchy.swift",
                "Core/AXAttribute.swift",
                "Core/AXError.swift",
                "Core/AXPermissions.swift",
                "Core/AXProcessUtils.swift",
                // Values
                "Values/AXValueHelpers.swift",
                "Values/AXValueUnwrapper.swift",
                "Values/AXValueParser.swift",
                "Values/AXValueFormatter.swift",
                "Values/AXScannable.swift",
                // Search
                "Search/AXSearch.swift",
                "Search/AXAttributeMatcher.swift",
                "Search/AXPathUtils.swift",
                "Search/AXAttributeHelpers.swift",
                // Commands
                "Commands/AXQueryCommandHandler.swift",
                "Commands/AXCollectAllCommandHandler.swift",
                "Commands/AXPerformCommandHandler.swift",
                "Commands/AXExtractTextCommandHandler.swift",
                // Utils
                "Utils/AXLogging.swift",
                "Utils/AXScanner.swift",
                "Utils/AXCharacterSet.swift",
                "Utils/AXStringExtensions.swift",
                "Utils/AXTextExtraction.swift",
                "Utils/AXGeneralParsingUtils.swift"
            ]
            // swiftSettings for framework linking removed, relying on Swift imports.
        ),
    ]
)
