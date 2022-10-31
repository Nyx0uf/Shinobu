import Foundation

final class Cache<Key: Hashable, Value> {
	private let wrapped = NSCache<WrappedKey, Entry>()

	var countLimit: Int = 100 {
		didSet {
			wrapped.countLimit = countLimit
		}
	}

	func insert(_ value: Value, forKey key: Key) {
		wrapped.setObject(Entry(value), forKey: WrappedKey(key))
	}

	func value(forKey key: Key) -> Value? {
		let entry = wrapped.object(forKey: WrappedKey(key))
		return entry?.value
	}

	func removeValue(forKey key: Key) {
		wrapped.removeObject(forKey: WrappedKey(key))
	}

	func removeAllValues() {
		wrapped.removeAllObjects()
	}
}

extension Cache {
	subscript(key: Key) -> Value? {
		get { return value(forKey: key) }
		set {
			guard let value = newValue else {
				removeValue(forKey: key)
				return
			}

			insert(value, forKey: key)
		}
	}
}

private extension Cache {
	final class WrappedKey: NSObject {
		let key: Key

		init(_ key: Key) {
			self.key = key
		}

		override var hash: Int {
			return key.hashValue
		}

		override func isEqual(_ object: Any?) -> Bool {
			guard let value = object as? WrappedKey else {
				return false
			}

			return value.key == key
		}
	}
}

private extension Cache {
	final class Entry {
		let value: Value

		init(_ value: Value) {
			self.value = value
		}
	}
}
