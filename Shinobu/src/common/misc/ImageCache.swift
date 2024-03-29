import UIKit
import Defaults
import Logging

final class ImageCache {
	// MARK: - Public properties
	/// Singletion instance
	static let shared = ImageCache()

	// MARK: - Private properties
	/// Cache
	private let cache: Cache<String, UIImage>
	/// Logger
	private let logger = Logger(label: "logger.imagecache")

	// MARK: - Initializers
	init() {
		self.cache = Cache<String, UIImage>()
		self.cache.countLimit = 60
		// URL cache
		URLCache.shared = URLCache(memoryCapacity: 4.MB, diskCapacity: 32.MB, diskPath: nil)
	}

	// MARK: - Public
	func clear(_ callback: ((_ success: Bool) -> Void)?) {
		var success = true

		defer {
			callback?(success)
		}

		let cachesDirectoryURL = FileManager.default.cachesDirectory()
		let coversDirectoryURL = cachesDirectoryURL.appendingPathComponent(Defaults[.coversDirectory])

		do {
			try FileManager.default.removeItem(at: coversDirectoryURL)
			try FileManager.default.createDirectory(at: coversDirectoryURL, withIntermediateDirectories: true, attributes: nil)
			URLCache.shared.removeAllCachedResponses()
			cache.removeAllValues()
		} catch _ {
			logger.info("Can't delete cover cache")
			success = false
		}
	}

	// MARK: - Subscripting
	subscript(key: String) -> UIImage? {
		get {
			cache[key]
		}
		set {
			cache[key] = newValue
		}
	}
}
