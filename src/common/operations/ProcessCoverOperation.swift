import UIKit
import Foundation

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

	// MARK: - Initializers
	init(album: Album, cropSizes: [AssetSize: CGSize]) {
		self.album = album
		self.cropSizes = cropSizes
	}

	// MARK: - Override
	override func main() {
		// Operation is cancelled, abort
		if isCancelled {
			Logger.shared.log(type: .information, message: "Operation cancelled for <\(album.name)>")
			return
		}

		guard let imageData = data else {
			Logger.shared.log(type: .error, message: "No data <\(album.name)>")
			return
		}

		guard let cover = UIImage(data: imageData) else {
			Logger.shared.log(type: .error, message: "Invalid cover data for <\(album.name)> (\(imageData.count)b)")
			return
		}

		var images = [AssetSize: UIImage?]()
		for (assetSize, cropSize) in cropSizes {
			let cropped = cover.smartCropped(toSize: cropSize, highQuality: false, screenScale: true)
			if let thumbnail = cropped {
				if thumbnail.save(url: album.localCoverURL.appendingPathComponent(assetSize.rawValue + ".jpg")) == false {
					Logger.shared.log(type: .error, message: "Failed to save cover for <\(album.name)>")
				}
			}
			images[assetSize] = cropped
		}

		if let block = callback {
			block(images[.large] ?? nil, images[.medium] ?? nil, images[.small] ?? nil)
		}
	}

	override var description: String {
		"ProcessCoverOperation for <\(album.name)>"
	}
}
