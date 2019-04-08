import UIKit


final class AlbumsListVC: MusicalCollectionVC
{
	// MARK: - Public properties
	// Selected artist
	let artist: Artist
	// Show artist or album artist ?
	let isAlbumArtist: Bool
	// Allowed display types
	override var allowedMusicalEntityTypes: [MusicalEntityType]
	{
		return [.albums]
	}

	// MARK: - Initializers
	init(artist: Artist, isAlbumArtist: Bool, mpdBridge: MPDBridge)
	{
		self.artist = artist
		self.isAlbumArtist = isAlbumArtist

		super.init(mpdBridge: mpdBridge)

		dataSource = MusicalCollectionDataSourceAndDelegate(type: .albums, delegate: self, mpdBridge: mpdBridge)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		if artist.albums.count <= 0
		{
			mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: isAlbumArtist) { [weak self] (albums) in
				DispatchQueue.main.async {
					self?.setItems(albums, forMusicalEntityType: .albums)
					self?.updateNavigationTitle()
				}
			}
		}
		else
		{
			DispatchQueue.main.async {
				self.setItems(self.artist.albums, forMusicalEntityType: .albums)
				self.updateNavigationTitle()
			}
		}
	}

	// MARK: - Gestures
	override func longPress(_ gest: UILongPressGestureRecognizer)
	{
		if longPressRecognized
		{
			return
		}
		longPressRecognized = true

		if let indexPath = collectionView.collectionView.indexPathForItem(at: gest.location(in: collectionView.collectionView))
		{
			MiniPlayerView.shared.stayHidden = true
			MiniPlayerView.shared.hide()

			let alertController = NYXAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel) { (action) in
				self.longPressRecognized = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(cancelAction)

			let album = dataSource.currentItemAtIndexPath(indexPath) as! Album
			let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
				self.mpdBridge.playAlbum(album, shuffle: false, loop: false)
				self.longPressRecognized = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(playAction)
			let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
				self.mpdBridge.playAlbum(album, shuffle: true, loop: false)
				self.longPressRecognized = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(shuffleAction)
			let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
				self.mpdBridge.addAlbumToQueue(album)
				self.longPressRecognized = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(addQueueAction)

			present(alertController, animated: true, completion: nil)
		}
	}

	override func updateNavigationTitle()
	{
		titleView.setMainText(artist.name, detailText: "\(dataSource.items.count) \(dataSource.items.count == 1 ? NYXLocalizedString("lbl_album").lowercased() : NYXLocalizedString("lbl_albums").lowercased())")
	}
}

// MARK: - MusicalCollectionViewDelegate
extension AlbumsListVC
{
	override func didSelectEntity(_ entity: AnyObject)
	{
		let vc = AlbumDetailVC(album: entity as! Album, mpdBridge: mpdBridge)
		navigationController?.pushViewController(vc, animated: true)
	}
}

// MARK: - UIViewControllerPreviewingDelegate
extension AlbumsListVC
{
	override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
	{
		if let indexPath = collectionView.collectionView.indexPathForItem(at: location), let cellAttributes = collectionView.collectionView.layoutAttributesForItem(at: indexPath)
		{
			previewingContext.sourceRect = cellAttributes.frame

			let album = dataSource.currentItemAtIndexPath(indexPath) as! Album
			return AlbumDetailVC(album: album, mpdBridge: mpdBridge)
		}
		return nil
	}
}

// MARK: - Peek & Pop
extension AlbumsListVC
{
	override var previewActionItems: [UIPreviewActionItem]
	{
		let playAction = UIPreviewAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action, viewController) in
			self.mpdBridge.getAlbumsForArtist(self.artist, isAlbumArtist: self.isAlbumArtist) { (albums) in
				self.mpdBridge.getTracksForAlbums(self.artist.albums) { (tracks) in
					let source = self.dataSource.items as! [Album]
					let ar = source.compactMap { $0.tracks }.flatMap { $0 }
					self.mpdBridge.playTracks(ar, shuffle: false, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action, viewController) in
			self.mpdBridge.getAlbumsForArtist(self.artist, isAlbumArtist: self.isAlbumArtist) { (albums) in
				self.mpdBridge.getTracksForAlbums(self.artist.albums) { (tracks) in
					let source = self.dataSource.items as! [Album]
					let ar = source.compactMap { $0.tracks }.flatMap { $0 }
					self.mpdBridge.playTracks(ar, shuffle: true, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let addQueueAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action, viewController) in
			self.mpdBridge.getAlbumsForArtist(self.artist, isAlbumArtist: self.isAlbumArtist) { (albums) in
				let source = self.dataSource.items as! [Album]
				for album in source
				{
					self.mpdBridge.addAlbumToQueue(album)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, addQueueAction]
	}
}
