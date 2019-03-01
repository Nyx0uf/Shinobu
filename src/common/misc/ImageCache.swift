import UIKit


final class ImageCache
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = ImageCache()

	// MARK: - Private properties
	private let _cache: NSCache<AnyObject, UIImage>

	// MARK: - Initializers
	init()
	{
		self._cache = NSCache()
		self._cache.countLimit = 100
	}

	// MARK: - Subscripting
	subscript(key: String) -> UIImage?
	{
		get
		{
			return _cache.object(forKey: key as AnyObject)
		}
		set (newValue)
		{
			if let img = newValue
			{
				_cache.setObject(img, forKey: key as AnyObject)
			}
		}
	}
}
