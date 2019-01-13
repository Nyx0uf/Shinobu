// LibraryVC.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit


final class LibraryVC : UIViewController, CenterViewController
{
	// MARK: - Private properties
	// Albums view
	@IBOutlet private var collectionView: MusicalCollectionView!
	// Top constraint for collection view
	@IBOutlet private var topConstraint: NSLayoutConstraint!
	// Search view
	private var searchView: UIView! = nil
	// Search bar
	private var searchBar: UISearchBar! = nil
	// Button in the navigationbar
	private var titleView: UIButton! = nil
	// Should show the search view, flag
	private var searchBarVisible = false
	// Is currently searching, flag
	private var searching = false
	// Long press gesture is recognized, flag
	private var longPressRecognized = false
	// View to change the type of items in the collection view
	private var _typeChoiceView: TypeChoiceView! = nil
	// Active display type
	private var _displayType = DisplayType(rawValue: Settings.shared.integer(forKey: kNYXPrefDisplayType))!
	// Audio server changed
	private var _serverChanged = false
	// Previewing context for peek & pop
	private var _previewingContext: UIViewControllerPreviewing! = nil
	// Long press gesture for devices without force touch
	private var _longPress: UILongPressGestureRecognizer! = nil
	// MARK: - Public properties
	// Delegate
	var containerDelegate: ContainerVCDelegate? = nil

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Remove back button label
		navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "btn-back")
		navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "btn-back")
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		// Search button
		let searchButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-search"), style: .plain, target: self, action: #selector(showSearchBarAction(_:)))
		searchButton.accessibilityLabel = NYXLocalizedString("lbl_search")
		navigationItem.rightBarButtonItems = [searchButton]

		// Menu button
		let menuButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-hamb"), style: .plain, target: self, action: #selector(showLeftViewAction(_:)))
		menuButton.accessibilityLabel = NYXLocalizedString("vo_displaymenu")
		// Display layout button
		let layoutCollectionViewAsCollection = Settings.shared.bool(forKey: kNYXPrefLayoutLibraryCollection)
		let displayButton = UIBarButtonItem(image: layoutCollectionViewAsCollection ? #imageLiteral(resourceName: "btn-display-list") : #imageLiteral(resourceName: "btn-display-collection"), style: .plain, target: self, action: #selector(changeCollectionLayoutType(_:)))
		displayButton.accessibilityLabel = NYXLocalizedString(layoutCollectionViewAsCollection ? "lbl_pref_layoutastable" : "lbl_pref_layoutascollection")
		navigationItem.leftBarButtonItems = [menuButton, displayButton]

		// Searchbar
		let navigationBar = (navigationController?.navigationBar)!
		searchView = UIView(frame: CGRect(0.0, 0.0, navigationBar.width, navigationBar.bottom))
		searchBar = UISearchBar(frame: CGRect(0.0, navigationBar.y, navigationBar.width, navigationBar.height))
		searchView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		searchView.alpha = 0.0
		searchBar.searchBarStyle = .minimal
		searchBar.barTintColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		searchBar.tintColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		(searchBar.value(forKey: "searchField") as? UITextField)?.textColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		searchBar.showsCancelButton = true
		searchBar.delegate = self
		searchView.addSubview(searchBar)

		// Navigation bar title
		titleView = UIButton(frame: CGRect(0.0, 0.0, 100.0, navigationBar.height))
		titleView.addTarget(self, action: #selector(changeTypeAction(_:)), for: .touchUpInside)
		navigationItem.titleView = titleView

		// Collection view
		collectionView.myDelegate = self
		collectionView.layoutType = layoutCollectionViewAsCollection ? .collection : .table

		// Longpress
		_longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
		_longPress.minimumPressDuration = 0.5
		_longPress.delaysTouchesBegan = true
		updateLongpressState()

		// Double tap
		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
		doubleTap.numberOfTapsRequired = 2
		doubleTap.numberOfTouchesRequired = 1
		doubleTap.delaysTouchesBegan = true
		collectionView.addGestureRecognizer(doubleTap)

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
			if let serverAsData = Settings.shared.data(forKey: kNYXPrefMPDServer)
			{
				do
				{
					let server = try JSONDecoder().decode(AudioServer.self, from: serverAsData)
					// Data source
					MusicDataSource.shared.server = server
					let resultDataSource = MusicDataSource.shared.initialize()
					if resultDataSource.succeeded == false
					{
						MessageView.shared.showWithMessage(message: resultDataSource.messages.first!)
					}
					if _displayType != .albums
					{
						// Always fetch the albums list
						MusicDataSource.shared.getListForDisplayType(.albums) {}
					}
					MusicDataSource.shared.getListForDisplayType(_displayType) {
						DispatchQueue.main.async {
							self.collectionView.items = MusicDataSource.shared.selectedList()
							self.collectionView.displayType = self._displayType
							self.collectionView.reloadData()
							self.updateNavigationTitle()
							self.updateNavigationButtons()
						}
					}

					// Player
					PlayerController.shared.server = server
					let resultPlayer = PlayerController.shared.initialize()
					if resultPlayer.succeeded == false
					{
						MessageView.shared.showWithMessage(message: resultPlayer.messages.first!)
					}
				}
				catch
				{
					let alertController = UIAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_server_need_check"), preferredStyle: .alert)
					let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel, handler: nil)
					alertController.addAction(cancelAction)
					present(alertController, animated: true, completion: nil)
				}
			}
			else
			{
				Logger.shared.log(type: .debug, message: "No MPD server registered yet")
				containerDelegate?.showServerVC()
			}
		}

		// Since we are in search mode, show the bar
		if searchView.superview == nil
		{
			navigationController?.view.addSubview(searchView)
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
		if _serverChanged
		{
			// Refresh view
			MusicDataSource.shared.getListForDisplayType(_displayType) {
				DispatchQueue.main.async {
					self.collectionView.items = MusicDataSource.shared.selectedList()
					self.collectionView.displayType = self._displayType
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
				let result = PlayerController.shared.reinitialize()
				if result.succeeded == false
				{
					MessageView.shared.showWithMessage(message: result.messages.first!)
				}
			}

			_serverChanged = false
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		OperationManager.shared.cancelAllOperations()

		if searchView.superview != nil
		{
			searchView.removeFromSuperview()
		}
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .default
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		super.prepare(for: segue, sender: sender)
		
		if segue.identifier == "root-albums-to-detail-album"
		{
			let row = collectionView.indexPathsForSelectedItems![0].row
			let album = searching ? collectionView.searchResults[row] as! Album : MusicDataSource.shared.albums[row]
			let vc = segue.destination as! AlbumDetailVC
			vc.album = album
		}
		else if segue.identifier == "root-genres-to-artists"
		{
			let row = collectionView.indexPathsForSelectedItems![0].row
			let genre = searching ? collectionView.searchResults[row] as! Genre : MusicDataSource.shared.genres[row]
			let vc = segue.destination as! ArtistsVC
			vc.genre = genre
		}
		else if segue.identifier == "root-artists-to-albums"
		{
			let row = collectionView.indexPathsForSelectedItems![0].row
			let artist = searching ? collectionView.searchResults[row] as! Artist : (_displayType == .artists ? MusicDataSource.shared.artists[row] : MusicDataSource.shared.albumsartists[row])
			let vc = segue.destination as! AlbumsVC
			vc.artist = artist
		}
		else if segue.identifier == "root-playlists-to-detail-playlist"
		{
			let row = collectionView.indexPathsForSelectedItems![0].row
			let playlist = searching ? collectionView.searchResults[row] as! Playlist : MusicDataSource.shared.playlists[row]
			let vc = segue.destination as! PlaylistDetailVC
			vc.playlist = playlist
		}
	}

	// MARK: - Gestures
	@objc func doubleTap(_ gest: UITapGestureRecognizer)
	{
		if gest.state != .ended
		{
			return
		}

		if let indexPath = collectionView.indexPathForItem(at: gest.location(in: collectionView))
		{
			switch _displayType
			{
				case .albums:
					let album = searching ? collectionView.searchResults[indexPath.row] as! Album : MusicDataSource.shared.albums[indexPath.row]
					PlayerController.shared.playAlbum(album, shuffle: Settings.shared.bool(forKey: kNYXPrefMPDShuffle), loop: Settings.shared.bool(forKey: kNYXPrefMPDRepeat))
				case .artists:
					let artist = searching ? collectionView.searchResults[indexPath.row] as! Artist : MusicDataSource.shared.artists[indexPath.row]
					MusicDataSource.shared.getAlbumsForArtist(artist) {
						MusicDataSource.shared.getTracksForAlbums(artist.albums) {
							let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
							PlayerController.shared.playTracks(ar, shuffle: Settings.shared.bool(forKey: kNYXPrefMPDShuffle), loop: Settings.shared.bool(forKey: kNYXPrefMPDRepeat))
						}
					}
				case .albumsartists:
					let artist = searching ? collectionView.searchResults[indexPath.row] as! Artist : MusicDataSource.shared.albumsartists[indexPath.row]
					MusicDataSource.shared.getAlbumsForArtist(artist, isAlbumArtist: true) {
						MusicDataSource.shared.getTracksForAlbums(artist.albums) {
							let ar = artist.albums.compactMap({$0.tracks}).flatMap({$0})
							PlayerController.shared.playTracks(ar, shuffle: Settings.shared.bool(forKey: kNYXPrefMPDShuffle), loop: Settings.shared.bool(forKey: kNYXPrefMPDRepeat))
						}
					}
				case .genres:
					let genre = searching ? collectionView.searchResults[indexPath.row] as! Genre : MusicDataSource.shared.genres[indexPath.row]
					MusicDataSource.shared.getAlbumsForGenre(genre, firstOnly: false) {
						MusicDataSource.shared.getTracksForAlbums(genre.albums) {
							let ar = genre.albums.compactMap({$0.tracks}).flatMap({$0})
							PlayerController.shared.playTracks(ar, shuffle: Settings.shared.bool(forKey: kNYXPrefMPDShuffle), loop: Settings.shared.bool(forKey: kNYXPrefMPDRepeat))
						}
					}
				case .playlists:
					let playlist = searching ? collectionView.searchResults[indexPath.row] as! Playlist : MusicDataSource.shared.playlists[indexPath.row]
					PlayerController.shared.playPlaylist(playlist, shuffle: Settings.shared.bool(forKey: kNYXPrefMPDShuffle), loop: Settings.shared.bool(forKey: kNYXPrefMPDRepeat))
			}
		}
	}

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
			let cell = collectionView.cellForItem(at: indexPath) as! MusicalEntityBaseCell
			cell.longPressed = true

			let alertController = UIAlertController(title: nil, message: nil, preferredStyle:.actionSheet)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel) { (action) in
				self.longPressRecognized = false
				cell.longPressed = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(cancelAction)

			switch _displayType
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
						MusicDataSource.shared.deletePlaylist(name: playlist.name) { (result: ActionResult<Void>) in
							if result.succeeded
							{
								MusicDataSource.shared.getListForDisplayType(.playlists) {
									DispatchQueue.main.async {
										self.collectionView.items = MusicDataSource.shared.selectedList()
										self.collectionView.reloadData()
										self.updateNavigationTitle()
									}
								}
							}
							else
							{
								DispatchQueue.main.async {
									MessageView.shared.showWithMessage(message: result.messages.first!)
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
		if _typeChoiceView == nil
		{
			_typeChoiceView = TypeChoiceView(frame: CGRect(0.0, (self.navigationController?.navigationBar.bottom)!, collectionView.width, 220.0))
			_typeChoiceView.delegate = self
		}

		if _typeChoiceView.superview != nil
		{ // Is visible
			//self.collectionView.contentInset = UIEdgeInsets(top: (self.navigationController?.navigationBar.bottom)!, left: 0.0, bottom: 0.0, right: 0.0)
			topConstraint.constant = 0.0
			UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
				self.view.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
				self.view.layoutIfNeeded()
				if MusicDataSource.shared.selectedList().count == 0
				{
					self.collectionView.contentOffset = CGPoint(0, (self.navigationController?.navigationBar.bottom)!)
				}
				else
				{
					self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
				}
			}, completion: { finished in
				self._typeChoiceView.removeFromSuperview()
			})
		}
		else
		{ // Is hidden
			_typeChoiceView.tableView.reloadData()
			view.insertSubview(_typeChoiceView, belowSubview:collectionView)
			topConstraint.constant = _typeChoiceView.bottom;

			UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
				self.collectionView.contentInset = .zero
				self.view.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
			}, completion:nil)
		}
	}

	@objc func showSearchBarAction(_ sender: Any?)
	{
		UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
			self.searchView.alpha = 1.0
			self.searchBar.becomeFirstResponder()
		}, completion:{ finished in
			self.searchBarVisible = true
		})
	}

	@objc func showLeftViewAction(_ sender: Any?)
	{
		containerDelegate?.toggleMenu()
	}

	@objc func changeCollectionLayoutType(_ sender: Any?)
	{
		var b = Settings.shared.bool(forKey: kNYXPrefLayoutLibraryCollection)
		b = !b
		Settings.shared.set(b, forKey: kNYXPrefLayoutLibraryCollection)
		Settings.shared.synchronize()

		collectionView.layoutType = b ? .collection : .table
		if let buttons = navigationItem.leftBarButtonItems
		{
			if buttons.count >= 2
			{
				let btn = buttons[1]
				btn.image = b ? #imageLiteral(resourceName: "btn-display-list") : #imageLiteral(resourceName: "btn-display-collection")
				btn.accessibilityLabel = NYXLocalizedString(b ? "lbl_pref_layoutastable" : "lbl_pref_layoutascollection")
			}
		}
	}

	@objc func createPlaylistAction(_ sender: Any?)
	{
		let alertController = UIAlertController(title: NYXLocalizedString("lbl_create_playlist_name"), message: nil, preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_save"), style: .default, handler: { alert -> Void in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text)
			{
				let errorAlert = UIAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel, handler: { alert -> Void in
				}))
				self.present(errorAlert, animated: true, completion: nil)
			}
			else
			{
				MusicDataSource.shared.createPlaylist(name: textField.text!) { (result: ActionResult<Void>) in
					if result.succeeded
					{
						MusicDataSource.shared.getListForDisplayType(.playlists) {
							DispatchQueue.main.async {
								self.collectionView.items = MusicDataSource.shared.selectedList()
								self.collectionView.reloadData()
								self.updateNavigationTitle()
							}
						}
					}
					else
					{
						DispatchQueue.main.async {
							MessageView.shared.showWithMessage(message: result.messages.first!)
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
	private func showNavigationBar(animated: Bool = true)
	{
		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay: 0.0, options: .curveEaseOut, animations: {
			self.searchBar.resignFirstResponder()
			self.searchView.alpha = 0.0
		}, completion:{ finished in
			self.searchBarVisible = false
		})
	}

	private func updateNavigationTitle()
	{
		let p = NSMutableParagraphStyle()
		p.alignment = .center
		p.lineBreakMode = .byWordWrapping
		var title = ""
		switch _displayType
		{
			case .albums:
				let n = MusicDataSource.shared.albums.count
				title = "\(n) \(n == 1 ? NYXLocalizedString("lbl_album") : NYXLocalizedString("lbl_albums"))"
			case .artists:
				let n = MusicDataSource.shared.artists.count
				title = "\(n) \(n == 1 ? NYXLocalizedString("lbl_artist") : NYXLocalizedString("lbl_artists"))"
			case .albumsartists:
				let n = MusicDataSource.shared.albumsartists.count
				title = "\(n) \(n == 1 ? NYXLocalizedString("lbl_albumartist") : NYXLocalizedString("lbl_albumartists"))"
			case .genres:
				let n = MusicDataSource.shared.genres.count
				title = "\(n) \(n == 1 ? NYXLocalizedString("lbl_genre") : NYXLocalizedString("lbl_genres"))"
			case .playlists:
				let n = MusicDataSource.shared.playlists.count
				title = "\(n) \(n == 1 ? NYXLocalizedString("lbl_playlist") : NYXLocalizedString("lbl_playlists"))"
		}
		let astr1 = NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1), NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Medium", size: 14.0)!, NSAttributedString.Key.paragraphStyle : p])
		titleView.setAttributedTitle(astr1, for: .normal)
		let astr2 = NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1), NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Medium", size: 14.0)!, NSAttributedString.Key.paragraphStyle : p])
		titleView.setAttributedTitle(astr2, for: .highlighted)
	}

	private func updateLongpressState()
	{
		#if NYX_DEBUG
			collectionView.addGestureRecognizer(_longPress)
			_longPress.isEnabled = true
		#else
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
		#endif
	}

	private func updateNavigationButtons()
	{
		// Search button
		let searchButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-search"), style: .plain, target: self, action: #selector(showSearchBarAction(_:)))
		searchButton.accessibilityLabel = NYXLocalizedString("lbl_search")
		if _displayType == .playlists
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
		let alertController = UIAlertController(title: "\(NYXLocalizedString("lbl_rename_playlist")) \(playlist.name)", message: nil, preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_save"), style: .default, handler: { alert -> Void in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text)
			{
				let errorAlert = UIAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel, handler: { alert -> Void in
				}))
				self.present(errorAlert, animated: true, completion: nil)
			}
			else
			{
				MusicDataSource.shared.renamePlaylist(playlist: playlist, newName: textField.text!) { (result: ActionResult<Void>) in
					if result.succeeded
					{
						MusicDataSource.shared.getListForDisplayType(.playlists) {
							DispatchQueue.main.async {
								self.collectionView.items = MusicDataSource.shared.selectedList()
								self.collectionView.reloadData()
								self.updateNavigationTitle()
							}
						}
					}
					else
					{
						DispatchQueue.main.async {
							MessageView.shared.showWithMessage(message: result.messages.first!)
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
		_serverChanged = true
	}

	@objc func miniPlayShouldExpandNotification(_ aNotification: Notification)
	{
		self.navigationController?.performSegue(withIdentifier: "root-to-player", sender: self.navigationController)
	}
}

// MARK: - MusicalCollectionViewDelegate
extension LibraryVC : MusicalCollectionViewDelegate
{
	func isSearching(actively: Bool) -> Bool
	{
		return actively ? (self.searching && searchBar.isFirstResponder == true) : self.searching
	}

	func didSelectItem(indexPath: IndexPath)
	{
		// If menu is visible ignore default behavior and hide it
		if (containerDelegate?.isMenuVisible())!
		{
			collectionView.deselectItem(at: indexPath, animated: false)
			showLeftViewAction(nil)
			return
		}

		switch _displayType
		{
			case .albums:
				performSegue(withIdentifier: "root-albums-to-detail-album", sender: self)
			case .artists:
				performSegue(withIdentifier: "root-artists-to-albums", sender: self)
			case .albumsartists:
				performSegue(withIdentifier: "root-artists-to-albums", sender: self)
			case .genres:
				performSegue(withIdentifier: "root-genres-to-artists", sender: self)
			case .playlists:
				performSegue(withIdentifier: "root-playlists-to-detail-playlist", sender: self)
		}
	}
}

// MARK: - UISearchBarDelegate
extension LibraryVC : UISearchBarDelegate
{
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
	{
		collectionView.searchResults.removeAll()
		searching = false
		searchBar.text = ""
		showNavigationBar(animated: true)
		collectionView.reloadData()
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
	{
		searchBar.resignFirstResponder()
		searchBar.endEditing(true)
		collectionView.reloadData()
	}

	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
	{
		searching = true
		// Copy original source to avoid crash when nothing was searched
		collectionView.searchResults = MusicDataSource.shared.selectedList()
	}

	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
	{
		if MusicDataSource.shared.selectedList().count > 0
		{
			if String.isNullOrWhiteSpace(searchText)
			{
				collectionView.searchResults = MusicDataSource.shared.selectedList()
				collectionView.reloadData()
				return
			}

			if Settings.shared.bool(forKey: kNYXPrefFuzzySearch)
			{
				collectionView.searchResults = MusicDataSource.shared.selectedList().filter({$0.name.fuzzySearch(withString: searchText)})
			}
			else
			{
				collectionView.searchResults = MusicDataSource.shared.selectedList().filter({$0.name.lowercased().contains(searchText.lowercased())})
			}

			collectionView.reloadData()
		}
	}
}

// MARK: - TypeChoiceViewDelegate
extension LibraryVC : TypeChoiceViewDelegate
{
	func didSelectDisplayType(_ type: DisplayType)
	{
		// Ignore if type did not change
		if _displayType == type
		{
			changeTypeAction(nil)
			return
		}
		_displayType = type

		Settings.shared.set(type.rawValue, forKey: kNYXPrefDisplayType)
		Settings.shared.synchronize()

		// Longpress / peek & pop
		updateLongpressState()

		// Refresh view
		MusicDataSource.shared.getListForDisplayType(type) {
			DispatchQueue.main.async {
				self.collectionView.items = MusicDataSource.shared.selectedList()
				self.collectionView.displayType = type
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
			if Settings.shared.bool(forKey: kNYXPrefShakeToPlayRandomAlbum) == false || MusicDataSource.shared.albums.count == 0
			{
				return
			}

			let randomAlbum = MusicDataSource.shared.albums.randomItem()
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

	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		if segue.identifier == "root-to-player"
		{
			let vc = segue.destination as! PlayerVC
			vc.transitioningDelegate = self
			vc.modalPresentationStyle = .custom
		}
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
			if _displayType == .albums
			{
				let vc = sb.instantiateViewController(withIdentifier: "AlbumDetailVC") as! AlbumDetailVC

				let album = searching ? collectionView.searchResults[row] as! Album : MusicDataSource.shared.albums[row]
				vc.album = album
				return vc
			}
			else if _displayType == .playlists
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
