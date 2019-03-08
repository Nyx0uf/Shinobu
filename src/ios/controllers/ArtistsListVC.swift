import UIKit


final class ArtistsListVC : NYXViewController
{
	// MARK: - Public properties
	// Collection View
	var collectionView: MusicalCollectionView!
	// Selected genre
	var genre: Genre

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
		// Remove back button label
		navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "btn-back")
		navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "btn-back")
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		// Display layout button
		let layoutCollectionViewAsCollection = Settings.shared.bool(forKey: .pref_layoutArtistsCollection)
		let displayButton = UIBarButtonItem(image: layoutCollectionViewAsCollection ? #imageLiteral(resourceName: "btn-display-list") : #imageLiteral(resourceName: "btn-display-collection"), style: .plain, target: self, action: #selector(changeCollectionLayoutType(_:)))
		displayButton.accessibilityLabel = NYXLocalizedString(layoutCollectionViewAsCollection ? "lbl_pref_layoutastable" : "lbl_pref_layoutascollection")
		navigationItem.leftBarButtonItems = [displayButton]
		navigationItem.leftItemsSupplementBackButton = true

		// CollectionView
		collectionView = MusicalCollectionView(frame: self.view.bounds, collectionViewLayout: UICollectionViewLayout())
		collectionView.myDelegate = self
		collectionView.displayType = .artists
		collectionView.layoutType = layoutCollectionViewAsCollection ? .collection : .table
		self.view.addSubview(collectionView)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		MusicDataSource.shared.getArtistsForGenre(genre) { (artists: [Artist]) in
			DispatchQueue.main.async {
				self.collectionView.items = artists
				self.collectionView.reloadData()
				self.updateNavigationTitle()
			}
		}
	}

	// MARK: - Actions
	@objc func changeCollectionLayoutType(_ sender: Any?)
	{
		var b = Settings.shared.bool(forKey: .pref_layoutArtistsCollection)
		b = !b
		Settings.shared.set(b, forKey: .pref_layoutArtistsCollection)

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
		let attrs = NSMutableAttributedString(string: genre.name + "\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .medium)])
		attrs.append(NSAttributedString(string: "\(collectionView.items.count) \(collectionView.items.count == 1 ? NYXLocalizedString("lbl_artist").lowercased() : NYXLocalizedString("lbl_artists").lowercased())", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13, weight: .regular)]))
		titleView.attributedText = attrs
	}
}

// MARK: - MusicalCollectionViewDelegate
extension ArtistsListVC : MusicalCollectionViewDelegate
{
	func isSearching(actively: Bool) -> Bool
	{
		return false
	}

	func didSelectItem(indexPath: IndexPath)
	{
		let artist = collectionView.items[indexPath.row] as! Artist
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
