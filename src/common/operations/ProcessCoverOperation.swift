import UIKit
import Foundation
import Logging

final class ProcessCoverOperation: Operation {
	// MARK: - Public properties
	// Image data
	var data: Data?
	// Custom completion block
	var callback: ((UIImage?, UIImage?, UIImage?) -> Void)?

	// MARK: - Private properties
	// Album
	private let album: Album
	// Size of the thumbnail to create
	private let cropSizes: [AssetSize: CGSize]
	// Logger
	private let logger: Logger

	// MARK: - Initializers
	init(logger: Logger, album: Album, cropSizes: [AssetSize: CGSize]) {
		self.album = album
		self.cropSizes = cropSizes
		self.logger = logger
	}

	// MARK: - Override
	override func main() {
		var images = [AssetSize: UIImage?]()
		defer {
			if let block = callback {
				block(images[.large] ?? nil, images[.medium] ?? nil, images[.small] ?? nil)
			}
		}

		// Operation is cancelled, abort
		if isCancelled {
			logger.info("Operation cancelled for <\(album.name)>")
			return
		}

		guard let imageData = data else {
			logger.error("No data <\(album.name)>")
			return
		}

		guard let cover = UIImage(data: imageData) else {
			logger.error("Invalid cover data for <\(album.name)> (\(imageData.count)b)")
			return
		}

		for (assetSize, cropSize) in cropSizes {
			let cropped = cover.smartCropped(toSize: cropSize, highQuality: false, screenScale: true)
			if let thumbnail = cropped {
				if thumbnail.save(url: album.localCoverURL.appendingPathComponent(assetSize.rawValue + ".jpg")) == false {
					logger.error("Failed to save cover for <\(album.name)>")
				}
			}
			images[assetSize] = cropped
		}
	}

	override var description: String {
		"ProcessCoverOperation for <\(album.name)>"
	}
}
