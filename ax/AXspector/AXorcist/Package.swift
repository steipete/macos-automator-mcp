// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "axPackage", // Renamed package slightly to avoid any confusion with executable name
    platforms: [
        .macOS(.v13) // macOS 13.0 or later
    ],
    products: [
        // Add library product for AXorcist
        .library(name: "AXorcist", targets: ["AXorcist"]),
        .executable(name: "axorc", targets: ["axorc"]) // Product 'axorc' comes from target 'axorc'
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0") // Added swift-argument-parser
    ],
    targets: [
        .target(
            name: "AXorcist", // New library target name
            path: "Sources/AXorcist", // Path to library sources
            sources: [ // All files previously in AXHelper, except main.swift
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
                "Commands/GetAttributesCommandHandler.swift",
                "Commands/BatchCommandHandler.swift",
                "Commands/DescribeElementCommandHandler.swift",
                "Commands/GetFocusedElementCommandHandler.swift",
                // Utils
                "Utils/Scanner.swift",
                "Utils/CustomCharacterSet.swift",
                "Utils/String+HelperExtensions.swift",
                "Utils/TextExtraction.swift",
                "Utils/GeneralParsingUtils.swift"
            ]
        ),
        .executableTarget(
            name: "axorc", // Executable target name
            dependencies: [
                "AXorcist",
                .product(name: "ArgumentParser", package: "swift-argument-parser") // Added dependency product
            ], 
            path: "Sources/axorc",      // Path to executable's main.swift (now axorc.swift)
            sources: ["axorc.swift"]
        ),
        .testTarget(
            name: "AXorcistTests",
            dependencies: ["AXorcist"], // Test target depends on the library
            path: "Tests/AXorcistTests",
            sources: ["AXHelperIntegrationTests.swift"]
        )
    ]
)