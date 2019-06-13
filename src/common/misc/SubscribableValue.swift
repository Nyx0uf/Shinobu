import Foundation

struct SubscribableValue<T> {
	fileprivate struct Weak<Object: AnyObject> {
		weak var value: Object?
	}

	// MARK: - Public properties
	var value: T

	// MARK: - Private properties
	private typealias Subscription = (object: Weak<AnyObject>, handler: (T) -> Void)
	private var subscriptions: [Subscription] = []

	// MARK: - Initializers
	init(value: T) {
		self.value = value
	}

	// MARK: - Public
	func notify() {
		for (object, handler) in subscriptions where object.value != nil {
			handler(value)
		}
	}

	mutating func subscribe(_ object: AnyObject, using handler: @escaping (T) -> Void) {
		subscriptions.append((Weak(value: object), handler))
		cleanupSubscriptions()
	}

	// MARK: - Private
	private mutating func cleanupSubscriptions() {
		subscriptions = subscriptions.filter({ (entry) in
			return entry.object.value != nil
		})
	}
}
