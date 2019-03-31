import UIKit


protocol MusicalCollectionViewDelegate : class
{
	func isSearching(actively: Bool) -> Bool
	func didSelectItem(indexPath: IndexPath)
}

final class CollectionFlowLayout : UICollectionViewFlowLayout
{
	let sideSpan = CGFloat(10.0)
	let columns = 3

	override init()
	{
		super.init()
		setupLayout()
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	func setupLayout()
	{
		self.itemSize = CGSize(itemWidth(), itemWidth() + 20.0)
		self.sectionInset = UIEdgeInsets(top: sideSpan, left: sideSpan, bottom: sideSpan, right: sideSpan)
		scrollDirection = .vertical
	}

	private func itemWidth() -> CGFloat
	{
		return ceil((UIScreen.main.bounds.width / CGFloat(columns)) - (2 * sideSpan))
	}

	override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint
	{
		return collectionView!.contentOffset
	}
}


final class MusicalCollectionView : UICollectionView
{
	// MARK: - Properties
	// Data sources
	private(set) var items = [MusicalEntity]()
	var searchResults = [MusicalEntity]()
	// Type of entities displayd
	var displayType = MusicalEntityType.albums
	// Delegate
	weak var myDelegate: MusicalCollectionViewDelegate!
	// Cover download operations
	private var downloadOperations = [String : Operation]()

	override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout)
	{
		super.init(frame: frame, collectionViewLayout: layout)
		
		self.dataSource = self
		self.delegate = self
		self.isPrefetchingEnabled = false
		self.backgroundColor = Colors.background

		self.setCollectionViewLayout(CollectionFlowLayout(), animated: false)
		self.register(MusicalEntityBaseCell.self, forCellWithReuseIdentifier: self.cellIdentifier())
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	func setItems(_ items: [MusicalEntity], displayType: MusicalEntityType)
	{
		if displayType != self.displayType
		{
			self.displayType = displayType
			self.register(MusicalEntityBaseCell.self, forCellWithReuseIdentifier: self.cellIdentifier())
		}
		self.items = items
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

	private func cellIdentifier() -> String
	{
		switch displayType
		{
			case .albums:
				return "fr.whine.shinobu.cell.musicalentity.album"
			case .artists:
				return "fr.whine.shinobu.cell.musicalentity.artist"
			case .albumsartists:
				return "fr.whine.shinobu.cell.musicalentity.albumartist"
			case .genres:
				return "fr.whine.shinobu.cell.musicalentity.genre"
			case .playlists:
				return "fr.whine.shinobu.cell.musicalentity.playlist"
		}
	}
}

// MARK: - UICollectionViewDataSource
extension MusicalCollectionView : UICollectionViewDataSource
{
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		if myDelegate == nil
		{
			return 0
		}

		if myDelegate.isSearching(actively: false)
		{
			return searchResults.count
		}

		return items.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier(), for: indexPath) as! MusicalEntityBaseCell
		cell.type = displayType
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.main.scale
		cell.label.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		cell.label.backgroundColor = collectionView.backgroundColor

		// Sanity check
		let searching = myDelegate.isSearching(actively: false)
		if searching && indexPath.row >= searchResults.count
		{
			return cell
		}

		let entity = searching ? searchResults[indexPath.row] : items[indexPath.row]
		// Init cell
		cell.label.text = entity.name
		cell.accessibilityLabel = entity.name
		cell.image = nil
		switch displayType
		{
			case .albums:
				handleCoverForCell(cell, at: indexPath, withAlbum: entity as! Album)
			case .artists, .albumsartists:
				cell.image = #imageLiteral(resourceName: "img-artists").tinted(withColor: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1))
			case .genres:
				cell.image = generateCoverFromString(entity.name[0..<2].uppercased(), size: cell.imageView.size)
			case .playlists:
				cell.image = generateCoverForPlaylist(entity as! Playlist, size: cell.imageView.size)
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
		guard let _ = ServersManager.shared.getSelectedServer()?.covers else { return }
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
			/*if let op = cell.associatedObject as! CoverOperation?
			{
				Logger.shared.log(type: .debug, message: "canceling \(op)")
				op.cancel()
			}*/

			if myDelegate.isSearching(actively: true)
			{
				return
			}

			let sizeAsData = Settings.shared.data(forKey: .coversSize)!
			let cropSize = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSValue.self], from: sizeAsData) as? NSValue
			if album.path != nil
			{
				cell.associatedObject = downloadCoverForAlbum(album, cropSize: (cropSize?.cgSizeValue)!) { (cover: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						if let c = self.cellForItem(at: indexPath) as? MusicalEntityBaseCell
						{
							c.image = thumbnail
						}
					}
				}
			}
			else
			{
				MusicDataSource.shared.getPathForAlbum(album) {
					cell.associatedObject = self.downloadCoverForAlbum(album, cropSize: (cropSize?.cgSizeValue)!) { (cover: UIImage, thumbnail: UIImage) in
						DispatchQueue.main.async {
							if let c = self.cellForItem(at: indexPath) as? MusicalEntityBaseCell
							{
								c.image = thumbnail
							}
						}
					}
				}
			}
		}
	}
}

// MARK: - UICollectionViewDelegate
extension MusicalCollectionView : UICollectionViewDelegate
{
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		myDelegate.didSelectItem(indexPath: indexPath)
	}
}

// MARK: - UIScrollViewDelegate
extension MusicalCollectionView
{
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
	{
		self.reloadItems(at: self.indexPathsForVisibleItems)
	}
}
