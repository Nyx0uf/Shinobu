import UIKit


final class ImageCache
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = ImageCache()

	// MARK: - Private properties
	private let cache: NSCache<AnyObject, UIImage>

	// MARK: - Initializers
	init()
	{
		self.cache = NSCache()
		self.cache.countLimit = 100
	}

	// MARK: - Subscripting
	subscript(key: String) -> UIImage?
	{
		get
		{
			return cache.object(forKey: key as AnyObject)
		}
		set (newValue)
		{
			if let img = newValue
			{
				cache.setObject(img, forKey: key as AnyObject)
			}
		}
	}
}
