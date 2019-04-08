import Foundation


extension Int
{
	func KB() -> Int
	{
		return self * 1024
	}

	func MB() -> Int
	{
		return self * 1024 * 1024
	}
}

// MARK: - Clamp
public func clamp<T: Comparable>(_ value: T, lower: T, upper: T) -> T
{
	return max(min(value, upper), lower)
}
