import UIKit


final class GenreDetailVC : MusicalCollectionVC
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
	init(genre: Genre, mpdDataSource: MPDDataSource)
	{
		self.genre = genre

		super.init(mpdDataSource: mpdDataSource)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		dataSource = MusicalCollectionDataSourceAndDelegate(type: .albums, delegate: self, mpdDataSource: mpdDataSource)
		self.collectionView.musicalEntityType = dataSource.musicalEntityType
		self.collectionView.dataSource = dataSource
		self.collectionView.delegate = dataSource
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		mpdDataSource.getAlbumsForGenre(genre, firstOnly: false) { albums in
			DispatchQueue.main.async {
				self.setItems(albums, forMusicalEntityType: self.dataSource.musicalEntityType)
				self.updateNavigationTitle()
			}
		}
	}

	override func updateNavigationTitle()
	{
		var detailText: String?
		switch self.dataSource.musicalEntityType
		{
			case .albums:
				detailText = "\(dataSource.items.count) \(dataSource.items.count == 1 ? NYXLocalizedString("lbl_album").lowercased() : NYXLocalizedString("lbl_albums").lowercased())"
			case .artists:
				detailText = "\(dataSource.items.count) \(dataSource.items.count == 1 ? NYXLocalizedString("lbl_artist").lowercased() : NYXLocalizedString("lbl_artists").lowercased())"
			case .albumsartists:
				detailText = "\(dataSource.items.count) \(dataSource.items.count == 1 ? NYXLocalizedString("lbl_albumartist").lowercased() : NYXLocalizedString("lbl_albumartists").lowercased())"
			default:
				break
		}
		titleView.setMainText(genre.name, detailText: detailText)
	}

	override func didSelectDisplayType(_ typeAsInt: Int)
	{
		// Ignore if type did not change
		let type = MusicalEntityType(rawValue: typeAsInt)
		if dataSource.musicalEntityType == type || allowedMusicalEntityTypes.contains(type) == false
		{
			changeTypeAction(nil)
			return
		}

		// Longpress / peek & pop
		updateLongpressState()

		switch type
		{
			case .albums:
				mpdDataSource.getAlbumsForGenre(genre, firstOnly: false) { albums in
					DispatchQueue.main.async {
						self.setItems(albums, forMusicalEntityType: type)
						self.updateNavigationTitle()
					}
				}
			case .artists, .albumsartists:
				mpdDataSource.getArtistsForGenre(genre) { artists in
					DispatchQueue.main.async {
						self.setItems(artists, forMusicalEntityType: type)
						self.updateNavigationTitle()
					}
				}
			default:
				break
		}

		self.changeTypeAction(nil)
		if self.dataSource.items.count == 0
		{
			self.collectionView.contentOffset = CGPoint(0, 64)
		}
		else
		{
			self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false) // Scroll to top
		}
	}
}

// MARK: - MusicalCollectionViewDelegate
extension GenreDetailVC
{
	override func didSelectItem(indexPath: IndexPath)
	{
		let entities = searching ? dataSource.searchResults : dataSource.items
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
			case .artists, .albumsartists:
				let vc = AlbumsListVC(artist: entity as! Artist, isAlbumArtist: dataSource.musicalEntityType == .albumsartists, mpdDataSource: mpdDataSource)
				self.navigationController?.pushViewController(vc, animated: true)
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
			strongSelf.mpdDataSource.getAlbumsForGenre(strongSelf.genre, firstOnly: false) { albums in
				strongSelf.mpdDataSource.getTracksForAlbums(strongSelf.genre.albums) {
					let allTracks = strongSelf.genre.albums.compactMap({$0.tracks}).flatMap({$0})
					PlayerController.shared.playTracks(allTracks, shuffle: false, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) {
			[weak self] (action, viewController) in
			guard let strongSelf = self else { return }
			strongSelf.mpdDataSource.getAlbumsForGenre(strongSelf.genre, firstOnly: false) { albums in
				strongSelf.mpdDataSource.getTracksForAlbums(strongSelf.genre.albums) {
					let allTracks = strongSelf.genre.albums.compactMap({$0.tracks}).flatMap({$0})
					PlayerController.shared.playTracks(allTracks, shuffle: true, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let addQueueAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) {
			[weak self] (action, viewController) in
			guard let strongSelf = self else { return }
			strongSelf.mpdDataSource.getAlbumsForGenre(strongSelf.genre, firstOnly: false) { albums in
				for album in strongSelf.genre.albums
				{
					PlayerController.shared.addAlbumToQueue(album)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, addQueueAction]
	}
}
