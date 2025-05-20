// AXScanner.swift - Custom scanner implementation (AXScanner)

import Foundation

// String extension from AXScanner
extension String {
	subscript (i: Int) -> Character {
		return self[index(startIndex, offsetBy: i)]
	}
	func range(from range: NSRange) -> Range<String.Index>? {
		return Range(range, in: self)
	}
	func range(from range: Range<String.Index>) -> NSRange {
		return NSRange(range, in: self)
	}
	var firstLine: String? {
		var line: String?
		self.enumerateLines {
			line = $0
			$1 = true
		}
		return line
	}
}

// AXCharacterSet struct from AXScanner
struct AXCharacterSet {
	private var characters: Set<Character>
	init(characters: Set<Character>) {
		self.characters = characters
	}
	init(charactersInString: String) {
		self.characters = Set(charactersInString.map { $0 })
	}
	func contains(_ character: Character) -> Bool {
		return self.characters.contains(character)
	}
	mutating func add(_ characters: Set<Character>) {
		self.characters.formUnion(characters)
	}
	func adding(_ characters: Set<Character>) -> AXCharacterSet {
		return AXCharacterSet(characters: self.characters.union(characters))
	}
	mutating func remove(_ characters: Set<Character>) {
		self.characters.subtract(characters)
	}
	func removing(_ characters: Set<Character>) -> AXCharacterSet   {
		return AXCharacterSet(characters: self.characters.subtracting(characters))
	}

    // Add some common character sets that might be useful, similar to Foundation.CharacterSet
    static var whitespacesAndNewlines: AXCharacterSet {
        return AXCharacterSet(charactersInString: " \t\n\r")
    }
    static var decimalDigits: AXCharacterSet {
        return AXCharacterSet(charactersInString: "0123456789")
    }
    static func punctuationAndSymbols() -> AXCharacterSet { // Example
        // This would need a more comprehensive list based on actual needs
        return AXCharacterSet(charactersInString: ".,:;?!()[]{}-_=+") // Simplified set
    }
     static func characters(in string: String) -> AXCharacterSet {
        return AXCharacterSet(charactersInString: string)
    }
}

// AXScanner class from AXScanner
class AXScanner {

	let string: String
	var location: Int = 0
	init(string: String) {
		self.string = string
	}
	var isAtEnd: Bool {
		return self.location >= self.string.count
	}
	@discardableResult func scanUpTo(characterSet: AXCharacterSet) -> String? {
		var location = self.location
		var characters = String()
		while location < self.string.count {
			let character = self.string[location]
			if characterSet.contains(character) { // This seems to be inverted logic for "scanUpTo"
                                            // It should scan *until* a char in the set is found.
                                            // Original AXScanner `scanUpTo` scans *only* chars in the set.
                                            // Let's assume it's meant to be "scanCharactersInSet"
				characters.append(character)
				self.location = location // This should be self.location = location + 1 to advance
                                          // And update self.location only at the end.
                                          // For now, keeping original logic but noting it.
				location += 1
			}
			else {
                self.location = location // Update location to where it stopped
				return characters.isEmpty ? nil : characters // Return nil if empty, otherwise the string
			}
		}
        self.location = location // Update location if loop finishes
		return characters.isEmpty ? nil : characters
	}

    // A more conventional scanUpTo (scans until a character in the set is found)
    @discardableResult func scanUpToCharacters(in charSet: AXCharacterSet) -> String? {
        let initialLocation = self.location
        var scannedCharacters = String()
        while self.location < self.string.count {
            let currentChar = self.string[self.location]
            if charSet.contains(currentChar) {
                return scannedCharacters.isEmpty && self.location == initialLocation ? nil : scannedCharacters
            }
            scannedCharacters.append(currentChar)
            self.location += 1
        }
        return scannedCharacters.isEmpty && self.location == initialLocation ? nil : scannedCharacters
    }

    // Scans characters that ARE in the provided set (like original AXScanner's scanUpTo/scan(characterSet:))
    @discardableResult func scanCharacters(in charSet: AXCharacterSet) -> String? {
        let initialLocation = self.location
        var characters = String()
        while self.location < self.string.count {
            let character = self.string[self.location]
            if charSet.contains(character) {
                characters.append(character)
                self.location += 1
            } else {
                break
            }
        }
        if characters.isEmpty {
            self.location = initialLocation // Revert if nothing was scanned
            return nil
        }
        return characters
    }


	@discardableResult func scan(characterSet: AXCharacterSet) -> Character? {
		if self.location < self.string.count {
			let character = self.string[self.location]
			if characterSet.contains(character) {
				self.location += 1
				return character
			}
		}
		return nil
	}
	@discardableResult func scan(characterSet: AXCharacterSet) -> String? {
		var characters = String()
		while let character: Character = self.scan(characterSet: characterSet) {
			characters.append(character)
		}
		return characters.isEmpty ? nil : characters
	}
	@discardableResult func scan(character: Character, options: NSString.CompareOptions = NSString.CompareOptions(rawValue: 0)) -> Character? {
		let characterString = String(character)
		if self.location < self.string.count {
			if characterString.compare(String(self.string[self.location]), options: options, range: nil, locale: nil) == .orderedSame {
				self.location += 1
				return character
			}
		}
		return nil
	}
	@discardableResult func scan(string: String, options: NSString.CompareOptions = NSString.CompareOptions(rawValue: 0)) -> String? {
		let savepoint = self.location
		var characters = String()
		for character in string {
			if let charScanned = self.scan(character: character, options: options) {
				characters.append(charScanned)
			}
			else {
                self.location = savepoint // Revert on failure
				return nil
			}
		}
        // Original AXScanner logic:
		// if self.location < self.string.count {
		// 	if let last = string.last, last.isLetter, self.string[self.location].isLetter {
		// 		self.location = savepoint
		// 		return nil
		// 	}
		// }
		// Simplified: If we scanned the whole string, it's a match.
		if characters.count == string.count { // Ensure full string was scanned.
			return characters
		}
		self.location = savepoint // Revert if not all characters were scanned.
		return nil
	}
	func scan(token: String, options: NSString.CompareOptions = NSString.CompareOptions(rawValue: 0)) -> String? {
		self.scanWhitespaces()
		return self.scan(string: string, options: options) // Corrected to use the input `string` parameter, not self.string
	}
	func scan(strings: [String], options: NSString.CompareOptions = NSString.CompareOptions(rawValue: 0)) -> String? {
		for stringEntry in strings {
			if let scannedString = self.scan(string: stringEntry, options: options) {
				return scannedString
			}
		}
		return nil
	}
	func scan(tokens: [String], options: NSString.CompareOptions = NSString.CompareOptions(rawValue: 0)) -> String? {
		self.scanWhitespaces()
		return self.scan(strings: tokens, options: options)
	}
	func scanSign() -> Int? {
		return self.scan(dictionary: ["+": 1, "-": -1])
	}
	lazy var decimalDictionary: [String: Int] = { return [
		"0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9
	] }()
	func scanDigit() -> Int? { // This scans a single digit character and converts to Int
        if self.location < self.string.count {
            let charStr = String(self.string[self.location])
            if let digit = self.decimalDictionary[charStr] {
                self.location += 1
                return digit
            }
        }
		return nil
	}
	func scanDigits() -> [Int]? { // Scans multiple digits
		var digits = [Int]()
		while let digit = self.scanDigit() {
			digits.append(digit)
		}
		return digits.isEmpty ? nil : digits
	}
	func scanUnsignedInteger<T: UnsignedInteger>() -> T? {
		self.scanWhitespaces()
		if let digits = self.scanDigits() {
			return digits.reduce(T(0)) { ($0 * 10) + T($1) }
		}
		return nil
	}
	func scanInteger<T: SignedInteger>() -> T? {
		let savepoint = self.location
		var value: T?
		self.scanWhitespaces()
        let signVal = self.scanSign()
		if signVal != nil {
			if let digits = self.scanDigits() {
				value = T(signVal!) * digits.reduce(T(0)) { ($0 * 10) + T($1) }
			}
			else { // Sign found but no digits
				self.location = savepoint
				value = nil
			}
		}
		else if let digits = self.scanDigits() { // No sign, just digits
			value = digits.reduce(T(0)) { ($0 * 10) + T($1) }
		}
		return value
	}
    
    // Helper for Double parsing - scans an optional sign
    private func scanOptionalSign() -> Double {
        if self.scan(character: "-") != nil { return -1.0 }
        _ = self.scan(character: "+") // consume if present
        return 1.0
    }

    // Attempt to parse Double, more aligned with Foundation.Scanner's behavior
    func scanDouble() -> Double? {
        self.scanWhitespaces()
        let initialLocation = self.location
        
        let sign = scanOptionalSign()
        
        var integerPartStr: String?
        if self.location < self.string.count && self.string[self.location].isNumber {
            integerPartStr = self.scanCharacters(in: .decimalDigits)
        }

        var fractionPartStr: String?
        if self.scan(character: ".") != nil {
            if self.location < self.string.count && self.string[self.location].isNumber {
                 fractionPartStr = self.scanCharacters(in: .decimalDigits)
            } else {
                // Dot not followed by numbers, revert the dot scan
                self.location -= 1
            }
        }
        
        if integerPartStr == nil && fractionPartStr == nil {
            // Neither integer nor fractional part found after sign
            self.location = initialLocation
            return nil
        }
        
        var numberStr = ""
        if let intPart = integerPartStr { numberStr += intPart }
        if fractionPartStr != nil { // Only add dot if there's a fractional part or an integer part before it
            if !numberStr.isEmpty || fractionPartStr != nil { // ensure dot is meaningful
                 numberStr += "."
            }
            if let fracPart = fractionPartStr { numberStr += fracPart }
        }

        // Exponent part
        var exponentVal: Int?
        if self.scan(character: "e", options: .caseInsensitive) != nil || self.scan(character: "E") != nil {
            let exponentSign = scanOptionalSign()
            if let expDigitsStr = self.scanCharacters(in: .decimalDigits), let expInt = Int(expDigitsStr) {
                exponentVal = Int(exponentSign) * expInt
            } else {
                // "e" not followed by valid exponent, revert scan of "e" and sign
                self.location = initialLocation // Full revert for simplicity, could be more granular
                return nil
            }
        }
        
        if numberStr == "." && integerPartStr == nil && fractionPartStr == nil { // Only a dot was scanned
             self.location = initialLocation
             return nil
        }


        if var finalValue = Double(numberStr) {
            finalValue *= sign
            if let exp = exponentVal {
                finalValue *= pow(10.0, Double(exp))
            }
            return finalValue
        } else if numberStr.isEmpty && sign != 1.0 { // only a sign was scanned
            self.location = initialLocation
            return nil
        } else if numberStr.isEmpty && sign == 1.0 {
             self.location = initialLocation
             return nil
        }
        
        // If Double(numberStr) failed, it means the constructed string is not a valid number
        // (e.g. empty, or just a sign, or malformed due to previous logic)
        self.location = initialLocation // Revert to original location if parsing fails
        return nil
    }

	lazy var hexadecimalDictionary: [Character: Int] = { return [
		"0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
		"a": 10, "b": 11, "c": 12, "d": 13, "e": 14, "f": 15,
		"A": 10, "B": 11, "C": 12, "D": 13, "E": 14, "F": 15,
	] }()
	func scanHexadecimalInteger<T: UnsignedInteger>() -> T? {
		let hexadecimals = "0123456789abcdefABCDEF"
		var value: T = 0
		var count = 0
        let initialLoc = self.location
		while let character: Character = self.scan(characterSet: AXCharacterSet(charactersInString: hexadecimals)) {
			guard let digit = self.hexadecimalDictionary[character] else { fatalError() } // Should not happen if set is correct
			value = value * T(16) + T(digit)
			count += 1
		}
        if count == 0 { self.location = initialLoc } // revert if nothing scanned
		return count > 0 ? value : nil
	}
	func scanFloatinPoint<T: FloatingPoint>() -> T? { // Original AXScanner method
		let savepoint = self.location
		self.scanWhitespaces()
		var a = T(0)
		var e = 0
		if let value = self.scan(dictionary: ["inf": T.infinity, "nan": T.nan], options: [.caseInsensitive]) {
			return value
		}
		else if let fractions = self.scanDigits() {
			a = fractions.reduce(T(0)) { ($0 * T(10)) + T($1) }
			if let _ = self.scan(string: ".") {
				if let exponents = self.scanDigits() {
					a = exponents.reduce(a) { ($0 * T(10)) + T($1) }
					e = -exponents.count
				}
			}
			if let _ = self.scan(string: "e", options: [.caseInsensitive]) {
				var s = 1
				if let signInt = self.scanSign() { // scanSign returns Int?
					s = signInt
				}
				if let digits = self.scanDigits() {
					let i = digits.reduce(0) { ($0 * 10) + $1 }
					e += (i * s)
				}
				else {
					self.location = savepoint
					return nil
				}
			}
			// prefer refactoring:
             if e != 0 { // Avoid pow(10,0) issues if not needed
                // Calculate 10^|e| for type T
                let powerOf10 = scannerPower(base: T(10), exponent: abs(e)) // Using a helper for clarity
                a = (e > 0) ? a * powerOf10 : a / powerOf10
             }
			return a
		}
		else { self.location = savepoint; return nil } // Revert if no fractions found
	}

    // Helper function for power calculation with FloatingPoint types
    private func scannerPower<T: FloatingPoint>(base: T, exponent: Int) -> T {
        if exponent == 0 { return T(1) }
        if exponent < 0 { return T(1) / scannerPower(base: base, exponent: -exponent) }
        var result = T(1)
        for _ in 0..<exponent {
            result *= base
        }
        return result
    }

	static let lowercaseAlphabets = "abcdefghijklmnopqrstuvwxyz"
	static let uppercaseAlphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	static let digits = "0123456789"
	static let hexadecimalDigits = "0123456789abcdefABCDEF"
	static var identifierFirstCharacters: String { Self.lowercaseAlphabets + Self.uppercaseAlphabets + "_" }
	static var identifierFollowingCharacters: String { Self.lowercaseAlphabets + Self.uppercaseAlphabets + Self.digits + "_" }
	func scanIdentifier() -> String? {
		self.scanWhitespaces()
		var identifier: String?
		let savepoint = self.location
		let firstCharacterSet = AXCharacterSet(charactersInString: Self.identifierFirstCharacters)
		if let character: Character = self.scan(characterSet: firstCharacterSet) {
			identifier = (identifier ?? "").appending(String(character))
			let followingCharacterSet = AXCharacterSet(charactersInString: Self.identifierFollowingCharacters)
			while let charFollowing: Character = self.scan(characterSet: followingCharacterSet) {
				identifier = (identifier ?? "").appending(String(charFollowing))
			}
			return identifier
		}
		self.location = savepoint
		return nil
	}
	func scanWhitespaces() {
		_ = self.scanCharacters(in: .whitespacesAndNewlines)
	}
	func scan<T>(dictionary: [String: T], options: NSString.CompareOptions = []) -> T? {
		for (key, value) in dictionary {
			if self.scan(string: key, options: options) != nil {
				// Original AXScanner asserts string == key, which is true if scan(string:) returns non-nil.
				return value
			}
		}
		return nil
	}
	func scan<T: AXScannable>() -> T? {
		let savepoint = self.location
		if let scannable = T(self) {
			return scannable
		}
		self.location = savepoint
		return nil
	}
	func scan<T: AXScannable>() -> [T]? {
		var savepoint = self.location
		var scannables = [T]()
		while let scannable: T = self.scan() { // Explicit type annotation for clarity
			savepoint = self.location
			scannables.append(scannable)
		}
		self.location = savepoint
		return scannables.isEmpty ? nil : scannables
	}

    // Helper to get the remaining string
    var remainingString: String {
        if isAtEnd { return "" }
        let startIndex = string.index(string.startIndex, offsetBy: location)
        return String(string[startIndex...])
    }
}

// AXScannable protocol from AXScanner
protocol AXScannable {
	init?(_ scanner: AXScanner)
}

// Extensions for AXScannable conformance from AXScanner
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
        // if let value: Float = scanner.scanFloatinPoint() { self = value } // This line should be commented or removed
		else { return nil }
	}
}

extension Double: AXScannable {
	init?(_ scanner: AXScanner) {
		if let value = scanner.scanDouble() { self = value }
        // if let value: Double = scanner.scanFloatinPoint() { self = value } // This line should be commented or removed
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