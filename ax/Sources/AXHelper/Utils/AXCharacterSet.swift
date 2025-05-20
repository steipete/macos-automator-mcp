import Foundation

// AXCharacterSet struct from AXScanner
public struct AXCharacterSet {
	private var characters: Set<Character>
	public init(characters: Set<Character>) {
		self.characters = characters
	}
	public init(charactersInString: String) {
		self.characters = Set(charactersInString.map { $0 })
	}
	public func contains(_ character: Character) -> Bool {
		return self.characters.contains(character)
	}
	public mutating func add(_ characters: Set<Character>) {
		self.characters.formUnion(characters)
	}
	public func adding(_ characters: Set<Character>) -> AXCharacterSet {
		return AXCharacterSet(characters: self.characters.union(characters))
	}
	public mutating func remove(_ characters: Set<Character>) {
		self.characters.subtract(characters)
	}
	public func removing(_ characters: Set<Character>) -> AXCharacterSet   {
		return AXCharacterSet(characters: self.characters.subtracting(characters))
	}

    // Add some common character sets that might be useful, similar to Foundation.CharacterSet
    public static var whitespacesAndNewlines: AXCharacterSet {
        return AXCharacterSet(charactersInString: " \t\n\r")
    }
    public static var decimalDigits: AXCharacterSet {
        return AXCharacterSet(charactersInString: "0123456789")
    }
    public static func punctuationAndSymbols() -> AXCharacterSet { // Example
        // This would need a more comprehensive list based on actual needs
        return AXCharacterSet(charactersInString: ".,:;?!()[]{}-_=+") // Simplified set
    }
    public static func characters(in string: String) -> AXCharacterSet {
        return AXCharacterSet(charactersInString: string)
    }
} 