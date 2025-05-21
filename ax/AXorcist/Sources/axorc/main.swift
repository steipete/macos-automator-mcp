import Foundation
import ArgumentParser

// This main.swift becomes the explicit entry point for the 'axorc' executable.

// Print the received command line arguments for debugging.
let argumentsString = CommandLine.arguments.joined(separator: " ")

let argumentsForSAP = Array(CommandLine.arguments.dropFirst())

// struct TestEcho: ParsableCommand { ... } // Old TestEcho definition removed or commented out

// Call the main command defined in axorc.swift
AXORCCommand.main(argumentsForSAP)

// AXORC.main() // Commented out for this test 