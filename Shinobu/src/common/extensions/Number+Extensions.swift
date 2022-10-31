import Foundation

extension Int {
	var KB: Int { self * 1024 }

	var MB: Int { self * 1048576 }
}

// MARK: - Clamp
public func clamp<T: Comparable>(_ value: T, lower: T, upper: T) -> T {
	max(min(value, upper), lower)
}
