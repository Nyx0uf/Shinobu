import UIKit

final class ImageCache {
	// MARK: - Public properties
	// Singletion instance
	static let shared = ImageCache()

	// MARK: - Private properties
	private let cache: NSCache<AnyObject, UIImage>

	// MARK: - Initializers
	init() {
		self.cache = NSCache()
		self.cache.countLimit = 60
		// URL cache
		URLCache.shared = URLCache(memoryCapacity: 4.MB(), diskCapacity: 32.MB(), diskPath: nil)
	}

	// MARK: - Public
	func clear(_ callback: ((_ success: Bool) -> Void)?) {
		var success = true

		defer {
			callback?(success)
		}

		guard let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else {
			success = false
			return
		}
		guard let coversDirectoryName = Settings.shared.string(forKey: .coversDirectory) else {
			success = false
			return
		}
		let coversDirectoryURL = cachesDirectoryURL.appendingPathComponent(coversDirectoryName)

		do {
			try FileManager.default.removeItem(at: coversDirectoryURL)
			try FileManager.default.createDirectory(at: coversDirectoryURL, withIntermediateDirectories: true, attributes: nil)
			URLCache.shared.removeAllCachedResponses()
			self.cache.removeAllObjects()
		} catch _ {
			Logger.shared.log(type: .error, message: "Can't delete cover cache")
			success = false
		}
	}

	// MARK: - Subscripting
	subscript(key: String) -> UIImage? {
		get {
			return cache.object(forKey: key as AnyObject)
		}
		set (newValue) {
			if let img = newValue {
				cache.setObject(img, forKey: key as AnyObject)
			}
		}
	}
}
