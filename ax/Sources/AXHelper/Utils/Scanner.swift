// Scanner.swift - Custom scanner implementation (Scanner)

import Foundation

// String extension MOVED to String+HelperExtensions.swift
// CustomCharacterSet struct MOVED to CustomCharacterSet.swift

// Scanner class from Scanner
class Scanner {

	// MARK: - Properties and Initialization
	let string: String
	var location: Int = 0
	init(string: String) {
		self.string = string
	}
	var isAtEnd: Bool {
		return self.location >= self.string.count
	}

    // MARK: - Character Set Scanning
    // A more conventional scanUpTo (scans until a character in the set is found)
    @discardableResult func scanUpToCharacters(in charSet: CustomCharacterSet) -> String? {
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

    // Scans characters that ARE in the provided set (like original Scanner's scanUpTo/scan(characterSet:))
    @discardableResult func scanCharacters(in charSet: CustomCharacterSet) -> String? {
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


	@discardableResult func scan(characterSet: CustomCharacterSet) -> Character? {
		if self.location < self.string.count {
			let character = self.string[self.location]
			if characterSet.contains(character) {
				self.location += 1
				return character
			}
		}
		return nil
	}
	@discardableResult func scan(characterSet: CustomCharacterSet) -> String? {
		var characters = String()
		while let character: Character = self.scan(characterSet: characterSet) {
			characters.append(character)
		}
		return characters.isEmpty ? nil : characters
	}
	// MARK: - Specific Character and String Scanning
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
        // Original Scanner logic:
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
		return self.scan(string: token, options: options) // Corrected: use 'token' parameter
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
	// MARK: - Integer Scanning
	func scanSign() -> Int? {
		return self.scan(dictionary: ["+": 1, "-": -1])
	}
	
	// Private helper that scans and returns a string of digits
	private func scanDigits() -> String? {
		return self.scanCharacters(in: .decimalDigits)
	}
	
	// Calculate integer value from digit string with given base
	private func integerValue<T: BinaryInteger>(from digitString: String, base: T = 10) -> T {
		return digitString.reduce(T(0)) { result, char in
			result * base + T(Int(String(char))!)
		}
	}
	
	func scanUnsignedInteger<T: UnsignedInteger>() -> T? {
		self.scanWhitespaces()
		guard let digitString = self.scanDigits() else { return nil }
		return integerValue(from: digitString)
	}
	
	func scanInteger<T: SignedInteger>() -> T? {
		let savepoint = self.location
		self.scanWhitespaces()
		
		// Parse sign if present
		let sign = self.scanSign() ?? 1
		
		// Parse digits
		guard let digitString = self.scanDigits() else {
			// If we found a sign but no digits, revert and return nil
			if sign != 1 {
				self.location = savepoint
			}
			return nil
		}
		
		// Calculate final value with sign applied
		return T(sign) * integerValue(from: digitString)
	}
    
    // MARK: - Floating Point Scanning
    // Helper for Double parsing - scans an optional sign
    private func scanOptionalSign() -> Double {
        if self.scan(character: "-") != nil { return -1.0 }
        _ = self.scan(character: "+") // consume if present
        return 1.0
    }

    // Helper to scan a sequence of decimal digits
    private func _scanDecimalDigits() -> String? {
        return self.scanCharacters(in: .decimalDigits)
    }

    // Helper to scan the integer part of a double
    private func _scanIntegerPartForDouble() -> String? {
        if self.location < self.string.count && self.string[self.location].isNumber {
            return _scanDecimalDigits()
        }
        return nil
    }

    // Helper to scan the fractional part of a double
    private func _scanFractionalPartForDouble() -> String? {
        let initialDotLocation = self.location
        if self.scan(character: ".") != nil {
            if self.location < self.string.count && self.string[self.location].isNumber {
                 return _scanDecimalDigits()
            } else {
                // Dot not followed by numbers, revert the dot scan
                self.location = initialDotLocation
                return nil // Indicate no fractional part *digits* were scanned after dot
            }
        }
        return nil // No dot found
    }

    // Helper to scan the exponent part of a double
    private func _scanExponentPartForDouble() -> Int? {
        let initialExponentMarkerLocation = self.location
        if self.scan(character: "e", options: .caseInsensitive) != nil { // Also handles "E"
            let exponentSign = scanOptionalSign() // Returns 1.0 or -1.0
            if let expDigitsStr = _scanDecimalDigits(), let expInt = Int(expDigitsStr) {
                return Int(exponentSign) * expInt
            } else {
                // "e" not followed by valid exponent, revert scan of "e" and sign
                // Revert to before "e" was scanned
                self.location = initialExponentMarkerLocation 
                return nil
            }
        }
        return nil // No exponent marker found
    }

    // Attempt to parse Double, more aligned with Foundation.Scanner's behavior
    func scanDouble() -> Double? {
        self.scanWhitespaces()
        let initialLocation = self.location
        
        let sign = scanOptionalSign() // sign is 1.0 or -1.0
        
        let integerPartStr = _scanIntegerPartForDouble()
        let fractionPartStr = _scanFractionalPartForDouble()

        // If no digits were scanned for either integer or fractional part
        if integerPartStr == nil && fractionPartStr == nil {
            self.location = initialLocation // Revert fully, including any sign scan
            return nil
        }
        
        var numberStr = ""
        if let intPart = integerPartStr { numberStr += intPart }
        
        if fractionPartStr != nil {
            numberStr += "." // Add dot if fractional digits were found
            numberStr += fractionPartStr! // Append fractional digits
        }
        
        let exponentVal = _scanExponentPartForDouble()
        
        if numberStr.isEmpty { // Should be covered by the (integerPartStr == nil && fractionPartStr == nil) check earlier
            self.location = initialLocation
            return nil
        }
        if numberStr == "." { // Only a dot was assembled. This should not happen if _scanFractionalPartForDouble works correctly. But as a safeguard:
            self.location = initialLocation
            return nil
        }

        if var finalValue = Double(numberStr) {
            finalValue *= sign
            if let exp = exponentVal {
                finalValue *= pow(10.0, Double(exp))
            }
            return finalValue
        } else {
            // If Double(numberStr) failed, it implies an issue not caught by prior checks
            self.location = initialLocation // Revert to original location if parsing fails
            return nil
        }
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
		while let character: Character = self.scan(characterSet: CustomCharacterSet(charactersInString: hexadecimals)) {
			guard let digit = self.hexadecimalDictionary[character] else { fatalError() } // Should not happen if set is correct
			value = value * T(16) + T(digit)
			count += 1
		}
        if count == 0 { self.location = initialLoc } // revert if nothing scanned
		return count > 0 ? value : nil
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

	// MARK: - Identifier Scanning
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
		let firstCharacterSet = CustomCharacterSet(charactersInString: Self.identifierFirstCharacters)
		if let character: Character = self.scan(characterSet: firstCharacterSet) {
			identifier = (identifier ?? "").appending(String(character))
			let followingCharacterSet = CustomCharacterSet(charactersInString: Self.identifierFollowingCharacters)
			while let charFollowing: Character = self.scan(characterSet: followingCharacterSet) {
				identifier = (identifier ?? "").appending(String(charFollowing))
			}
			return identifier
		}
		self.location = savepoint
		return nil
	}
	// MARK: - Whitespace Scanning
	func scanWhitespaces() {
		_ = self.scanCharacters(in: .whitespacesAndNewlines)
	}
	// MARK: - Dictionary-based Scanning
	func scan<T>(dictionary: [String: T], options: NSString.CompareOptions = []) -> T? {
		for (key, value) in dictionary {
			if self.scan(string: key, options: options) != nil {
				// Original Scanner asserts string == key, which is true if scan(string:) returns non-nil.
				return value
			}
		}
		return nil
	}

    // Helper to get the remaining string
    var remainingString: String {
        if isAtEnd { return "" }
        let startIndex = string.index(string.startIndex, offsetBy: location)
        return String(string[startIndex...])
    }
}