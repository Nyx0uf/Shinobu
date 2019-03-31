import UIKit


final class ArtistsListVC : MusicalCollectionVC
{
	// MARK: - Public properties
	// Selected genre
	let genre: Genre

	// MARK: - Initializers
	init(genre: Genre)
	{
		self.genre = genre
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

		self.collectionView.displayType = .artists
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		MusicDataSource.shared.getArtistsForGenre(genre) { (artists: [Artist]) in
			DispatchQueue.main.async {
				self.dataSource.setItems(artists, forType: .artists)
				self.collectionView.reloadData()
				self.updateNavigationTitle()
			}
		}
	}

	// MARK: - Private
	private func updateNavigationTitle()
	{
		titleView.setMainText(genre.name, detailText: "\(dataSource.items.count) \(dataSource.items.count == 1 ? NYXLocalizedString("lbl_artist").lowercased() : NYXLocalizedString("lbl_artists").lowercased())")
	}
}

// MARK: - MusicalCollectionViewDelegate
extension ArtistsListVC
{
	override func didSelectItem(indexPath: IndexPath)
	{
		let artist = searching ? dataSource.searchResults[indexPath.row] as! Artist : dataSource.items[indexPath.row] as! Artist
		let vc = AlbumsListVC(artist: artist)
		self.navigationController?.pushViewController(vc, animated: true)
	}
}

// MARK: - Peek & Pop
extension ArtistsListVC
{
	override var previewActionItems: [UIPreviewActionItem]
	{
		let playAction = UIPreviewAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action, viewController) in
			MusicDataSource.shared.getAlbumsForGenre(self.genre, firstOnly: false) {
				MusicDataSource.shared.getTracksForAlbums(self.genre.albums) {
					let ar = self.genre.albums.compactMap({$0.tracks}).flatMap({$0})
					PlayerController.shared.playTracks(ar, shuffle: false, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action, viewController) in
			MusicDataSource.shared.getAlbumsForGenre(self.genre, firstOnly: false) {
				MusicDataSource.shared.getTracksForAlbums(self.genre.albums) {
					let ar = self.genre.albums.compactMap({$0.tracks}).flatMap({$0})
					PlayerController.shared.playTracks(ar, shuffle: true, loop: false)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		let addQueueAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action, viewController) in
			MusicDataSource.shared.getAlbumsForGenre(self.genre, firstOnly: false) {
				for album in self.genre.albums
				{
					PlayerController.shared.addAlbumToQueue(album)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, addQueueAction]
	}
}
