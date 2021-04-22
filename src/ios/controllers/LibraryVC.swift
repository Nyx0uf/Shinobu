import UIKit

final class LibraryVC: MusicalCollectionVC {
	// MARK: - Private properties
	// Audio server changed
	private var serverChanged = false

	// MARK: - Initializers
	override init(mpdBridge: MPDBridge) {
		super.init(mpdBridge: mpdBridge)

		dataSource = MusicalCollectionDataSourceAndDelegate(type: AppDefaults.lastTypeLibrary, delegate: self, mpdBridge: mpdBridge)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
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

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		handleFirstLaunch()

		checkInit()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		OperationManager.shared.cancelAllOperations()
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		[.portrait, .portraitUpsideDown]
	}

	// MARK: - Private
	private func handleFirstLaunch() {
		if AppDefaults.isFirstRun == true {
			showServersListAction(nil)
		}
	}

	private func checkInit() {
		// Initialize the mpd connection
		if mpdBridge.server == nil {
			if let server = ServerManager().getServer() {
				// Data source
				mpdBridge.server = server.mpd
				let resultDataSource = mpdBridge.initialize()
				switch resultDataSource {
				case .failure(let error):
					MessageView.shared.showWithMessage(message: error.message)
				case .success:
					mpdBridge.getAllEntities {
						self.mpdBridge.entitiesForType(self.dataSource.musicalEntityType) { (entities) in
							DispatchQueue.main.async {
								self.setItems(entities, forMusicalEntityType: self.dataSource.musicalEntityType)
								self.updateNavigationTitle()
								self.updateNavigationButtons()
							}
						}
					}
				}
			}
		}

		// Deselect cell
//		if let idxs = collectionView.collectionView.indexPathsForSelectedItems {
//			for indexPath in idxs {
//				collectionView.collectionView.deselectItem(at: indexPath, animated: true)
//			}
//		}

		// When entity type menu was displayed
		if navMenuDisplayed == false {
			// Refresh view
			mpdBridge.entitiesForType(dataSource.musicalEntityType) { (entities) in
				DispatchQueue.main.async {
					self.setItems(entities, forMusicalEntityType: self.dataSource.musicalEntityType)
					self.collectionView.collectionView.scrollToTop(animated: true)
					self.updateNavigationTitle()
					self.updateNavigationButtons()
				}
			}
			navMenuDisplayed = false
			serverChanged = false
		}
	}

	// MARK: - Gestures
	override func doubleTap(_ gest: UITapGestureRecognizer) {
		if gest.state != .ended {
			return
		}

		if let indexPath = collectionView.collectionView.indexPathForItem(at: gest.location(in: collectionView.collectionView)) {
			switch dataSource.musicalEntityType {
			case .albums:
				let album = dataSource.currentItemAtIndexPath(indexPath) as! Album
				mpdBridge.playAlbum(album, shuffle: false, loop: false)
			case .artists:
				let artist = dataSource.currentItemAtIndexPath(indexPath) as! Artist
				mpdBridge.getAlbumsForArtist(artist) { [weak self] (albums) in
					guard let strongSelf = self else { return }
					strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
						let arr = artist.albums.compactMap(\.tracks).flatMap { $0 }
						strongSelf.mpdBridge.playTracks(arr, shuffle: false, loop: false)
					}
				}
			case .albumsartists:
				let artist = dataSource.currentItemAtIndexPath(indexPath) as! Artist
				mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { [weak self] (albums) in
					guard let strongSelf = self else { return }
					strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
						let arr = artist.albums.compactMap(\.tracks).flatMap { $0 }
						strongSelf.mpdBridge.playTracks(arr, shuffle: false, loop: false)
					}
				}
			case .genres:
				let genre = dataSource.currentItemAtIndexPath(indexPath) as! Genre
				mpdBridge.getAlbumsForGenre(genre, firstOnly: false) { [weak self] (albums) in
					guard let strongSelf = self else { return }
					strongSelf.mpdBridge.getTracksForAlbums(genre.albums) { (tracks) in
						let arr = genre.albums.compactMap(\.tracks).flatMap { $0 }
						strongSelf.mpdBridge.playTracks(arr, shuffle: false, loop: false)
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

	// MARK: - Buttons actions
	@objc func showServersListAction(_ sender: Any?) {
		let serverVC = ServerVC(mpdBridge: mpdBridge)
		let nvc = NYXNavigationController(rootViewController: serverVC)
		nvc.presentationController?.delegate = self
		navigationController?.present(nvc, animated: true, completion: nil)
	}

	@objc func showSettingsAction(_ sender: Any?) {
		let settingsVC = SettingsVC()
		let nvc = NYXNavigationController(rootViewController: settingsVC)
		nvc.presentationController?.delegate = self
		nvc.modalTransitionStyle = .flipHorizontal
		UIApplication.shared.delegate?.window??.rootViewController?.present(nvc, animated: true, completion: nil)
	}

	@objc func createPlaylistAction(_ sender: Any?) {
		let alertController = NYXAlertController(title: NYXLocalizedString("lbl_create_playlist_name"), message: nil, preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_save"), style: .default) { (alert) in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text) {
				let errorAlert = NYXAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel))
				self.present(errorAlert, animated: true, completion: nil)
			} else {
				self.mpdBridge.createPlaylist(named: textField.text!) { (result) in
					switch result {
					case .failure(let error):
						DispatchQueue.main.async {
							MessageView.shared.showWithMessage(message: error.message)
						}
					case .success:
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

		alertController.addTextField { (textField) in
			textField.placeholder = NYXLocalizedString("lbl_create_playlist_placeholder")
			textField.textAlignment = .left
		}

		self.present(alertController, animated: true, completion: nil)
	}

	override func updateNavigationTitle() {
		mpdBridge.entitiesForType(dataSource.musicalEntityType) { (entities) in
			var title = ""
			switch self.dataSource.musicalEntityType {
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

	private func updateNavigationButtons() {
		// Search button
		let searchButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-search"), style: .plain, target: self, action: #selector(showSearchBarAction(_:)))
		searchButton.accessibilityLabel = NYXLocalizedString("lbl_search")
		if dataSource.musicalEntityType == .playlists {
			// Create playlist button
			let createButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-add"), style: .plain, target: self, action: #selector(createPlaylistAction(_:)))
			createButton.accessibilityLabel = NYXLocalizedString("lbl_create_playlist")
			navigationItem.rightBarButtonItems = [searchButton, createButton]
		} else {
			navigationItem.rightBarButtonItems = [searchButton]
		}
	}

	private func renamePlaylistAction(playlist: Playlist) {
		let alertController = NYXAlertController(title: "\(NYXLocalizedString("lbl_rename_playlist")) \(playlist.name)", message: nil, preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_save"), style: .default) { (alert) in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text) {
				let errorAlert = NYXAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel))
				self.present(errorAlert, animated: true, completion: nil)
			} else {
				self.mpdBridge.rename(playlist: playlist, withNewName: textField.text!) { (result) in
					switch result {
					case .failure(let error):
						DispatchQueue.main.async {
							MessageView.shared.showWithMessage(message: error.message)
						}
					case .success:
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

		alertController.addTextField { (textField) in
			textField.placeholder = NYXLocalizedString("lbl_rename_playlist_placeholder")
			textField.textAlignment = .left
		}

		present(alertController, animated: true, completion: nil)
	}

	// MARK: - Notifications
	@objc func audioServerConfigurationDidChange(_ aNotification: Notification) {
		serverChanged = true
	}

	@objc func showArtist(_ aNotification: Notification) {
		guard let artistName = aNotification.object as? String else { return }

		let avc = AlbumsListVC(artist: Artist(name: artistName), isAlbumArtist: false, mpdBridge: mpdBridge)
		navigationController?.pushViewController(avc, animated: true)
	}

	@objc func showAlbum(_ aNotification: Notification) {
		guard let album = aNotification.object as? Album else { return }

		let avc = AlbumDetailVC(album: album, mpdBridge: mpdBridge)
		navigationController?.pushViewController(avc, animated: true)
	}

	// MARK: - TypeChoiceVCDelegate
	override func didSelectDisplayType(_ type: MusicalEntityType) {
		// Ignore if type did not change
		if dataSource.musicalEntityType == type {
			return
		}

		AppDefaults.lastTypeLibrary = type

		// Refresh view
		mpdBridge.entitiesForType(type) { (entities) in
			DispatchQueue.main.async {
				self.setItems(entities, forMusicalEntityType: type)
				self.updateNavigationTitle()
				self.updateNavigationButtons()
				self.searchBar.placeholder = "\(NYXLocalizedString("lbl_search")) \(type.description.lowercased())"
				self.collectionView.collectionView.scrollToTop(animated: true)
			}
		}
	}
}

// MARK: - MusicalCollectionViewDelegate
extension LibraryVC {
	override func didSelectEntity(_ entity: AnyObject) {
		switch dataSource.musicalEntityType {
		case .albums:
			let avc = AlbumDetailVC(album: entity as! Album, mpdBridge: mpdBridge)
			navigationController?.pushViewController(avc, animated: true)
		case .artists:
			let avc = AlbumsListVC(artist: entity as! Artist, isAlbumArtist: false, mpdBridge: mpdBridge)
			navigationController?.pushViewController(avc, animated: true)
		case .albumsartists:
			let avc = AlbumsListVC(artist: entity as! Artist, isAlbumArtist: true, mpdBridge: mpdBridge)
			navigationController?.pushViewController(avc, animated: true)
		case .genres:
			let gvc = GenreDetailVC(genre: entity as! Genre, mpdBridge: mpdBridge)
			navigationController?.pushViewController(gvc, animated: true)
		case .playlists:
			let pvc = PlaylistDetailVC(playlist: entity as! Playlist, mpdBridge: mpdBridge)
			navigationController?.pushViewController(pvc, animated: true)
		default:
			break
		}
	}

	override func shouldDeletePlaytlist(_ playlist: AnyObject) {
		self.mpdBridge.deletePlaylist(named: (playlist as! Playlist).name) { [weak self] (result) in
			guard let strongSelf = self else { return }
			switch result {
			case .failure(let error):
				DispatchQueue.main.async {
					MessageView.shared.showWithMessage(message: error.message)
				}
			case .success:
				strongSelf.mpdBridge.entitiesForType(.playlists) { (entities) in
					DispatchQueue.main.async {
						strongSelf.setItems(entities, forMusicalEntityType: .playlists)
						strongSelf.updateNavigationTitle()
					}
				}
			}
		}
	}
}

// MARK: - UIResponder
extension LibraryVC {
	override var canBecomeFirstResponder: Bool {
		true
	}

	override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			if AppDefaults.pref_shakeToPlayRandom == false {
				return
			}

			mpdBridge.entitiesForType(.albums) { [weak self] (entities) in
				guard let randomAlbum = entities.randomElement() as? Album else { return }
				self?.mpdBridge.playAlbum(randomAlbum, shuffle: false, loop: false)

				if let image = randomAlbum.asset(ofSize: .large) {
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

// MARK: - UIAdaptivePresentationControllerDelegate
extension LibraryVC {
	func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		checkInit()
	}

	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return self.modalStyleForController(controller)
	}

	override func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		return self.modalStyleForController(controller)
	}

	private func modalStyleForController(_ controller: UIPresentationController) -> UIModalPresentationStyle {
		guard let nvc = controller.presentedViewController as? NYXNavigationController else {
			return controller.presentedViewController.isKind(of: TypeChoiceVC.self) ? .none : .automatic
		}
		guard let tvc = nvc.topViewController else { return .automatic }

		if tvc.isKind(of: SettingsVC.self) {
			return .fullScreen
		} else if tvc.isKind(of: TypeChoiceVC.self) {
			return .none
		} else {
			return .automatic
		}
	}
}
