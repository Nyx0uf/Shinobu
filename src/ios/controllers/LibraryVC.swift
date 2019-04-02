import UIKit


final class LibraryVC : MusicalCollectionVC, CenterViewController
{
	// MARK: - Public properties
	// Delegate
	var containerDelegate: ContainerVCDelegate? = nil

	// MARK: - Private properties
	// Audio server changed
	private var serverChanged = false

	// MARK: - Initializers
	override init(mpdDataSource: MPDDataSource)
	{
		super.init(mpdDataSource: mpdDataSource)

		dataSource = MusicalCollectionDataSourceAndDelegate(type: MusicalEntityType(rawValue: Settings.shared.integer(forKey: .lastTypeLibrary)), delegate: self, mpdDataSource: mpdDataSource)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Menu button
		let menuButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-hamb"), style: .plain, target: self, action: #selector(showLeftViewAction(_:)))
		menuButton.accessibilityLabel = NYXLocalizedString("vo_displaymenu")
		navigationItem.leftBarButtonItem = menuButton

		MiniPlayerView.shared.mpdDataSource = mpdDataSource

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(miniPlayShouldExpandNotification(_:)), name: .miniPlayerShouldExpand, object: nil)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Initialize the mpd connection
		if mpdDataSource.server == nil
		{
			if let server = ServersManager().getSelectedServer()
			{
				// Player
				PlayerController.shared.server = server.mpd
				let resultPlayer = PlayerController.shared.initialize()
				switch resultPlayer
				{
					case .failure(let error):
						MessageView.shared.showWithMessage(message: error.message)
					case .success(_):
						break
				}

				// Data source
				mpdDataSource.server = server.mpd
				let resultDataSource = mpdDataSource.initialize()
				switch resultDataSource
				{
					case .failure(let error):
						MessageView.shared.showWithMessage(message: error.message)
					case .success(_):
						break
				}
				if dataSource.musicalEntityType != .albums
				{
					// Always fetch the albums list
					mpdDataSource.getListForMusicalEntityType(.albums) {}
				}
				mpdDataSource.getListForMusicalEntityType(dataSource.musicalEntityType) {
					PlayerController.shared.albums = self.mpdDataSource.albums
					DispatchQueue.main.async {
						self.setItems(self.mpdDataSource.listForMusicalEntityType(self.dataSource.musicalEntityType), forMusicalEntityType: self.dataSource.musicalEntityType)
						self.updateNavigationTitle()
						self.updateNavigationButtons()
					}
				}
			}
			else
			{
				Logger.shared.log(type: .information, message: "No MPD server registered or enabled yet")
				containerDelegate?.showServerVC()
			}
		}
		
		// Deselect cell
		if let idxs = collectionView.indexPathsForSelectedItems
		{
			for indexPath in idxs
			{
				collectionView.deselectItem(at: indexPath, animated: true)
			}
		}

		// Audio server changed
		if serverChanged
		{
			// Refresh view
			mpdDataSource.getListForMusicalEntityType(dataSource.musicalEntityType) {
				DispatchQueue.main.async {
					self.setItems(self.mpdDataSource.listForMusicalEntityType(self.dataSource.musicalEntityType), forMusicalEntityType: self.dataSource.musicalEntityType)
					self.collectionView.setContentOffset(.zero, animated: false) // Scroll to top
					self.updateNavigationTitle()
					self.updateNavigationButtons()
				}
			}

			// First time config case
			if PlayerController.shared.server == nil
			{
				PlayerController.shared.server = mpdDataSource.server
				let resultPlayer = PlayerController.shared.reinitialize()
				switch resultPlayer
				{
					case .failure(let error):
						MessageView.shared.showWithMessage(message: error.message)
					case .success(_):
						break
				}
			}

			serverChanged = false
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		OperationManager.shared.cancelAllOperations()
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return [.portrait, .portraitUpsideDown]
	}

	override var shouldAutorotate: Bool
	{
		return true
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	// MARK: - Gestures
	override func doubleTap(_ gest: UITapGestureRecognizer)
	{
		if gest.state != .ended
		{
			return
		}

		if let indexPath = collectionView.indexPathForItem(at: gest.location(in: collectionView))
		{
			switch dataSource.musicalEntityType
			{
				case .albums:
					let album = dataSource.actualItems[indexPath.row] as! Album
					PlayerController.shared.playAlbum(album, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
				case .artists:
					let artist = dataSource.actualItems[indexPath.row] as! Artist
					self.mpdDataSource.getAlbumsForArtist(artist) { (albums) in
						self.mpdDataSource.getTracksForAlbums(artist.albums) {
							let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
							PlayerController.shared.playTracks(ar, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
						}
					}
				case .albumsartists:
					let artist = dataSource.actualItems[indexPath.row] as! Artist
					self.mpdDataSource.getAlbumsForArtist(artist, isAlbumArtist: true) { (albums) in
						self.mpdDataSource.getTracksForAlbums(artist.albums) {
							let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
							PlayerController.shared.playTracks(ar, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
						}
					}
				case .genres:
					let genre = dataSource.actualItems[indexPath.row] as! Genre
					self.mpdDataSource.getAlbumsForGenre(genre, firstOnly: false) { albums in
						self.mpdDataSource.getTracksForAlbums(genre.albums) {
							let ar = genre.albums.compactMap({$0.tracks}).flatMap({$0})
							PlayerController.shared.playTracks(ar, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
						}
					}
				case .playlists:
					let playlist = dataSource.actualItems[indexPath.row] as! Playlist
					PlayerController.shared.playPlaylist(playlist, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
				default:
					break
			}
		}
	}

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
			let cell = collectionView.cellForItem(at: indexPath) as! MusicalEntityBaseCell
			cell.longPressed = true

			let alertController = NYXAlertController(title: nil, message: nil, preferredStyle:.actionSheet)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel) { (action) in
				self.longPressRecognized = false
				cell.longPressed = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(cancelAction)

			switch dataSource.musicalEntityType
			{
				case .albums:
					let album = dataSource.actualItems[indexPath.row] as! Album
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						PlayerController.shared.playAlbum(album, shuffle: false, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						PlayerController.shared.playAlbum(album, shuffle: true, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						PlayerController.shared.addAlbumToQueue(album)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .artists:
					let artist = dataSource.actualItems[indexPath.row] as! Artist
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						self.mpdDataSource.getAlbumsForArtist(artist) { (albums) in
							self.mpdDataSource.getTracksForAlbums(artist.albums) {
								let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
								PlayerController.shared.playTracks(ar, shuffle: false, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdDataSource.getAlbumsForArtist(artist) { (albums) in
							self.mpdDataSource.getTracksForAlbums(artist.albums) {
								let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
								PlayerController.shared.playTracks(ar, shuffle: true, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						self.mpdDataSource.getAlbumsForArtist(artist) { (albums) in
							for album in artist.albums
							{
								PlayerController.shared.addAlbumToQueue(album)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .albumsartists:
					let artist = dataSource.actualItems[indexPath.row] as! Artist
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						self.mpdDataSource.getAlbumsForArtist(artist, isAlbumArtist: true) { (albums) in
							self.mpdDataSource.getTracksForAlbums(artist.albums) {
								let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
								PlayerController.shared.playTracks(ar, shuffle: false, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdDataSource.getAlbumsForArtist(artist, isAlbumArtist: true) { (albums) in
							self.mpdDataSource.getTracksForAlbums(artist.albums) {
								let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
								PlayerController.shared.playTracks(ar, shuffle: true, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						self.mpdDataSource.getAlbumsForArtist(artist, isAlbumArtist: true) { (albums) in
							for album in artist.albums
							{
								PlayerController.shared.addAlbumToQueue(album)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .genres:
					let genre = self.dataSource.actualItems[indexPath.row] as! Genre
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						self.mpdDataSource.getAlbumsForGenre(genre, firstOnly: false) { albums in
							self.mpdDataSource.getTracksForAlbums(genre.albums) {
								let ar = genre.albums.compactMap({$0.tracks}).flatMap({$0})
								PlayerController.shared.playTracks(ar, shuffle: false, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdDataSource.getAlbumsForGenre(genre, firstOnly: false) { albums in
							self.mpdDataSource.getTracksForAlbums(genre.albums) {
								let ar = genre.albums.compactMap({$0.tracks}).flatMap({$0})
								PlayerController.shared.playTracks(ar, shuffle: true, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						self.mpdDataSource.getAlbumsForGenre(genre, firstOnly: false) { albums in
							for album in genre.albums
							{
								PlayerController.shared.addAlbumToQueue(album)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .playlists:
					let playlist = dataSource.actualItems[indexPath.row] as! Playlist
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						PlayerController.shared.playPlaylist(playlist, shuffle: false, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						PlayerController.shared.playPlaylist(playlist, shuffle: true, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let renameAction = UIAlertAction(title: NYXLocalizedString("lbl_rename_playlist"), style: .default) { (action) in
						self.renamePlaylistAction(playlist: playlist)
					}
					alertController.addAction(renameAction)
					let deleteAction = UIAlertAction(title: NYXLocalizedString("lbl_delete_playlist"), style: .destructive) { (action) in
						self.mpdDataSource.deletePlaylist(named: playlist.name) { (result: Result<Bool, MPDConnectionError>) in
							switch result
							{
								case .failure(let error):
									DispatchQueue.main.async {
										MessageView.shared.showWithMessage(message: error.message)
									}
								case .success( _):
									self.mpdDataSource.getListForMusicalEntityType(.playlists) {
										DispatchQueue.main.async {
											self.setItems(self.mpdDataSource.listForMusicalEntityType(.playlists), forMusicalEntityType: .playlists)
											self.updateNavigationTitle()
										}
									}
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(deleteAction)
				default:
					break
			}

			present(alertController, animated: true, completion: nil)
		}
	}

	// MARK: - Buttons actions
	@objc func showLeftViewAction(_ sender: Any?)
	{
		containerDelegate?.toggleMenu()
	}

	@objc func createPlaylistAction(_ sender: Any?)
	{
		let alertController = NYXAlertController(title: NYXLocalizedString("lbl_create_playlist_name"), message: nil, preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_save"), style: .default, handler: { alert -> Void in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text)
			{
				let errorAlert = NYXAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel, handler: { alert -> Void in
				}))
				self.present(errorAlert, animated: true, completion: nil)
			}
			else
			{
				self.mpdDataSource.createPlaylist(named: textField.text!) { (result: Result<Bool, MPDConnectionError>) in
					switch result
					{
						case .failure(let error):
							DispatchQueue.main.async {
								MessageView.shared.showWithMessage(message: error.message)
							}
						case .success( _):
							self.mpdDataSource.getListForMusicalEntityType(.playlists) {
								DispatchQueue.main.async {
									self.setItems(self.mpdDataSource.listForMusicalEntityType(.playlists), forMusicalEntityType: .playlists)
									self.updateNavigationTitle()
								}
							}
					}
				}
			}
		}))
		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel, handler: nil))

		alertController.addTextField(configurationHandler: { (textField) -> Void in
			textField.placeholder = NYXLocalizedString("lbl_create_playlist_placeholder")
			textField.textAlignment = .left
		})

		self.present(alertController, animated: true, completion: nil)
	}

	override func updateNavigationTitle()
	{
		var count = 0
		var title = ""
		switch dataSource.musicalEntityType
		{
			case .albums:
				count = mpdDataSource.albums.count
				title = NYXLocalizedString("lbl_albums")
			case .artists:
				count = mpdDataSource.artists.count
				title = NYXLocalizedString("lbl_artists")
			case .albumsartists:
				count = mpdDataSource.albumsartists.count
				title = NYXLocalizedString("lbl_albumartists")
			case .genres:
				count = mpdDataSource.genres.count
				title = NYXLocalizedString("lbl_genres")
			case .playlists:
				count = mpdDataSource.playlists.count
				title = NYXLocalizedString("lbl_playlists")
			default:
				break
		}
		titleView.setMainText(title, detailText: "(\(count))")
	}

	private func updateNavigationButtons()
	{
		// Search button
		let searchButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-search"), style: .plain, target: self, action: #selector(showSearchBarAction(_:)))
		searchButton.accessibilityLabel = NYXLocalizedString("lbl_search")
		if dataSource.musicalEntityType == .playlists
		{
			// Create playlist button
			let createButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-add"), style: .plain, target: self, action: #selector(createPlaylistAction(_:)))
			createButton.accessibilityLabel = NYXLocalizedString("lbl_create_playlist")
			navigationItem.rightBarButtonItems = [searchButton, createButton]
		}
		else
		{
			navigationItem.rightBarButtonItems = [searchButton]
		}
	}

	private func renamePlaylistAction(playlist: Playlist)
	{
		let alertController = NYXAlertController(title: "\(NYXLocalizedString("lbl_rename_playlist")) \(playlist.name)", message: nil, preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_save"), style: .default, handler: { alert -> Void in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text)
			{
				let errorAlert = NYXAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel, handler: { alert -> Void in
				}))
				self.present(errorAlert, animated: true, completion: nil)
			}
			else
			{
				self.mpdDataSource.rename(playlist: playlist, withNewName: textField.text!) { (result: Result<Bool, MPDConnectionError>) in
					switch result
					{
						case .failure(let error):
							DispatchQueue.main.async {
								MessageView.shared.showWithMessage(message: error.message)
							}
						case .success( _):
							self.mpdDataSource.getListForMusicalEntityType(.playlists) {
								DispatchQueue.main.async {
									self.setItems(self.mpdDataSource.listForMusicalEntityType(.playlists), forMusicalEntityType: .playlists)
									self.updateNavigationTitle()
								}
							}
					}
				}
			}
		}))
		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel, handler: nil))

		alertController.addTextField(configurationHandler: { (textField) -> Void in
			textField.placeholder = NYXLocalizedString("lbl_rename_playlist_placeholder")
			textField.textAlignment = .left
		})

		self.present(alertController, animated: true, completion: nil)
	}

	// MARK: - Notifications
	@objc func audioServerConfigurationDidChange(_ aNotification: Notification)
	{
		serverChanged = true
	}

	@objc func miniPlayShouldExpandNotification(_ aNotification: Notification)
	{
		let vc = PlayerVC(mpdDataSource: mpdDataSource)
		vc.transitioningDelegate = self.navigationController as! NYXNavigationController
		vc.modalPresentationStyle = .custom
		self.navigationController?.present(vc, animated: true, completion: nil)
	}

	override func didSelectDisplayType(_ typeAsInt: Int)
	{
		// Hide
		changeTypeAction(nil)
		// Ignore if type did not change
		let type = MusicalEntityType(rawValue: typeAsInt)
		if dataSource.musicalEntityType == type
		{
			return
		}

		Settings.shared.set(typeAsInt, forKey: .lastTypeLibrary)

		// Refresh view
		mpdDataSource.getListForMusicalEntityType(type) {
			DispatchQueue.main.async {
				self.setItems(self.mpdDataSource.listForMusicalEntityType(type), forMusicalEntityType: type)
				if self.dataSource.items.count == 0
				{
					self.collectionView.contentOffset = CGPoint(0, 64)
				}
				else
				{
					self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false) // Scroll to top
				}

				self.updateNavigationTitle()
				self.updateNavigationButtons()
			}
		}
	}
}

// MARK: - MusicalCollectionViewDelegate
extension LibraryVC
{
	override func didSelectItem(indexPath: IndexPath)
	{
		// If menu is visible ignore default behavior and hide it
		if let del = containerDelegate, del.isMenuVisible()
		{
			collectionView.deselectItem(at: indexPath, animated: false)
			showLeftViewAction(nil)
			return
		}

		let entities = dataSource.actualItems
		if indexPath.row >= entities.count
		{
			return
		}
		let entity = entities[indexPath.row]

		switch dataSource.musicalEntityType
		{
			case .albums:
				let vc = AlbumDetailVC(album: entity as! Album, mpdDataSource: mpdDataSource)
				self.navigationController?.pushViewController(vc, animated: true)
			case .artists:
				let vc = AlbumsListVC(artist: entity as! Artist, isAlbumArtist: false, mpdDataSource: mpdDataSource)
				self.navigationController?.pushViewController(vc, animated: true)
			case .albumsartists:
				let vc = AlbumsListVC(artist: entity as! Artist, isAlbumArtist: true, mpdDataSource: mpdDataSource)
				self.navigationController?.pushViewController(vc, animated: true)
			case .genres:
				let vc = GenreDetailVC(genre: entity as! Genre, mpdDataSource: mpdDataSource)
				self.navigationController?.pushViewController(vc, animated: true)
			case .playlists:
				let vc = PlaylistDetailVC(playlist: entity as! Playlist, mpdDataSource: mpdDataSource)
				self.navigationController?.pushViewController(vc, animated: true)
			default:
				break
		}
	}
}

// MARK: - UIResponder
extension LibraryVC
{
	override var canBecomeFirstResponder: Bool
	{
		return true
	}

	override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?)
	{
		if motion == .motionShake
		{
			if Settings.shared.bool(forKey: .pref_shakeToPlayRandom) == false || mpdDataSource.albums.count == 0
			{
				return
			}

			guard let randomAlbum = mpdDataSource.albums.randomElement() else { return }
			if randomAlbum.tracks == nil
			{
				mpdDataSource.getTracksForAlbums([randomAlbum]) {
					PlayerController.shared.playAlbum(randomAlbum, shuffle: false, loop: false)
				}
			}
			else
			{
				PlayerController.shared.playAlbum(randomAlbum, shuffle: false, loop: false)
			}
		}
	}
}

// MARK: - UIViewControllerTransitioningDelegate
extension NYXNavigationController : UIViewControllerTransitioningDelegate
{
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
	{
		let c = PlayerVCCustomPresentAnimationController()
		c.presenting = true
		return c
	}

	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
	{
		let c = PlayerVCCustomPresentAnimationController()
		c.presenting = false
		return c
	}
}

// MARK: - UIViewControllerPreviewingDelegate
extension LibraryVC
{
	override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
	{
		if let indexPath = collectionView.indexPathForItem(at: location), let cellAttributes = collectionView.layoutAttributesForItem(at: indexPath)
		{
			previewingContext.sourceRect = cellAttributes.frame
			let row = indexPath.row
			switch dataSource.musicalEntityType
			{
				case .albums:
					let album = dataSource.actualItems[row] as! Album
					return AlbumDetailVC(album: album, mpdDataSource: mpdDataSource)
				case .artists, .albumsartists:
					let artist = dataSource.actualItems[row] as! Artist
					return AlbumsListVC(artist: artist, isAlbumArtist: dataSource.musicalEntityType == .albumsartists, mpdDataSource: mpdDataSource)
				case .genres:
					let genre = dataSource.actualItems[row] as! Genre
					return GenreDetailVC(genre: genre, mpdDataSource: mpdDataSource)
				case .playlists:
					let playlist = dataSource.actualItems[row] as! Playlist
					return PlaylistDetailVC(playlist: playlist, mpdDataSource: mpdDataSource)
				default:
					break
			}
		}
		return nil
	}
}
