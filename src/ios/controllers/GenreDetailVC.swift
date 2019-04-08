import UIKit


final class GenreDetailVC: MusicalCollectionVC
{
	// MARK: - Public properties
	// Selected genre
	let genre: Genre
	// Allowed display types
	override var allowedMusicalEntityTypes: [MusicalEntityType]
	{
		return [.albums, .artists, .albumsartists]
	}

	// MARK: - Initializers
	init(genre: Genre, mpdBridge: MPDBridge)
	{
		self.genre = genre

		super.init(mpdBridge: mpdBridge)

		dataSource = MusicalCollectionDataSourceAndDelegate(type: MusicalEntityType(rawValue: Settings.shared.integer(forKey: .lastTypeGenre)), delegate: self, mpdBridge: mpdBridge)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		switch dataSource.musicalEntityType
		{
			case .albums:
				mpdBridge.getAlbumsForGenre(genre, firstOnly: false) {
					[weak self] (albums) in
					DispatchQueue.main.async {
						self?.setItems(albums, forMusicalEntityType: self?.dataSource.musicalEntityType ?? .albums)
						self?.updateNavigationTitle()
					}
				}
			case .artists, .albumsartists:
				mpdBridge.getArtistsForGenre(genre, isAlbumArtist: dataSource.musicalEntityType == .albumsartists) {
					[weak self] (artists) in
					DispatchQueue.main.async {
						self?.setItems(artists, forMusicalEntityType: self?.dataSource.musicalEntityType ?? .artists)
						self?.updateNavigationTitle()
					}
				}
			default:
				break
		}

	}

	override func updateNavigationTitle()
	{
		var detailText: String?
		let count = dataSource.items.count
		switch dataSource.musicalEntityType
		{
			case .albums:
				detailText = "\(count) \(count == 1 ? NYXLocalizedString("lbl_album").lowercased() : NYXLocalizedString("lbl_albums").lowercased())"
			case .artists:
				detailText = "\(count) \(count == 1 ? NYXLocalizedString("lbl_artist").lowercased() : NYXLocalizedString("lbl_artists").lowercased())"
			case .albumsartists:
				detailText = "\(count) \(count == 1 ? NYXLocalizedString("lbl_albumartist").lowercased() : NYXLocalizedString("lbl_albumartists").lowercased())"
			default:
				break
		}
		titleView.setMainText(genre.name, detailText: detailText)
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

		Settings.shared.set(typeAsInt, forKey: .lastTypeGenre)
		switch type
		{
			case .albums:
				mpdBridge.getAlbumsForGenre(genre, firstOnly: false) {
					 [weak self] (albums) in
					DispatchQueue.main.async {
						self?.setItems(albums, forMusicalEntityType: type)
						self?.updateNavigationTitle()
					}
				}
			case .artists, .albumsartists:
				mpdBridge.getArtistsForGenre(genre, isAlbumArtist: type == .albumsartists) {
					 [weak self] (artists) in
					DispatchQueue.main.async {
						self?.setItems(artists, forMusicalEntityType: type)
						self?.updateNavigationTitle()
					}
				}
			default:
				break
		}

		if dataSource.items.count == 0
		{
			collectionView.collectionView.contentOffset = CGPoint(0, 64)
		}
		else
		{
			collectionView.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false) // Scroll to top
		}
	}
}

// MARK: - MusicalCollectionViewDelegate
extension GenreDetailVC
{
	override func didSelectEntity(_ entity: AnyObject)
	{
		switch dataSource.musicalEntityType
		{
			case .albums:
				let vc = AlbumDetailVC(album: entity as! Album, mpdBridge: mpdBridge)
				navigationController?.pushViewController(vc, animated: true)
			case .artists, .albumsartists:
				let vc = AlbumsListVC(artist: entity as! Artist, isAlbumArtist: dataSource.musicalEntityType == .albumsartists, mpdBridge: mpdBridge)
				navigationController?.pushViewController(vc, animated: true)
			default:
				break
		}
	}
}

// MARK: - Peek & Pop
extension GenreDetailVC
{
	override var previewActionItems: [UIPreviewActionItem]
	{
		let playAction = UIPreviewAction(title: NYXLocalizedString("lbl_play"), style: .default) {
			[weak self] (action, viewController) in
			guard let strongSelf = self else { return }
			strongSelf.mpdBridge.getAlbumsForGenre(strongSelf.genre, firstOnly: false) { albums in
				strongSelf.mpdBridge.getTracksForAlbums(strongSelf.genre.albums) { (tracks) in
					let allTracks = strongSelf.genre.albums.compactMap { $0.tracks }.flatMap { $0 }
					strongSelf.mpdBridge.playTracks(allTracks, shuffle: false, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) {
			[weak self] (action, viewController) in
			guard let strongSelf = self else { return }
			strongSelf.mpdBridge.getAlbumsForGenre(strongSelf.genre, firstOnly: false) { albums in
				strongSelf.mpdBridge.getTracksForAlbums(strongSelf.genre.albums) { (tracks) in
					let allTracks = strongSelf.genre.albums.compactMap { $0.tracks }.flatMap { $0 }
					strongSelf.mpdBridge.playTracks(allTracks, shuffle: true, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let addQueueAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) {
			[weak self] (action, viewController) in
			guard let strongSelf = self else { return }
			strongSelf.mpdBridge.getAlbumsForGenre(strongSelf.genre, firstOnly: false) { albums in
				for album in strongSelf.genre.albums
				{
					strongSelf.mpdBridge.addAlbumToQueue(album)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, addQueueAction]
	}
}
