import Foundation

// MARK: - AXScannable Protocol
protocol AXScannable {
	init?(_ scanner: AXScanner)
}

// MARK: - AXScannable Conformance
extension Int: AXScannable {
	init?(_ scanner: AXScanner) {
		if let value: Int = scanner.scanInteger() { self = value }
		else { return nil }
	}
}

extension UInt: AXScannable {
	init?(_ scanner: AXScanner) {
		if let value: UInt = scanner.scanUnsignedInteger() { self = value }
		else { return nil }
	}
}

extension Float: AXScannable {
	init?(_ scanner: AXScanner) {
        // Using the custom scanDouble and casting
		if let value = scanner.scanDouble() { self = Float(value) }
		else { return nil }
	}
}

extension Double: AXScannable {
	init?(_ scanner: AXScanner) {
		if let value = scanner.scanDouble() { self = value }
		else { return nil }
	}
}

extension Bool: AXScannable {
	init?(_ scanner: AXScanner) {
		scanner.scanWhitespaces()
		if let value: Bool = scanner.scan(dictionary: ["true": true, "false": false], options: [.caseInsensitive]) { self = value }
		else { return nil }
	}
} 