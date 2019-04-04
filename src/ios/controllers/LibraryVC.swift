import UIKit


final class LibraryVC : MusicalCollectionVC
{
	// MARK: - Private properties
	// Audio server changed
	private var serverChanged = false

	// MARK: - Initializers
	override init(mpdBridge: MPDBridge)
	{
		super.init(mpdBridge: mpdBridge)

		dataSource = MusicalCollectionDataSourceAndDelegate(type: MusicalEntityType(rawValue: Settings.shared.integer(forKey: .lastTypeLibrary)), delegate: self, mpdBridge: mpdBridge)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

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
		NotificationCenter.default.addObserver(self, selector: #selector(miniPlayShouldExpandNotification(_:)), name: .miniPlayerShouldExpand, object: nil)
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

						MiniPlayerView.shared.mpdBridge = mpdBridge
				}
			}
			else
			{
				Logger.shared.log(type: .information, message: "No MPD server registered or enabled yet")
				self.showServersListAction(nil)
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
			mpdBridge.entitiesForType(dataSource.musicalEntityType) { (entities) in
				DispatchQueue.main.async {
					self.setItems(entities, forMusicalEntityType: self.dataSource.musicalEntityType)
					self.collectionView.setContentOffset(.zero, animated: false) // Scroll to top
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
					mpdBridge.playAlbum(album, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
				case .artists:
					let artist = dataSource.actualItems[indexPath.row] as! Artist
					self.mpdBridge.getAlbumsForArtist(artist) { (albums) in
						self.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
							let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
							self.mpdBridge.playTracks(ar, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
						}
					}
				case .albumsartists:
					let artist = dataSource.actualItems[indexPath.row] as! Artist
					self.mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { (albums) in
						self.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
							let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
							self.mpdBridge.playTracks(ar, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
						}
					}
				case .genres:
					let genre = dataSource.actualItems[indexPath.row] as! Genre
					self.mpdBridge.getAlbumsForGenre(genre, firstOnly: false) { albums in
						self.mpdBridge.getTracksForAlbums(genre.albums) { (tracks) in
							let ar = genre.albums.compactMap({$0.tracks}).flatMap({$0})
							self.mpdBridge.playTracks(ar, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
						}
					}
				case .playlists:
					let playlist = dataSource.actualItems[indexPath.row] as! Playlist
					mpdBridge.playPlaylist(playlist, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
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
						self.mpdBridge.playAlbum(album, shuffle: false, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdBridge.playAlbum(album, shuffle: true, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						self.mpdBridge.addAlbumToQueue(album)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .artists:
					let artist = dataSource.actualItems[indexPath.row] as! Artist
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForArtist(artist) { (albums) in
							self.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
								let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
								self.mpdBridge.playTracks(ar, shuffle: false, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForArtist(artist) { (albums) in
							self.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
								let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
								self.mpdBridge.playTracks(ar, shuffle: true, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForArtist(artist) { (albums) in
							for album in artist.albums
							{
								self.mpdBridge.addAlbumToQueue(album)
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
						self.mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { (albums) in
							self.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
								let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
								self.mpdBridge.playTracks(ar, shuffle: false, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { (albums) in
							self.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
								let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
								self.mpdBridge.playTracks(ar, shuffle: true, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { (albums) in
							for album in artist.albums
							{
								self.mpdBridge.addAlbumToQueue(album)
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
						self.mpdBridge.getAlbumsForGenre(genre, firstOnly: false) { albums in
							self.mpdBridge.getTracksForAlbums(genre.albums) { (tracks) in
								let ar = genre.albums.compactMap({$0.tracks}).flatMap({$0})
								self.mpdBridge.playTracks(ar, shuffle: false, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForGenre(genre, firstOnly: false) { albums in
							self.mpdBridge.getTracksForAlbums(genre.albums) { (tracks) in
								let ar = genre.albums.compactMap({$0.tracks}).flatMap({$0})
								self.mpdBridge.playTracks(ar, shuffle: true, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						self.mpdBridge.getAlbumsForGenre(genre, firstOnly: false) { albums in
							for album in genre.albums
							{
								self.mpdBridge.addAlbumToQueue(album)
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
						self.mpdBridge.playPlaylist(playlist, shuffle: false, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						self.mpdBridge.playPlaylist(playlist, shuffle: true, loop: false)
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
						self.mpdBridge.deletePlaylist(named: playlist.name) { (result: Result<Bool, MPDConnectionError>) in
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
	@objc func showServersListAction(_ sender: Any?)
	{
		let vc = ServersListVC(mpdBridge: self.mpdBridge)
		let nvc = NYXNavigationController(rootViewController: vc)
		vc.modalPresentationStyle = .overFullScreen
		vc.modalTransitionStyle = .coverVertical
		self.navigationController?.present(nvc, animated: true, completion: {

		})
	}

	@objc func showSettingsAction(_ sender: Any?)
	{
		let vc = SettingsVC()
		let nvc = NYXNavigationController(rootViewController: vc)
		vc.modalPresentationStyle = .fullScreen
		vc.modalTransitionStyle = .flipHorizontal
		self.navigationController?.present(nvc, animated: true, completion: {

		})
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
				self.mpdBridge.createPlaylist(named: textField.text!) { (result: Result<Bool, MPDConnectionError>) in
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
				self.mpdBridge.rename(playlist: playlist, withNewName: textField.text!) { (result: Result<Bool, MPDConnectionError>) in
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
		let vc = PlayerVC(mpdBridge: mpdBridge)
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
		mpdBridge.entitiesForType(type) { (entities) in
			DispatchQueue.main.async {
				self.setItems(entities, forMusicalEntityType: type)
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
		let entities = dataSource.actualItems
		if indexPath.row >= entities.count
		{
			return
		}
		let entity = entities[indexPath.row]

		switch dataSource.musicalEntityType
		{
			case .albums:
				let vc = AlbumDetailVC(album: entity as! Album, mpdBridge: mpdBridge)
				self.navigationController?.pushViewController(vc, animated: true)
			case .artists:
				let vc = AlbumsListVC(artist: entity as! Artist, isAlbumArtist: false, mpdBridge: mpdBridge)
				self.navigationController?.pushViewController(vc, animated: true)
			case .albumsartists:
				let vc = AlbumsListVC(artist: entity as! Artist, isAlbumArtist: true, mpdBridge: mpdBridge)
				self.navigationController?.pushViewController(vc, animated: true)
			case .genres:
				let vc = GenreDetailVC(genre: entity as! Genre, mpdBridge: mpdBridge)
				self.navigationController?.pushViewController(vc, animated: true)
			case .playlists:
				let vc = PlaylistDetailVC(playlist: entity as! Playlist, mpdBridge: mpdBridge)
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
			if Settings.shared.bool(forKey: .pref_shakeToPlayRandom) == false
			{
				return
			}

			mpdBridge.entitiesForType(.albums) { [weak self] (entities) in
				guard let randomAlbum = entities.randomElement() as? Album else { return }
				self?.mpdBridge.playAlbum(randomAlbum, shuffle: false, loop: false)
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
					return AlbumDetailVC(album: album, mpdBridge: mpdBridge)
				case .artists, .albumsartists:
					let artist = dataSource.actualItems[row] as! Artist
					return AlbumsListVC(artist: artist, isAlbumArtist: dataSource.musicalEntityType == .albumsartists, mpdBridge: mpdBridge)
				case .genres:
					let genre = dataSource.actualItems[row] as! Genre
					return GenreDetailVC(genre: genre, mpdBridge: mpdBridge)
				case .playlists:
					let playlist = dataSource.actualItems[row] as! Playlist
					return PlaylistDetailVC(playlist: playlist, mpdBridge: mpdBridge)
				default:
					break
			}
		}
		return nil
	}
}
