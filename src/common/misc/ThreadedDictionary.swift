import Foundation

final class ThreadedDictionary<K: Hashable, V>: ThreadedObject<[K: V]> {
	// MARK: - Initializers
	public override init(_ dictionary: [K: V]) {
		super.init(dictionary)
	}

	public convenience init() {
		self.init([K: V]())
	}

	// MARK: - Subscripting
	public subscript(key: K) -> V? {
		get {
			return sync { (collection) in
				return collection[key]
			}
		}
		set {
			async { (collection) in
				collection[key] = newValue
			}
		}
	}

	// MARK: - Public
	public var keys: Dictionary<K, V>.Keys {
		return sync { (collection) in
			return collection.keys
		}
	}

	public var values: Dictionary<K, V>.Values {
		return sync { (collection) in
			return collection.values
		}
	}

	public func removeValue(forKey key: K) {
		return async { (collection) in
			collection.removeValue(forKey: key)
		}
	}
}

extension ThreadedDictionary: Collection {
	public subscript(position: Dictionary<K, V>.Index) -> Dictionary<K, V>.Element {
		return sync { (collection) in
			return collection[position]
		}
	}

	public func index(after i: Dictionary<K, V>.Index) -> Dictionary<K, V>.Index {
		return sync { (collection) in
			return collection.index(after: i)
		}
	}

	public var startIndex: Dictionary<K, V>.Index {
		return sync { (collection) in
			return collection.startIndex
		}
	}

	public var endIndex: Dictionary<K, V>.Index {
		return sync { (collection) in
			return collection.endIndex
		}
	}
}

public class ThreadedObject<V> {
	// MARK: - Private properties
	// Object
	private var value: V
	// Concurrent queue
	private var queue: DispatchQueue

	init(_ value: V) {
		self.value = value
		self.queue = DispatchQueue(label: "fr.whine.shinobu.queue.threadedobject", attributes: .concurrent)
	}

	func async(_ callback: @escaping (inout V) -> Void) {
		queue.async(flags: .barrier) { callback(&self.value) }
	}

	func sync<R>(_ callback: @escaping (V) -> R) -> R {
		return queue.sync { return callback(self.value) }
	}

	public func mutatingSync<R>(_ callback: @escaping (inout V) -> R) -> R {
		return queue.sync(flags: .barrier) {
			return callback(&self.value)
		}
	}
}
