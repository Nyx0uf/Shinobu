import UIKit


final class LibraryVC: MusicalCollectionVC
{
	// MARK: - Private properties
	// Audio server changed
	private var serverChanged = false

	// MARK: - Initializers
	init()
	{
		super.init(mpdBridge: MPDBridge(usePrettyDB: Settings.shared.bool(forKey: .pref_usePrettyDB)))

		dataSource = MusicalCollectionDataSourceAndDelegate(type: MusicalEntityType(rawValue: Settings.shared.integer(forKey: .lastTypeLibrary)), delegate: self, mpdBridge: mpdBridge)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Servers button
		let serversButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-server"), style: .plain, target: self, action: #selector(showServersListAction(_:)))
		serversButton.accessibilityLabel = NYXLocalizedString("lbl_header_server_list")
		// Settings button
		let settingsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-settings"), style: .plain, target: self, action: #selector(showSettingsAction(_:)))
		settingsButton.accessibilityLabel = NYXLocalizedString("lbl_section_settings")
		navigationItem.leftBarButtonItems = [serversButton, settingsButton]

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(showArtist(_:)), name: .showArtistNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(showAlbum(_:)), name: .showAlbumNotification, object: nil)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Initialize the mpd connection
		if mpdBridge.server == nil
		{
			if let server = ServersManager().getSelectedServer()
			{
				// Data source
				mpdBridge.server = server.mpd
				let resultDataSource = mpdBridge.initialize()
				switch resultDataSource
				{
					case .failure(let error):
						MessageView.shared.showWithMessage(message: error.message)
					case .success(_):
						if dataSource.musicalEntityType != .albums
						{
							// Always fetch the albums list
							mpdBridge.entitiesForType(.albums) { (_) in }
						}

						mpdBridge.entitiesForType(dataSource.musicalEntityType) { (entities) in
							DispatchQueue.main.async {
								self.setItems(entities, forMusicalEntityType: self.dataSource.musicalEntityType)
								self.updateNavigationTitle()
								self.updateNavigationButtons()
							}
						}
				}
			}
			else
			{
				Logger.shared.log(type: .information, message: "No MPD server registered or enabled yet")
				showServersListAction(nil)
			}
		}

		// Deselect cell
		if let idxs = collectionView.collectionView.indexPathsForSelectedItems
		{
			for indexPath in idxs
			{
				collectionView.collectionView.deselectItem(at: indexPath, animated: true)
			}
		}

		// Audio server changed
		if serverChanged
		{
			// Refresh view
			mpdBridge.entitiesForType(dataSource.musicalEntityType) { (entities) in
				DispatchQueue.main.async {
					self.setItems(entities, forMusicalEntityType: self.dataSource.musicalEntityType)
					self.collectionView.collectionView.setContentOffset(.zero, animated: false) // Scroll to top
					self.updateNavigationTitle()
					self.updateNavigationButtons()
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

		if let indexPath = collectionView.collectionView.indexPathForItem(at: gest.location(in: collectionView.collectionView))
		{
			switch dataSource.musicalEntityType
			{
				case .albums:
					let album = dataSource.currentItemAtIndexPath(indexPath) as! Album
					mpdBridge.playAlbum(album, shuffle: false, loop: false)
				case .artists:
					let artist = dataSource.currentItemAtIndexPath(indexPath) as! Artist
					mpdBridge.getAlbumsForArtist(artist) { [weak self] (albums) in
						guard let strongSelf = self else { return }
						strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
							let ar = artist.albums.compactMap { $0.tracks }.flatMap { $0 }
							strongSelf.mpdBridge.playTracks(ar, shuffle: false, loop: false)
						}
					}
				case .albumsartists:
					let artist = dataSource.currentItemAtIndexPath(indexPath) as! Artist
					mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { [weak self] (albums) in
						guard let strongSelf = self else { return }
						strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
							let ar = artist.albums.compactMap { $0.tracks }.flatMap { $0 }
							strongSelf.mpdBridge.playTracks(ar, shuffle: false, loop: false)
						}
					}
				case .genres:
					let genre = dataSource.currentItemAtIndexPath(indexPath) as! Genre
					mpdBridge.getAlbumsForGenre(genre, firstOnly: false) { [weak self] (albums) in
						guard let strongSelf = self else { return }
						strongSelf.mpdBridge.getTracksForAlbums(genre.albums) { (tracks) in
							let ar = genre.albums.compactMap { $0.tracks }.flatMap { $0 }
							strongSelf.mpdBridge.playTracks(ar, shuffle: false, loop: false)
						}
					}
				case .playlists:
					let playlist = dataSource.currentItemAtIndexPath(indexPath) as! Playlist
					mpdBridge.playPlaylist(playlist, shuffle: false, loop: false)
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

		if let indexPath = collectionView.collectionView.indexPathForItem(at: gest.location(in: collectionView.collectionView))
		{
			let cell = collectionView.collectionView.cellForItem(at: indexPath) as! MusicalEntityCollectionViewCell
			cell.longPressed = true

			let alertController = NYXAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel) { (action) in
				self.longPressRecognized = false
				cell.longPressed = false
			}
			alertController.addAction(cancelAction)

			switch dataSource.musicalEntityType
			{
				case .albums:
					let album = dataSource.currentItemAtIndexPath(indexPath) as! Album
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						self.mpdBridge.playAlbum(album, shuffle: false, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdBridge.playAlbum(album, shuffle: true, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						self.mpdBridge.addAlbumToQueue(album)
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(addQueueAction)
				case .artists:
					let artist = dataSource.currentItemAtIndexPath(indexPath) as! Artist
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForArtist(artist) { [weak self] (albums) in
							guard let strongSelf = self else { return }
							strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
								let ar = artist.albums.compactMap { $0.tracks }.flatMap { $0 }
								strongSelf.mpdBridge.playTracks(ar, shuffle: false, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForArtist(artist) { [weak self] (albums) in
							guard let strongSelf = self else { return }
							strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
								let ar = artist.albums.compactMap { $0.tracks }.flatMap{ $0 }
								strongSelf.mpdBridge.playTracks(ar, shuffle: true, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForArtist(artist) { [weak self] (albums) in
							guard let strongSelf = self else { return }
							for album in artist.albums
							{
								strongSelf.mpdBridge.addAlbumToQueue(album)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(addQueueAction)
				case .albumsartists:
					let artist = dataSource.currentItemAtIndexPath(indexPath) as! Artist
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { [weak self] (albums) in
							guard let strongSelf = self else { return }
							strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
								let ar = artist.albums.compactMap { $0.tracks }.flatMap { $0 }
								strongSelf.mpdBridge.playTracks(ar, shuffle: false, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { [weak self] (albums) in
							guard let strongSelf = self else { return }
							strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
								let ar = artist.albums.compactMap { $0.tracks }.flatMap{ $0 }
								strongSelf.mpdBridge.playTracks(ar, shuffle: true, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { [weak self] (albums) in
							guard let strongSelf = self else { return }
							for album in artist.albums
							{
								strongSelf.mpdBridge.addAlbumToQueue(album)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(addQueueAction)
				case .genres:
					let genre = self.dataSource.currentItemAtIndexPath(indexPath) as! Genre
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForGenre(genre, firstOnly: false) { [weak self] (albums) in
							guard let strongSelf = self else { return }
							strongSelf.mpdBridge.getTracksForAlbums(genre.albums) { (tracks) in
								let ar = genre.albums.compactMap { $0.tracks }.flatMap{ $0 }
								strongSelf.mpdBridge.playTracks(ar, shuffle: false, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForGenre(genre, firstOnly: false) { [weak self] (albums) in
							guard let strongSelf = self else { return }
							strongSelf.mpdBridge.getTracksForAlbums(genre.albums) { (tracks) in
								let ar = genre.albums.compactMap { $0.tracks }.flatMap{ $0 }
								strongSelf.mpdBridge.playTracks(ar, shuffle: true, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForGenre(genre, firstOnly: false) { [weak self] (albums) in
							guard let strongSelf = self else { return }
							for album in genre.albums
							{
								strongSelf.mpdBridge.addAlbumToQueue(album)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(addQueueAction)
				case .playlists:
					let playlist = dataSource.currentItemAtIndexPath(indexPath) as! Playlist
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						self.mpdBridge.playPlaylist(playlist, shuffle: false, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdBridge.playPlaylist(playlist, shuffle: true, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(shuffleAction)
					let renameAction = UIAlertAction(title: NYXLocalizedString("lbl_rename_playlist"), style: .default) { (action) in
						self.renamePlaylistAction(playlist: playlist)
					}
					alertController.addAction(renameAction)
					let deleteAction = UIAlertAction(title: NYXLocalizedString("lbl_delete_playlist"), style: .destructive) { (action) in
						self.mpdBridge.deletePlaylist(named: playlist.name) { [weak self] (result) in
							guard let strongSelf = self else { return }
							switch result
							{
								case .failure(let error):
									DispatchQueue.main.async {
										MessageView.shared.showWithMessage(message: error.message)
									}
								case .success( _):
									strongSelf.mpdBridge.entitiesForType(.playlists) { (entities) in
										DispatchQueue.main.async {
											strongSelf.setItems(entities, forMusicalEntityType: .playlists)
											strongSelf.updateNavigationTitle()
										}
									}
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
					}
					alertController.addAction(deleteAction)
				default:
					break
			}

			present(alertController, animated: true, completion: nil)
		}
	}

	// MARK: - Buttons actions
	@objc func showServersListAction(_ sender: Any?)
	{
		let vc = ServersListVC(mpdBridge: mpdBridge)
		let nvc = NYXNavigationController(rootViewController: vc)
		vc.modalPresentationStyle = .overFullScreen
		vc.modalTransitionStyle = .coverVertical
		navigationController?.present(nvc, animated: true, completion: nil)
	}

	@objc func showSettingsAction(_ sender: Any?)
	{
		let vc = SettingsVC()
		let nvc = NYXNavigationController(rootViewController: vc)
		vc.modalPresentationStyle = .fullScreen
		vc.modalTransitionStyle = .flipHorizontal
		navigationController?.present(nvc, animated: true, completion: nil)
	}

	@objc func createPlaylistAction(_ sender: Any?)
	{
		let alertController = NYXAlertController(title: NYXLocalizedString("lbl_create_playlist_name"), message: nil, preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_save"), style: .default) { (alert) in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text)
			{
				let errorAlert = NYXAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel))
				self.present(errorAlert, animated: true, completion: nil)
			}
			else
			{
				self.mpdBridge.createPlaylist(named: textField.text!) { (result) in
					switch result
					{
						case .failure(let error):
							DispatchQueue.main.async {
								MessageView.shared.showWithMessage(message: error.message)
							}
						case .success( _):
							self.mpdBridge.entitiesForType(.playlists) { (entities) in
								DispatchQueue.main.async {
									self.setItems(entities, forMusicalEntityType: .playlists)
									self.updateNavigationTitle()
								}
							}
					}
				}
			}
		})
		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel))

		alertController.addTextField() { (textField) in
			textField.placeholder = NYXLocalizedString("lbl_create_playlist_placeholder")
			textField.textAlignment = .left
		}

		self.present(alertController, animated: true, completion: nil)
	}

	override func updateNavigationTitle()
	{
		mpdBridge.entitiesForType(dataSource.musicalEntityType) { (entities) in
			var title = ""
			switch self.dataSource.musicalEntityType
			{
				case .albums:
					title = NYXLocalizedString("lbl_albums")
				case .artists:
					title = NYXLocalizedString("lbl_artists")
				case .albumsartists:
					title = NYXLocalizedString("lbl_albumartists")
				case .genres:
					title = NYXLocalizedString("lbl_genres")
				case .playlists:
					title = NYXLocalizedString("lbl_playlists")
				default:
					break
			}
			DispatchQueue.main.async {
				self.titleView.setMainText(title, detailText: "(\(entities.count))")
			}
		}
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

		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_save"), style: .default) { (alert) in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text)
			{
				let errorAlert = NYXAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel))
				self.present(errorAlert, animated: true, completion: nil)
			}
			else
			{
				self.mpdBridge.rename(playlist: playlist, withNewName: textField.text!) { (result) in
					switch result
					{
						case .failure(let error):
							DispatchQueue.main.async {
								MessageView.shared.showWithMessage(message: error.message)
							}
						case .success( _):
							self.mpdBridge.entitiesForType(.playlists) { (entities) in
								DispatchQueue.main.async {
									self.setItems(entities, forMusicalEntityType: .playlists)
									self.updateNavigationTitle()
								}
							}
					}
				}
			}
		})
		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel))

		alertController.addTextField() { (textField) in
			textField.placeholder = NYXLocalizedString("lbl_rename_playlist_placeholder")
			textField.textAlignment = .left
		}

		present(alertController, animated: true, completion: nil)
	}

	// MARK: - Notifications
	@objc func audioServerConfigurationDidChange(_ aNotification: Notification)
	{
		serverChanged = true
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
		mpdBridge.entitiesForType(type) { (entities) in
			DispatchQueue.main.async {
				self.setItems(entities, forMusicalEntityType: type)
				if self.dataSource.items.count == 0
				{
					self.collectionView.collectionView.contentOffset = CGPoint(0, 64)
				}
				else
				{
					self.collectionView.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false) // Scroll to top
				}

				self.updateNavigationTitle()
				self.updateNavigationButtons()
			}
		}
	}

	@objc func showArtist(_ aNotification: Notification)
	{
		guard let artistName = aNotification.object as? String else { return }

		let vc = AlbumsListVC(artist: Artist(name: artistName), isAlbumArtist: false, mpdBridge: mpdBridge)
		navigationController?.pushViewController(vc, animated: true)
	}

	@objc func showAlbum(_ aNotification: Notification)
	{
		guard let album = aNotification.object as? Album else { return }

		let vc = AlbumDetailVC(album: album, mpdBridge: mpdBridge)
		navigationController?.pushViewController(vc, animated: true)
	}
}

// MARK: - MusicalCollectionViewDelegate
extension LibraryVC
{
	override func didSelectEntity(_ entity: AnyObject)
	{
		switch dataSource.musicalEntityType
		{
			case .albums:
				let vc = AlbumDetailVC(album: entity as! Album, mpdBridge: mpdBridge)
				navigationController?.pushViewController(vc, animated: true)
			case .artists:
				let vc = AlbumsListVC(artist: entity as! Artist, isAlbumArtist: false, mpdBridge: mpdBridge)
				navigationController?.pushViewController(vc, animated: true)
			case .albumsartists:
				let vc = AlbumsListVC(artist: entity as! Artist, isAlbumArtist: true, mpdBridge: mpdBridge)
				navigationController?.pushViewController(vc, animated: true)
			case .genres:
				let vc = GenreDetailVC(genre: entity as! Genre, mpdBridge: mpdBridge)
				navigationController?.pushViewController(vc, animated: true)
			case .playlists:
				let vc = PlaylistDetailVC(playlist: entity as! Playlist, mpdBridge: mpdBridge)
				navigationController?.pushViewController(vc, animated: true)
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
			if Settings.shared.bool(forKey: .pref_shakeToPlayRandom) == false
			{
				return
			}

			mpdBridge.entitiesForType(.albums) { [weak self] (entities) in
				guard let randomAlbum = entities.randomElement() as? Album else { return }
				self?.mpdBridge.playAlbum(randomAlbum, shuffle: false, loop: false)

				guard let url = randomAlbum.localCoverURL else { return }

				if let image = UIImage.loadFromFileURL(url)
				{
					DispatchQueue.main.async {
						let size = CGSize(256, 256)
						let imageView = UIImageView(frame: CGRect((UIScreen.main.bounds.width - size.width) / 2, (UIScreen.main.bounds.height - size.height) / 2, size))
						imageView.enableCorners()
						imageView.image = image
						self?.navigationController?.view.addSubview(imageView)
						imageView.shake(duration: 0.5, removeAtEnd: true)
					}
				}
			}
		}
	}
}

// MARK: - UIViewControllerPreviewingDelegate
extension LibraryVC
{
	override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
	{
		if let indexPath = collectionView.collectionView.indexPathForItem(at: location), let cellAttributes = collectionView.collectionView.layoutAttributesForItem(at: indexPath)
		{
			previewingContext.sourceRect = cellAttributes.frame
			switch dataSource.musicalEntityType
			{
				case .albums:
					let album = dataSource.currentItemAtIndexPath(indexPath) as! Album
					return AlbumDetailVC(album: album, mpdBridge: mpdBridge)
				case .artists, .albumsartists:
					let artist = dataSource.currentItemAtIndexPath(indexPath) as! Artist
					return AlbumsListVC(artist: artist, isAlbumArtist: dataSource.musicalEntityType == .albumsartists, mpdBridge: mpdBridge)
				case .genres:
					let genre = dataSource.currentItemAtIndexPath(indexPath) as! Genre
					return GenreDetailVC(genre: genre, mpdBridge: mpdBridge)
				case .playlists:
					let playlist = dataSource.currentItemAtIndexPath(indexPath) as! Playlist
					return PlaylistDetailVC(playlist: playlist, mpdBridge: mpdBridge)
				default:
					break
			}
		}
		return nil
	}
}
