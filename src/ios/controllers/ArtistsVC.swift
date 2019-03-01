import UIKit


final class ArtistsVC : UIViewController
{
	// MARK: - Public properties
	// Collection View
	@IBOutlet var collectionView: MusicalCollectionView!
	// Selected genre
	var genre: Genre! = nil

	// MARK: - Private properties
	// Label in the navigationbar
	private var titleView: UILabel! = nil

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Remove back button label
		navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "btn-back")
		navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "btn-back")
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		// Navigation bar title
		titleView = UILabel(frame: CGRect(.zero, 100.0, 44.0))
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
		navigationItem.titleView = titleView

		// Display layout button
		let layoutCollectionViewAsCollection = Settings.shared.bool(forKey: kNYXPrefLayoutArtistsCollection)
		let displayButton = UIBarButtonItem(image: layoutCollectionViewAsCollection ? #imageLiteral(resourceName: "btn-display-list") : #imageLiteral(resourceName: "btn-display-collection"), style: .plain, target: self, action: #selector(changeCollectionLayoutType(_:)))
		displayButton.accessibilityLabel = NYXLocalizedString(layoutCollectionViewAsCollection ? "lbl_pref_layoutastable" : "lbl_pref_layoutascollection")
		navigationItem.leftBarButtonItems = [displayButton]
		navigationItem.leftItemsSupplementBackButton = true

		// CollectionView
		collectionView.myDelegate = self
		collectionView.displayType = .artists
		collectionView.layoutType = layoutCollectionViewAsCollection ? .collection : .table
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

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		if segue.identifier == "artists-to-albums"
		{
			guard let indexes = collectionView.indexPathsForSelectedItems else
			{
				return
			}

			if let indexPath = indexes.first
			{
				let vc = segue.destination as! AlbumsVC
				vc.artist = collectionView.items[indexPath.row] as? Artist
			}
		}
	}

	// MARK: - Actions
	@objc func changeCollectionLayoutType(_ sender: Any?)
	{
		var b = Settings.shared.bool(forKey: kNYXPrefLayoutArtistsCollection)
		b = !b
		Settings.shared.set(b, forKey: kNYXPrefLayoutArtistsCollection)
		Settings.shared.synchronize()

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
		let attrs = NSMutableAttributedString(string: genre.name + "\n", attributes: [NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Medium", size: 14.0)!])
		attrs.append(NSAttributedString(string: "\(collectionView.items.count) \(collectionView.items.count == 1 ? NYXLocalizedString("lbl_artist").lowercased() : NYXLocalizedString("lbl_artists").lowercased())", attributes: [NSAttributedString.Key.font : UIFont(name: "HelveticaNeue", size: 13.0)!]))
		titleView.attributedText = attrs
	}
}

// MARK: - MusicalCollectionViewDelegate
extension ArtistsVC : MusicalCollectionViewDelegate
{
	func isSearching(actively: Bool) -> Bool
	{
		return false
	}

	func didSelectItem(indexPath: IndexPath)
	{
		performSegue(withIdentifier: "artists-to-albums", sender: self)
	}
}

// MARK: - Peek & Pop
extension ArtistsVC
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
