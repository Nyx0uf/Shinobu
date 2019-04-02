import UIKit


protocol MusicalCollectionDataSourceAndDelegateDelegate : class
{
	func isSearching(actively: Bool) -> Bool
	func didSelectItem(indexPath: IndexPath)
	func coverDownloaded(_ cover: UIImage?, forItemAtIndexPath indexPath: IndexPath)
}


final class MusicalCollectionDataSourceAndDelegate : NSObject
{
	// MARK: - Public Properties
	// Original data source
	private(set) var items = [MusicalEntity]()
	// Only search results
	private(set) var searchResults = [MusicalEntity]()
	// Type of entity in the data source
	var musicalEntityType = MusicalEntityType.albums
	// Currenlty searching flag
	var searching = false
	// Delegate
	weak var delegate: MusicalCollectionDataSourceAndDelegateDelegate!
	// Return the correct items
	var actualItems: [MusicalEntity]
	{
		get
		{
			return searching ? searchResults : items
		}
	}

	// MARK: - Private Properties
	// Cover download operations
	private var downloadOperations = [String : Operation]()
	// MPD Data source
	private let mpdDataSource: MPDDataSource
	// MPD servers manager
	private let serversManager: ServersManager

	// MARK: - Initializers
	init(type: MusicalEntityType, delegate: MusicalCollectionDataSourceAndDelegateDelegate, mpdDataSource: MPDDataSource)
	{
		self.mpdDataSource = mpdDataSource
		self.musicalEntityType = type
		self.delegate = delegate
		self.serversManager = ServersManager()
	}

	// MARK: - Public
	func setItems(_ items: [MusicalEntity], forType type: MusicalEntityType)
	{
		self.items = items
		self.musicalEntityType = type
	}

	func setSearchResults(_ searchResults: [MusicalEntity])
	{
		self.searchResults = searchResults
	}

	// MARK: - Private
	private func downloadCoverForAlbum(_ album: Album, cropSize: CGSize, callback:((_ cover: UIImage, _ thumbnail: UIImage) -> Void)?) -> CoverOperation
	{
		let key = album.uniqueIdentifier
		if let cop = downloadOperations[key] as! CoverOperation?
		{
			return cop
		}
		let downloadOperation = CoverOperation(album: album, cropSize: cropSize)
		weak var weakOperation = downloadOperation
		downloadOperation.callback = {(cover: UIImage, thumbnail: UIImage) in
			if let _ = weakOperation
			{
				self.downloadOperations.removeValue(forKey: key)
			}
			if let block = callback
			{
				block(cover, thumbnail)
			}
		}
		downloadOperations[key] = downloadOperation

		OperationManager.shared.addOperation(downloadOperation)

		return downloadOperation
	}
}

extension MusicalCollectionDataSourceAndDelegate : UICollectionViewDataSource
{
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		if delegate == nil
		{
			return 0
		}

		let count = actualItems.count
		return count >= 9 ? count + 3 : count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: musicalEntityType.cellIdentifier(), for: indexPath) as! MusicalEntityBaseCell

		// Dummy cells
		let entities = self.actualItems
		if indexPath.row == entities.count || indexPath.row == entities.count + 1 || indexPath.row == entities.count + 2
		{
			cell.label.text = ""
			cell.imageView.backgroundColor = collectionView.backgroundColor
			cell.image = nil
			return cell
		}

		cell.type = musicalEntityType
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.main.scale
		cell.label.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		cell.label.backgroundColor = collectionView.backgroundColor
		cell.imageView.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)

		let entity = entities[indexPath.row]
		// Init cell
		cell.label.text = entity.name
		cell.accessibilityLabel = entity.name
		cell.image = nil
		switch musicalEntityType
		{
			case .albums:
				handleCoverForCell(cell, at: indexPath, withAlbum: entity as! Album)
			case .artists, .albumsartists:
				cell.image = #imageLiteral(resourceName: "img-artists").tinted(withColor: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1))
			case .genres:
				let string = entity.name[0..<2].uppercased()
				let backgroundColor = UIColor(rgb: string.djb2())
				cell.image = UIImage.fromString(string, font: UIFont(name: "Chalkduster", size: cell.imageView.size.width / 4.0)!, fontColor: backgroundColor.inverted(), backgroundColor: backgroundColor, maxSize: cell.imageView.size)
			case .playlists:
				let string = entity.name
				let backgroundColor = UIColor(rgb: string.djb2())
				cell.image = UIImage.fromString(string, font: UIFont(name: "Chalkduster", size: cell.imageView.size.width / 4.0)!, fontColor: backgroundColor.inverted(), backgroundColor: backgroundColor, maxSize: cell.imageView.size)
			default:
				break
		}

		return cell
	}

	private func handleCoverForCell(_ cell: MusicalEntityBaseCell, at indexPath: IndexPath, withAlbum album: Album)
	{
		// If image is in cache, bail out quickly
		if let cachedImage = ImageCache.shared[album.uniqueIdentifier]
		{
			cell.image = cachedImage
			return
		}

		// Get local URL for cover
		guard let _ = serversManager.getSelectedServer()?.covers else { return }
		guard let coverURL = album.localCoverURL else
		{
			Logger.shared.log(type: .error, message: "No cover file URL for \(album)") // should not happen
			return
		}

		if let cover = UIImage.loadFromFileURL(coverURL)
		{
			cell.image = cover
			ImageCache.shared[album.uniqueIdentifier] = cover
		}
		else
		{
			if let op = cell.associatedObject as! CoverOperation?
			{
				Logger.shared.log(type: .information, message: "canceling \(op)")
				op.cancel()
			}

			if delegate.isSearching(actively: true)
			{
				return
			}

			let sizeAsData = Settings.shared.data(forKey: .coversSize)!
			let cropSize = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSValue.self], from: sizeAsData) as? NSValue
			if album.path != nil
			{
				cell.associatedObject = downloadCoverForAlbum(album, cropSize: (cropSize?.cgSizeValue)!) { (cover: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						self.delegate.coverDownloaded(thumbnail, forItemAtIndexPath: indexPath)
					}
				}
			}
			else
			{
				mpdDataSource.getPathForAlbum(album) {
					cell.associatedObject = self.downloadCoverForAlbum(album, cropSize: (cropSize?.cgSizeValue)!) { (cover: UIImage, thumbnail: UIImage) in
						DispatchQueue.main.async {
							self.delegate.coverDownloaded(thumbnail, forItemAtIndexPath: indexPath)
						}
					}
				}
			}
		}
	}
}

// MARK: - UICollectionViewDelegate
extension MusicalCollectionDataSourceAndDelegate : UICollectionViewDelegate
{
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		delegate.didSelectItem(indexPath: indexPath)
	}
}
