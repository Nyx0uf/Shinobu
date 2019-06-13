import Foundation

final class CountedObject<T> {
	// MARK: - Public properties
	// Object
	var object: T
	// Count of object
	var count: UInt

	// MARK: - Initializers
	init(object: T, count: UInt) {
		self.object = object
		self.count = count
	}
}
