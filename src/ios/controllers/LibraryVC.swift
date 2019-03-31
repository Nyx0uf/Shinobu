import UIKit


final class LibraryVC : MusicalCollectionVC, CenterViewController
{
	// MARK: - Public properties
	// Delegate
	var containerDelegate: ContainerVCDelegate? = nil
	// MARK: - Private properties
	// View to change the type of items in the collection view
	private var typeChoiceView: TypeChoiceView! = nil
	// Active display type
	private var displayType = MusicalEntityType(rawValue: Settings.shared.integer(forKey: .pref_displayType))!
	// Audio server changed
	private var serverChanged = false

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Menu button
		let menuButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-hamb"), style: .plain, target: self, action: #selector(showLeftViewAction(_:)))
		menuButton.accessibilityLabel = NYXLocalizedString("vo_displaymenu")
		navigationItem.leftBarButtonItem = menuButton

		// Navigation bar title
		titleView.isEnabled = true
		titleView.addTarget(self, action: #selector(changeTypeAction(_:)), for: .touchUpInside)

		_ = MiniPlayerView.shared.visible

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(miniPlayShouldExpandNotification(_:)), name: .miniPlayerShouldExpand, object: nil)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Initialize the mpd connection
		if MusicDataSource.shared.server == nil
		{
			if let server = ServersManager.shared.getSelectedServer()
			{
				// Data source
				MusicDataSource.shared.server = server.mpd
				let resultDataSource = MusicDataSource.shared.initialize()
				switch resultDataSource
				{
					case .failure(let error):
						MessageView.shared.showWithMessage(message: error.message)
					case .success(_):
						break
				}
				if displayType != .albums
				{
					// Always fetch the albums list
					MusicDataSource.shared.getListForMusicalEntityType(.albums) {}
				}
				MusicDataSource.shared.getListForMusicalEntityType(displayType) {
					DispatchQueue.main.async {
						self.collectionView.setItems(MusicDataSource.shared.selectedList(), displayType: self.displayType)
						self.collectionView.reloadData()
						self.updateNavigationTitle()
						self.updateNavigationButtons()
					}
				}

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
			}
			else
			{
				Logger.shared.log(type: .debug, message: "No MPD server registered or enabled yet")
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
			MusicDataSource.shared.getListForMusicalEntityType(displayType) {
				DispatchQueue.main.async {
					self.collectionView.setItems(MusicDataSource.shared.selectedList(), displayType: self.displayType)
					self.collectionView.reloadData()
					self.collectionView.setContentOffset(.zero, animated: false) // Scroll to top
					self.updateNavigationTitle()
					self.updateNavigationButtons()
				}
			}

			// First time config case
			if PlayerController.shared.server == nil
			{
				PlayerController.shared.server = MusicDataSource.shared.server
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
			switch displayType
			{
				case .albums:
					let album = searching ? collectionView.searchResults[indexPath.row] as! Album : MusicDataSource.shared.albums[indexPath.row]
					PlayerController.shared.playAlbum(album, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
				case .artists:
					let artist = searching ? collectionView.searchResults[indexPath.row] as! Artist : MusicDataSource.shared.artists[indexPath.row]
					MusicDataSource.shared.getAlbumsForArtist(artist) {
						MusicDataSource.shared.getTracksForAlbums(artist.albums) {
							let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
							PlayerController.shared.playTracks(ar, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
						}
					}
				case .albumsartists:
					let artist = searching ? collectionView.searchResults[indexPath.row] as! Artist : MusicDataSource.shared.albumsartists[indexPath.row]
					MusicDataSource.shared.getAlbumsForArtist(artist, isAlbumArtist: true) {
						MusicDataSource.shared.getTracksForAlbums(artist.albums) {
							let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
							PlayerController.shared.playTracks(ar, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
						}
					}
				case .genres:
					let genre = searching ? collectionView.searchResults[indexPath.row] as! Genre : MusicDataSource.shared.genres[indexPath.row]
					MusicDataSource.shared.getAlbumsForGenre(genre, firstOnly: false) {
						MusicDataSource.shared.getTracksForAlbums(genre.albums) {
							let ar = genre.albums.compactMap({$0.tracks}).flatMap({$0})
							PlayerController.shared.playTracks(ar, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
						}
					}
				case .playlists:
					let playlist = searching ? collectionView.searchResults[indexPath.row] as! Playlist : MusicDataSource.shared.playlists[indexPath.row]
					PlayerController.shared.playPlaylist(playlist, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
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

			switch displayType
			{
				case .albums:
					let album = searching ? collectionView.searchResults[indexPath.row] as! Album : MusicDataSource.shared.albums[indexPath.row]
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
					let artist = searching ? collectionView.searchResults[indexPath.row] as! Artist : MusicDataSource.shared.artists[indexPath.row]
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						MusicDataSource.shared.getAlbumsForArtist(artist) {
							MusicDataSource.shared.getTracksForAlbums(artist.albums) {
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
						MusicDataSource.shared.getAlbumsForArtist(artist) {
							MusicDataSource.shared.getTracksForAlbums(artist.albums) {
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
						MusicDataSource.shared.getAlbumsForArtist(artist) {
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
					let artist = searching ? collectionView.searchResults[indexPath.row] as! Artist : MusicDataSource.shared.albumsartists[indexPath.row]
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						MusicDataSource.shared.getAlbumsForArtist(artist, isAlbumArtist: true) {
							MusicDataSource.shared.getTracksForAlbums(artist.albums) {
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
						MusicDataSource.shared.getAlbumsForArtist(artist, isAlbumArtist: true) {
							MusicDataSource.shared.getTracksForAlbums(artist.albums) {
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
						MusicDataSource.shared.getAlbumsForArtist(artist, isAlbumArtist: true) {
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
					let genre = self.searching ? collectionView.searchResults[indexPath.row] as! Genre : MusicDataSource.shared.genres[indexPath.row]
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						MusicDataSource.shared.getAlbumsForGenre(genre, firstOnly: false) {
							MusicDataSource.shared.getTracksForAlbums(genre.albums) {
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
						MusicDataSource.shared.getAlbumsForGenre(genre, firstOnly: false) {
							MusicDataSource.shared.getTracksForAlbums(genre.albums) {
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
						MusicDataSource.shared.getAlbumsForGenre(genre, firstOnly: false) {
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
					let playlist = self.searching ? collectionView.searchResults[indexPath.row] as! Playlist : MusicDataSource.shared.playlists[indexPath.row]
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
						MusicDataSource.shared.deletePlaylist(named: playlist.name) { (result: Result<Bool, MPDConnectionError>) in
							switch result
							{
								case .failure(let error):
									DispatchQueue.main.async {
										MessageView.shared.showWithMessage(message: error.message)
									}
								case .success( _):
									MusicDataSource.shared.getListForMusicalEntityType(.playlists) {
										DispatchQueue.main.async {
											self.collectionView.setItems(MusicDataSource.shared.selectedList(), displayType: .playlists)
											self.collectionView.reloadData()
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
			}

			present(alertController, animated: true, completion: nil)
		}
	}

	// MARK: - Buttons actions
	@objc func changeTypeAction(_ sender: UIButton?)
	{
		if typeChoiceView == nil
		{
			typeChoiceView = TypeChoiceView(frame: CGRect(0.0, (self.navigationController?.navigationBar.bottom)!, collectionView.width, 220.0))
			typeChoiceView.delegate = self
		}

		if typeChoiceView.superview != nil
		{ // Is visible
			UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
				self.collectionView.frame = CGRect(0, 0, self.collectionView.size)
				//self.view.layoutIfNeeded()
				if MusicDataSource.shared.selectedList().count == 0
				{
					self.collectionView.contentOffset = CGPoint(0, (self.navigationController?.navigationBar.bottom)!)
				}
				else
				{
					self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
					self.collectionView.contentOffset = CGPoint(0, -(self.navigationController?.navigationBar.bottom)!)
				}
			}, completion: { finished in
				self.typeChoiceView.removeFromSuperview()
			})
		}
		else
		{ // Is hidden
			typeChoiceView.tableView.reloadData()
			view.insertSubview(typeChoiceView, belowSubview:collectionView)

			UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
				self.collectionView.frame = CGRect(0, self.typeChoiceView.bottom, self.collectionView.size)
				self.collectionView.contentInset = .zero
				self.view.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
			}, completion:nil)
		}
	}

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
				MusicDataSource.shared.createPlaylist(named: textField.text!) { (result: Result<Bool, MPDConnectionError>) in
					switch result
					{
						case .failure(let error):
							DispatchQueue.main.async {
								MessageView.shared.showWithMessage(message: error.message)
							}
						case .success( _):
							MusicDataSource.shared.getListForMusicalEntityType(.playlists) {
								DispatchQueue.main.async {
									self.collectionView.setItems(MusicDataSource.shared.selectedList(), displayType: .playlists)
									self.collectionView.reloadData()
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

	// MARK: - Private
	private func updateNavigationTitle()
	{
		var count = 0
		var title = ""
		switch displayType
		{
			case .albums:
				count = MusicDataSource.shared.albums.count
				title = NYXLocalizedString("lbl_albums")
			case .artists:
				count = MusicDataSource.shared.artists.count
				title = NYXLocalizedString("lbl_artists")
			case .albumsartists:
				count = MusicDataSource.shared.albumsartists.count
				title = NYXLocalizedString("lbl_albumartists")
			case .genres:
				count = MusicDataSource.shared.genres.count
				title = NYXLocalizedString("lbl_genres")
			case .playlists:
				count = MusicDataSource.shared.playlists.count
				title = NYXLocalizedString("lbl_playlists")
		}
		titleView.setMainText(title, detailText: "(\(count))")
	}

	private func updateNavigationButtons()
	{
		// Search button
		let searchButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-search"), style: .plain, target: self, action: #selector(showSearchBarAction(_:)))
		searchButton.accessibilityLabel = NYXLocalizedString("lbl_search")
		if displayType == .playlists
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
				MusicDataSource.shared.rename(playlist: playlist, withNewName: textField.text!) { (result: Result<Bool, MPDConnectionError>) in
					switch result
					{
						case .failure(let error):
							DispatchQueue.main.async {
								MessageView.shared.showWithMessage(message: error.message)
							}
						case .success( _):
							MusicDataSource.shared.getListForMusicalEntityType(.playlists) {
								DispatchQueue.main.async {
									self.collectionView.setItems(MusicDataSource.shared.selectedList(), displayType: .playlists)
									self.collectionView.reloadData()
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
		let vc = PlayerVC()
		vc.transitioningDelegate = self.navigationController as! NYXNavigationController
		vc.modalPresentationStyle = .custom
		self.navigationController?.present(vc, animated: true, completion: nil)
	}
}

// MARK: - MusicalCollectionViewDelegate
extension LibraryVC
{
	override func isSearching(actively: Bool) -> Bool
	{
		return actively ? (self.searching && searchBar.isFirstResponder) : self.searching
	}

	override func didSelectItem(indexPath: IndexPath)
	{
		// If menu is visible ignore default behavior and hide it
		if containerDelegate!.isMenuVisible()
		{
			collectionView.deselectItem(at: indexPath, animated: false)
			showLeftViewAction(nil)
			return
		}

		switch displayType
		{
			case .albums:
				let album = searching ? collectionView.searchResults[indexPath.row] as! Album : MusicDataSource.shared.albums[indexPath.row]
				let vc = AlbumDetailVC(album: album)
				self.navigationController?.pushViewController(vc, animated: true)
			case .artists:
				let artist = searching ? collectionView.searchResults[indexPath.row] as! Artist : MusicDataSource.shared.artists[indexPath.row]
				let vc = AlbumsListVC(artist: artist)
				self.navigationController?.pushViewController(vc, animated: true)
			case .albumsartists:
				let artist = searching ? collectionView.searchResults[indexPath.row] as! Artist : MusicDataSource.shared.albumsartists[indexPath.row]
				let vc = AlbumsListVC(artist: artist)
				self.navigationController?.pushViewController(vc, animated: true)
			case .genres:
				let genre = searching ? collectionView.searchResults[indexPath.row] as! Genre : MusicDataSource.shared.genres[indexPath.row]
				let vc = ArtistsListVC(genre: genre)
				self.navigationController?.pushViewController(vc, animated: true)
			case .playlists:
				let playlist = searching ? collectionView.searchResults[indexPath.row] as! Playlist : MusicDataSource.shared.playlists[indexPath.row]
				let vc = PlaylistDetailVC(playlist: playlist)
				self.navigationController?.pushViewController(vc, animated: true)
		}
	}
}

// MARK: - TypeChoiceViewDelegate
extension LibraryVC : TypeChoiceViewDelegate
{
	func didSelectDisplayType(_ type: MusicalEntityType)
	{
		// Ignore if type did not change
		if displayType == type
		{
			changeTypeAction(nil)
			return
		}
		displayType = type

		Settings.shared.set(type.rawValue, forKey: .pref_displayType)

		// Longpress / peek & pop
		updateLongpressState()

		// Refresh view
		MusicDataSource.shared.getListForMusicalEntityType(type) {
			DispatchQueue.main.async {
				self.collectionView.setItems(MusicDataSource.shared.selectedList(), displayType: type)
				self.collectionView.reloadData()
				self.changeTypeAction(nil)
				if MusicDataSource.shared.selectedList().count == 0
				{
					self.collectionView.contentOffset = CGPoint(0, 64)
				}
				else
				{
					self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false) // Scroll to top
				}

				self.updateNavigationTitle()
			}
		}

		updateNavigationButtons()
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
			if Settings.shared.bool(forKey: .pref_shakeToPlayRandom) == false || MusicDataSource.shared.albums.count == 0
			{
				return
			}

			guard let randomAlbum = MusicDataSource.shared.albums.randomElement() else { return }
			if randomAlbum.tracks == nil
			{
				MusicDataSource.shared.getTracksForAlbums([randomAlbum]) {
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
extension LibraryVC : UIViewControllerPreviewingDelegate
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
			let row = indexPath.row
			if displayType == .albums
			{
				let vc = sb.instantiateViewController(withIdentifier: "AlbumDetailVC") as! AlbumDetailVC

				let album = searching ? collectionView.searchResults[row] as! Album : MusicDataSource.shared.albums[row]
				vc.album = album
				return vc
			}
			else if displayType == .playlists
			{
				let vc = sb.instantiateViewController(withIdentifier: "PlaylistDetailVC") as! PlaylistDetailVC

				let playlist = searching ? collectionView.searchResults[row] as! Playlist : MusicDataSource.shared.playlists[row]
				vc.playlist = playlist
				return vc
			}
		}
		return nil
	}
}
