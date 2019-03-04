import Foundation
import UIKit


final class NetworkActivityIndicator
{
	// Singletion instance
	static let shared = NetworkActivityIndicator()
	// Queue
	private let _queue: DispatchQueue
	// Number of "operations"
	private var count: Int
	{
		didSet
		{
			DispatchQueue.main.async { [weak self] in
				guard let strongSelf = self else { return }
				UIApplication.shared.isNetworkActivityIndicatorVisible = strongSelf.count > 0
			}
		}
	}

	private init()
	{
		self._queue = DispatchQueue(label: "fr.whine.shinobu.queue.netact", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target: nil)
		self.count = 0
	}

	public func start()
	{
		_queue.sync { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.count += 1
		}
	}

	public func end()
	{
		_queue.sync { [weak self] in
			guard let strongSelf = self else { return }
			var c = strongSelf.count - 1
			if (c < 0)
			{
				c = 0
			}
			strongSelf.count = c
		}
	}

	public func reset()
	{
		_queue.sync { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.count = 0
		}
	}
}
