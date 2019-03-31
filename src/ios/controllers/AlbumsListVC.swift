import UIKit


final class AlbumsListVC : MusicalCollectionVC
{
	// MARK: - Public properties
	// Selected artist
	let artist: Artist

	// MARK: - Initializers
	init(artist: Artist)
	{
		self.artist = artist
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		self.collectionView.displayType = .albums
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		if artist.albums.count <= 0
		{
			MusicDataSource.shared.getAlbumsForArtist(artist, isAlbumArtist: MusicDataSource.shared.displayType == .albumsartists) {
				DispatchQueue.main.async {
					self.dataSource.setItems(self.artist.albums, forType: .albums)
					self.collectionView.reloadData()
					self.updateNavigationTitle()
				}
			}
		}
		else
		{
			DispatchQueue.main.async {
				self.dataSource.setItems(self.artist.albums, forType: .albums)
				self.collectionView.reloadData()
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

		if let indexPath = collectionView.indexPathForItem(at: gest.location(in: collectionView))
		{
			MiniPlayerView.shared.stayHidden = true
			MiniPlayerView.shared.hide()

			let alertController = NYXAlertController(title: nil, message: nil, preferredStyle:.actionSheet)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel) { (action) in
				self.longPressRecognized = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(cancelAction)

			let album = searching ? dataSource.searchResults[indexPath.row] as! Album : dataSource.items[indexPath.row] as! Album
			let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
				PlayerController.shared.playAlbum(album, shuffle: false, loop: false)
				self.longPressRecognized = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(playAction)
			let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
				PlayerController.shared.playAlbum(album, shuffle: true, loop: false)
				self.longPressRecognized = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(shuffleAction)
			let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
				PlayerController.shared.addAlbumToQueue(album)
				self.longPressRecognized = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(addQueueAction)

			present(alertController, animated: true, completion: nil)
		}
	}

	// MARK: - Private
	private func updateNavigationTitle()
	{
		titleView.setMainText(artist.name, detailText: "\(dataSource.items.count) \(dataSource.items.count == 1 ? NYXLocalizedString("lbl_album").lowercased() : NYXLocalizedString("lbl_albums").lowercased())")
	}
}

// MARK: - MusicalCollectionViewDelegate
extension AlbumsListVC
{
	override func didSelectItem(indexPath: IndexPath)
	{
		let album = searching ? dataSource.searchResults[indexPath.row] as! Album : dataSource.items[indexPath.row] as! Album
		let vc = AlbumDetailVC(album: album)
		self.navigationController?.pushViewController(vc, animated: true)
	}
}

// MARK: - UIViewControllerPreviewingDelegate
extension AlbumsListVC
{
	override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
	{
		if let indexPath = collectionView.indexPathForItem(at: location), let cellAttributes = collectionView.layoutAttributesForItem(at: indexPath)
		{
			previewingContext.sourceRect = cellAttributes.frame

			let album = searching ? dataSource.searchResults[indexPath.row] as! Album : dataSource.items[indexPath.row] as! Album
			return AlbumDetailVC(album: album)
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
			MusicDataSource.shared.getAlbumsForArtist(self.artist, isAlbumArtist: MusicDataSource.shared.displayType == .albumsartists) {
				MusicDataSource.shared.getTracksForAlbums(self.artist.albums) {
					let source = self.searching ? self.dataSource.searchResults as! [Album] : self.dataSource.items as! [Album]
					let ar = source.compactMap({$0.tracks}).flatMap({$0})
					PlayerController.shared.playTracks(ar, shuffle: false, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action, viewController) in
			MusicDataSource.shared.getAlbumsForArtist(self.artist, isAlbumArtist: MusicDataSource.shared.displayType == .albumsartists) {
				MusicDataSource.shared.getTracksForAlbums(self.artist.albums) {
					let source = self.searching ? self.dataSource.searchResults as! [Album] : self.dataSource.items as! [Album]
					let ar = source.compactMap({$0.tracks}).flatMap({$0})
					PlayerController.shared.playTracks(ar, shuffle: true, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let addQueueAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action, viewController) in
			MusicDataSource.shared.getAlbumsForArtist(self.artist, isAlbumArtist: MusicDataSource.shared.displayType == .albumsartists) {
				let source = self.searching ? self.dataSource.searchResults as! [Album] : self.dataSource.items as! [Album]
				for album in source
				{
					PlayerController.shared.addAlbumToQueue(album)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, addQueueAction]
	}
}
