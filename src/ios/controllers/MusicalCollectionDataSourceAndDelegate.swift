import UIKit


protocol MusicalCollectionDataSourceAndDelegateDelegate: class
{
	func isSearching(actively: Bool) -> Bool
	func didSelectEntity(_ entity: AnyObject)
	func coverDownloaded(_ cover: UIImage?, forItemAtIndexPath indexPath: IndexPath)
	func didDisplayCellAtIndexPath(_ indexPath: IndexPath)
}


final class MusicalCollectionDataSourceAndDelegate: NSObject
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
	// Sections
	private(set) var titlesIndex = [String]()
	private(set) var searchTitlesIndex = [String]()

	// MARK: - Private Properties
	// MPD Data source
	private let mpdBridge: MPDBridge
	// MPD servers manager
	private let serversManager: ServersManager
	// Items splitted by section title
	private(set) var orderedItems = [String: [MusicalEntity]]()
	// Items splitted by section title
	private(set) var orderedSearchResults = [String: [MusicalEntity]]()
	// Cover download operations
	private var downloadOperations = ThreadedDictionary<IndexPath, CoverOperations>()
	// Get albums path items
	private var pathsOperation = ThreadedDictionary<IndexPath, DispatchWorkItem>()

	// MARK: - Initializers
	init(type: MusicalEntityType, delegate: MusicalCollectionDataSourceAndDelegateDelegate, mpdBridge: MPDBridge)
	{
		self.mpdBridge = mpdBridge
		self.musicalEntityType = type
		self.delegate = delegate
		self.serversManager = ServersManager()
	}

	// MARK: - Public
	func setItems(_ items: [MusicalEntity], forType type: MusicalEntityType)
	{
		self.items = items
		musicalEntityType = type

		orderedItems.removeAll()
		for item in items
		{
			guard let firstChar = item.name.first else
			{
				continue
			}

			let letter = firstChar.isLetter ? String(firstChar).uppercased() : "#"
			if orderedItems[letter] == nil
			{
				orderedItems[letter] = []
			}

			orderedItems[letter]?.append(item)
		}

		titlesIndex = orderedItems.keys.sorted()
	}

	func setSearchResults(_ searchResults: [MusicalEntity])
	{
		self.searchResults = searchResults

		orderedSearchResults.removeAll()
		for item in searchResults
		{
			guard let firstChar = item.name.first else
			{
				continue
			}

			let letter = firstChar.isLetter ? String(firstChar).uppercased() : "#"
			if orderedSearchResults[letter] == nil
			{
				orderedSearchResults[letter] = []
			}

			orderedSearchResults[letter]?.append(item)
		}

		searchTitlesIndex = orderedSearchResults.keys.sorted()
	}

	func currentItemAtIndexPath(_ indexPath: IndexPath) -> MusicalEntity
	{
		if searching
		{
			let title = searchTitlesIndex[indexPath.section]
			return orderedSearchResults[title]![indexPath.row]
		}
		else
		{
			let title = titlesIndex[indexPath.section]
			return orderedItems[title]![indexPath.row]
		}
	}

	// MARK: - Private
	private func downloadCoverForAlbum(_ album: Album, _ indexPath: IndexPath, cropSize: CGSize, callback: ((_ cover: UIImage, _ thumbnail: UIImage) -> Void)?)
	{
		if let _ = downloadOperations[indexPath]
		{
			return
		}

		var op = CoverOperations(album: album, cropSize: cropSize, saveProcessed: true)
		op.processCallback = { (cover, thumbnail) in
			self.downloadOperations.removeValue(forKey: indexPath)
			if let block = callback
			{
				block(cover, thumbnail)
			}
		}
		downloadOperations[indexPath] = op

		op.submit()
	}

	private func handleCoverForCell(_ cell: MusicalEntityCollectionViewCell, at indexPath: IndexPath, withAlbum album: Album)
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
			if delegate.isSearching(actively: true)
			{
				return
			}

			let sizeAsData = Settings.shared.data(forKey: .coversSize)!
			let cropSize = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSValue.self], from: sizeAsData) as? NSValue
			if album.path != nil
			{
				downloadCoverForAlbum(album, indexPath, cropSize: (cropSize?.cgSizeValue)!) { (cover, thumbnail) in
					DispatchQueue.main.async {
						self.delegate.coverDownloaded(thumbnail, forItemAtIndexPath: indexPath)
					}
				}
			}
			else
			{
				let dwi = mpdBridge.getPathForAlbum2(album) { (success, path) in
					self.pathsOperation.removeValue(forKey: indexPath)
					if success
					{
						self.downloadCoverForAlbum(album, indexPath, cropSize: (cropSize?.cgSizeValue)!) { (cover, thumbnail) in
							DispatchQueue.main.async {
								self.delegate.coverDownloaded(thumbnail, forItemAtIndexPath: indexPath)
							}
						}
					}
				}
				pathsOperation[indexPath] = dwi
			}
		}
	}
}

extension MusicalCollectionDataSourceAndDelegate: UICollectionViewDataSource
{
	func numberOfSections(in collectionView: UICollectionView) -> Int
	{
		return searching ? orderedSearchResults.keys.count : orderedItems.keys.count
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		if searching
		{
			let title = searchTitlesIndex[section]
			return orderedSearchResults[title]?.count ?? 0
		}
		else
		{
			let title = titlesIndex[section]
			return orderedItems[title]?.count ?? 0
		}
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: musicalEntityType.cellIdentifier(), for: indexPath) as! MusicalEntityCollectionViewCell

		let title = searching ? searchTitlesIndex[indexPath.section] : titlesIndex[indexPath.section]
		let entities = searching ? orderedSearchResults[title]! : orderedItems[title]!

		cell.type = musicalEntityType
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.main.scale

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
				cell.image = #imageLiteral(resourceName: "img-artists").tinted(withColor: cell.imageTintColor)
			case .genres:
				let string = entity.name[0..<2].uppercased()
				let backgroundColor = UIColor(rgb: string.djb2())
				cell.image = UIImage.fromString(string, font: UIFont(name: "Chalkduster", size: cell.imageView.size.width / 4)!, fontColor: backgroundColor.inverted(), backgroundColor: backgroundColor, maxSize: cell.imageView.size)
			case .playlists:
				let string = entity.name
				let backgroundColor = UIColor(rgb: string.djb2())
				cell.image = UIImage.fromString(string, font: UIFont(name: "Chalkduster", size: cell.imageView.size.width / 4)!, fontColor: backgroundColor.inverted(), backgroundColor: backgroundColor, maxSize: cell.imageView.size)
			default:
				break
		}

		return cell
	}
}

// MARK: - UICollectionViewDelegate
extension MusicalCollectionDataSourceAndDelegate: UICollectionViewDelegate
{
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		let title = searching ? searchTitlesIndex[indexPath.section] : titlesIndex[indexPath.section]
		let entities = searching ? orderedSearchResults[title]! : orderedItems[title]!
		delegate.didSelectEntity(entities[indexPath.row])
	}

	func scrollViewDidScroll(_ scrollView: UIScrollView)
	{
		let collectionView = scrollView as! UICollectionView
		let layout = collectionView.collectionViewLayout as! MusicalCollectionViewFlowLayout
		if let indexPath = collectionView.indexPathForItem(at: CGPoint(20, scrollView.contentOffset.y + (layout.sectionInset.top + NavigationBarHeight())))
		{
			delegate.didDisplayCellAtIndexPath(indexPath)
		}
	}

	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	{
		// Cancel paths & covers operations
		if let dwi = pathsOperation[indexPath]
		{
			dwi.cancel()
			pathsOperation.removeValue(forKey: indexPath)
		}

		if let operation = downloadOperations[indexPath]
		{
			operation.cancel()
			downloadOperations.removeValue(forKey: indexPath)
		}
	}
}
