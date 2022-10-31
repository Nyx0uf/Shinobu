import Foundation

final class ThreadedArray<T>: ThreadedObject<[T]> {
	public override init(_ array: [T]) {
		super.init(array)
	}

	public convenience init() {
		self.init([T]())
	}

	public func append(_ newElement: Array<T>.Element) {
		async { collection in
			collection.append(newElement)
		}
	}

	public func append<S: Sequence>(contentsOf sequence: S) where S.Element == Array<T>.Element {
		async { collection in
			collection.append(contentsOf: sequence)
		}
	}

	public func remove(at index: Array<T>.Index, callback: ((Array<T>.Element) -> Void)? = nil) {
		async { collection in
			let value = collection.remove(at: index)
			if let function = callback {
				DispatchQueue.main.async {
					function(value)
				}
			}
		}
	}

	public func removeFirst(callback: ((Array<T>.Element) -> Void)? = nil) {
		async { collection in
			let value = collection.removeFirst()
			if let function = callback {
				DispatchQueue.main.async {
					function(value)
				}
			}
		}
	}

	public func removeLast(callback: ((Array<T>.Element) -> Void)? = nil) {
		async { collection in
			let value = collection.removeLast()
			if let function = callback {
				DispatchQueue.main.async {
					function(value)
				}
			}
		}
	}
}

extension ThreadedArray: MutableCollection, RandomAccessCollection {
	public var startIndex: Int {
		return sync { collection in
			return collection.startIndex
		}
	}

	public var endIndex: Int {
		return sync { collection in
			return collection.endIndex
		}
	}

	public subscript(position: Int) -> Array<T>.Element {
		get {
			return sync { collection in
				return collection[position]
			}
		}
		set {
			async { collection in
				collection[position] = newValue
			}
		}
	}

	public func index(after i: Array<T>.Index) -> Array<T>.Index {
		return sync { collection in
			return collection.index(after: i)
		}
	}
}
