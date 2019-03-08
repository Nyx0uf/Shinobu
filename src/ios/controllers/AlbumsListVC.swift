import UIKit


final class AlbumsListVC : NYXViewController
{
	// MARK: - Public properties
	// Collection View
	var collectionView: MusicalCollectionView!
	// Selected artist
	var artist: Artist

	// MARK: - Private properties
	// Previewing context for peek & pop
	private var _previewingContext: UIViewControllerPreviewing! = nil
	// Long press gesture for devices without force touch
	private var _longPress: UILongPressGestureRecognizer! = nil
	// Long press gesture is recognized, flag
	private var longPressRecognized = false

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
		// Remove back button label
		navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "btn-back")
		navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "btn-back")
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		// Display layout button
		let layoutCollectionViewAsCollection = Settings.shared.bool(forKey: .pref_layoutAlbumsCollection)
		let displayButton = UIBarButtonItem(image: layoutCollectionViewAsCollection ? #imageLiteral(resourceName: "btn-display-list") : #imageLiteral(resourceName: "btn-display-collection"), style: .plain, target: self, action: #selector(changeCollectionLayoutType(_:)))
		displayButton.accessibilityLabel = NYXLocalizedString(layoutCollectionViewAsCollection ? "lbl_pref_layoutastable" : "lbl_pref_layoutascollection")
		navigationItem.leftBarButtonItems = [displayButton]
		navigationItem.leftItemsSupplementBackButton = true

		// CollectionView
		collectionView = MusicalCollectionView(frame: self.view.bounds, collectionViewLayout: UICollectionViewLayout())
		collectionView.myDelegate = self
		collectionView.displayType = .albums
		collectionView.layoutType = layoutCollectionViewAsCollection ? .collection : .table
		self.view.addSubview(collectionView)

		// Longpress
		_longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
		_longPress.minimumPressDuration = 0.5
		_longPress.delaysTouchesBegan = true
		updateLongpressState()
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		if artist.albums.count <= 0
		{
			MusicDataSource.shared.getAlbumsForArtist(artist, isAlbumArtist: MusicDataSource.shared.displayType == .albumsartists) {
				DispatchQueue.main.async {
					self.collectionView.items = self.artist.albums
					self.collectionView.reloadData()
					self.updateNavigationTitle()
				}
			}
		}
		else
		{
			DispatchQueue.main.async {
				self.collectionView.items = self.artist.albums
				self.collectionView.reloadData()
				self.updateNavigationTitle()
			}
		}
	}

	// MARK: - Gestures
	@objc func longPress(_ gest: UILongPressGestureRecognizer)
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

			let album = artist.albums[indexPath.row]
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

	// MARK: - Actions
	@objc func changeCollectionLayoutType(_ sender: Any?)
	{
		var b = Settings.shared.bool(forKey: .pref_layoutAlbumsCollection)
		b = !b
		Settings.shared.set(b, forKey: .pref_layoutAlbumsCollection)

		collectionView.layoutType = b ? .collection : .table
		if let buttons = navigationItem.leftBarButtonItems
		{
			if buttons.count >= 1
			{
				let btn = buttons[0]
				btn.image = b ? #imageLiteral(resourceName: "btn-display-list") : #imageLiteral(resourceName: "btn-display-collection")
				btn.accessibilityLabel = NYXLocalizedString(b ? "lbl_pref_layoutastable" : "lbl_pref_layoutascollection")
			}
		}
	}

	// MARK: - Private
	private func updateNavigationTitle()
	{
		let attrs = NSMutableAttributedString(string: artist.name + "\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .medium)])
		attrs.append(NSAttributedString(string: "\(artist.albums.count) \(artist.albums.count == 1 ? NYXLocalizedString("lbl_album").lowercased() : NYXLocalizedString("lbl_albums").lowercased())", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13, weight: .regular)]))
		titleView.attributedText = attrs
	}

	private func updateLongpressState()
	{
		if traitCollection.forceTouchCapability == .available
		{
			collectionView.removeGestureRecognizer(_longPress)
			_longPress.isEnabled = false
			_previewingContext = registerForPreviewing(with: self, sourceView: collectionView)
		}
		else
		{
			collectionView.addGestureRecognizer(_longPress)
			_longPress.isEnabled = true
		}
	}
}

// MARK: - MusicalCollectionViewDelegate
extension AlbumsListVC : MusicalCollectionViewDelegate
{
	func isSearching(actively: Bool) -> Bool
	{
		return false
	}

	func didSelectItem(indexPath: IndexPath)
	{
		let album = artist.albums[indexPath.row]
		let vc = AlbumDetailVC(album: album)
		self.navigationController?.pushViewController(vc, animated: true)
	}
}

// MARK: - UIViewControllerPreviewingDelegate
extension AlbumsListVC : UIViewControllerPreviewingDelegate
{
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
	{
		self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
	}

	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
	{
		if let indexPath = collectionView.indexPathForItem(at: location), let cellAttributes = collectionView.layoutAttributesForItem(at: indexPath)
		{
			previewingContext.sourceRect = cellAttributes.frame
			let sb = UIStoryboard(name: "main-iphone", bundle: .main)

			let vc = sb.instantiateViewController(withIdentifier: "AlbumDetailVC") as! AlbumDetailVC

			let row = indexPath.row
			let album = artist.albums[row]
			vc.album = album
			return vc
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
					let ar = self.artist.albums.compactMap({$0.tracks}).flatMap({$0})
					PlayerController.shared.playTracks(ar, shuffle: false, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action, viewController) in
			MusicDataSource.shared.getAlbumsForArtist(self.artist, isAlbumArtist: MusicDataSource.shared.displayType == .albumsartists) {
				MusicDataSource.shared.getTracksForAlbums(self.artist.albums) {
					let ar = self.artist.albums.compactMap({$0.tracks}).flatMap({$0})
					PlayerController.shared.playTracks(ar, shuffle: true, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let addQueueAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action, viewController) in
			MusicDataSource.shared.getAlbumsForArtist(self.artist, isAlbumArtist: MusicDataSource.shared.displayType == .albumsartists) {
				for album in self.artist.albums
				{
					PlayerController.shared.addAlbumToQueue(album)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, addQueueAction]
	}
}
