import UIKit
import Foundation


final class ProcessCoverOperation: Operation
{
	// MARK: - Public properties
	// Image data
	var data: Data? = nil
	// Custom completion block
	var callback: ((UIImage, UIImage) -> Void)? = nil

	// MARK: - Private properties
	// Album
	private let album: Album
	// Size of the thumbnail to create
	private let cropSize: CGSize
	// Should save thumbnail flag
	private var save = true

	// MARK: - Initializers
	init(album: Album, cropSize: CGSize, save: Bool)
	{
		self.album = album
		self.cropSize = cropSize
		self.save = save
	}

	// MARK: - Override
	override func main()
	{
		// Operation is cancelled, abort
		if isCancelled
		{
			Logger.shared.log(type: .information, message: "Operation cancelled for <\(album.name)>")
			return
		}

		guard let imageData = data else
		{
			Logger.shared.log(type: .error, message: "No data <\(album.name)>")
			return
		}

		guard let cover = UIImage(data: imageData) else
		{
			Logger.shared.log(type: .error, message: "Invalid cover data for <\(album.name)> (\(imageData.count)b)")
			return
		}

		guard let thumbnail = cover.smartCropped(toSize: cropSize) else
		{
			Logger.shared.log(type: .error, message: "Failed to create thumbnail for <\(album.name)>")
			return
		}

		guard let saveURL = album.localCoverURL else
		{
			Logger.shared.log(type: .error, message: "Invalid cover url for <\(album.name)>")
			return
		}

		if save
		{
			if thumbnail.save(url: saveURL) == false
			{
				Logger.shared.log(type: .error, message: "Failed to save cover for <\(album.name)>")
			}
		}

		if let block = callback
		{
			block(cover, thumbnail)
		}
	}

	override var description: String
	{
		return "ProcessCoverOperation for <\(album.name)>"
	}
}
