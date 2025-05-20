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