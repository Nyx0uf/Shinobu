import Foundation

extension Int {
	func KB() -> Int {
		self * 1024
	}

	func MB() -> Int {
		self * 1048576
	}
}

// MARK: - Clamp
public func clamp<T: Comparable>(_ value: T, lower: T, upper: T) -> T {
	max(min(value, upper), lower)
}
