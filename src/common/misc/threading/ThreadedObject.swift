import Foundation

public class ThreadedObject<V> {
	// MARK: - Private properties
	// Object
	private var value: V
	// Concurrent queue
	private var queue: DispatchQueue

	init(_ value: V) {
		self.value = value
		self.queue = DispatchQueue(label: ThreadedQueueLabel.get(), attributes: .concurrent)
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

private final class ThreadedQueueLabel {
	private static var nextId = 0

	internal static func get() -> String {
		let id = nextId
		nextId += 1
		return "fr.whine.shinobu.queue.threadedobject_\(id)"
	}
}
