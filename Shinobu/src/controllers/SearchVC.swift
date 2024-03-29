import UIKit
import Defaults

private let margin = CGFloat(10)

fileprivate enum SearchSection: Int, CaseIterable {
	case albums
	case artists
	case albumartists
}
fileprivate typealias SearchDataSource = UITableViewDiffableDataSource<SearchSection, MusicalEntity>
fileprivate typealias SearchSnapshot = NSDiffableDataSourceSnapshot<SearchSection, MusicalEntity>

final class SearchVC: NYXViewController {
	// MARK: - Private properties
	/// MPD Data source
	private let mpdBridge: MPDBridge
	/// Servers managerto get covers
	private let serverManager: ServerManager
	/// Blurred background view
	private let blurEffectView = UIVisualEffectView()
	/// Search view (searchbar + tableview)
	private let searchView = UIView()
	/// Custom search bar
	private var searchField: SearchField!
	/// Tableview for results
	private var tableView: UITableView! = nil
	/// Table data source
	private lazy var dataSource = makeDataSource()
	/// All MPD albums
	private var albums = [Album]()
	/// All MPD artists
	private var artists = [Artist]()
	/// All MPD album artists
	private var albumsartists = [Artist]()
	/// Albums search results
	private var albumsResults = [Album]()
	/// Artists search results
	private var artistsResults = [Artist]()
	/// Album artists search results
	private var albumsartistsResults = [Artist]()
	/// Searching flag
	private var searching = false
	/// Single tap gesture to dismiss
	private let singleTap = UITapGestureRecognizer()
	/// Frame of the keyboard when shown
	private var keyboardFrame = CGRect.zero
	/// Is the search view displayed at full height
	private var isFullHeight = false

	// MARK: - Initializers
	init(mpdBridge: MPDBridge) {
		self.mpdBridge = mpdBridge
		self.serverManager = ServerManager()

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		view.frame = CGRect(.zero, view.width, view.height)
		view.backgroundColor = .clear
		view.isOpaque = false

		// Blurred background
		blurEffectView.effect = UIBlurEffect(style: .dark)
		blurEffectView.frame = view.bounds
		blurEffectView.isUserInteractionEnabled = true
		view.addSubview(blurEffectView)

		let y = margin + (UIApplication.shared.mainWindow?.safeAreaInsets.top ?? 0)
		searchView.frame = CGRect(margin, y, view.width - (margin * 2), 44)
		searchView.backgroundColor = .black
		view.addSubview(searchView)

		searchField = SearchField(frame: CGRect(0, 0, searchView.width, 44))
		searchField.delegate = self
		searchField.placeholder = NYXLocalizedString("lbl_search_library")
		searchField.cancelButton.addTarget(self, action: #selector(closeAction(_:)), for: .touchUpInside)
		searchField.cancelButton.accessibilityLabel = NYXLocalizedString("lbl_close")
		searchView.addSubview(searchField)
		searchView.layer.cornerRadius = 10
		searchView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		searchView.clipsToBounds = true

		tableView = UITableView(frame: CGRect(0, searchField.maxY, searchView.width, searchView.height - searchField.height), style: .plain)
		tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: SearchResultTableViewCell.reuseIdentifier)
		tableView.rowHeight = 54
		tableView.separatorStyle = .none
		tableView.delegate = self
		tableView.tableFooterView = UIView()
		tableView.backgroundColor = .black
		searchView.addSubview(tableView)

		// Single tap to close view
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		singleTap.addTarget(self, action: #selector(singleTap(_:)))
		blurEffectView.addGestureRecognizer(singleTap)

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		mpdBridge.entitiesForType(.albums, callback: { entities in
			self.albums = entities as! [Album]
		})

		mpdBridge.entitiesForType(.artists, callback: { entities in
			self.artists = entities as! [Artist]
		})

		mpdBridge.entitiesForType(.albumsartists, callback: { entities in
			self.albumsartists = entities as! [Artist]
		})

		_ = searchField.becomeFirstResponder()

		applySnapshot(animatingDifferences: false)
	}

	// MARK: - Buttons actions
	@objc func closeAction(_ sender: Any?) {
		if searchField.hasText {
			searchField.clearText()
		} else {
			dismiss(animated: true, completion: nil)
		}
	}

	// MARK: - Notifications
	@objc func keyboardWillShow(_ aNotification: Notification?) {
		guard let notif = aNotification else { return }
		guard let userInfos = notif.userInfo else { return }
		guard let duration = userInfos["UIKeyboardAnimationDurationUserInfoKey"] as? Double else { return }
		guard let curve = userInfos["UIKeyboardAnimationCurveUserInfoKey"] as? UInt else { return }
		guard let kbFrame = userInfos["UIKeyboardFrameEndUserInfoKey"] as? CGRect else { return }
		keyboardFrame = kbFrame
		adjustSearchView(duration: duration, animationCurve: curve)
	}

	// MARK: - Gestures
	@objc func singleTap(_ gesture: UITapGestureRecognizer) {
		dismiss(animated: true, completion: nil)
	}

	// MARK: - Private
	private func handleEmptyView(tableView: UITableView, isEmpty: Bool) {
		if isEmpty {
			let emptyView = UIView(frame: tableView.bounds)
			emptyView.translatesAutoresizingMaskIntoConstraints = false
			emptyView.backgroundColor = tableView.backgroundColor

			let lbl = UILabel(frame: .zero)
			lbl.text = self.searchField.hasText ? NYXLocalizedString("lbl_no_search_results") : ""
			lbl.font = UIFont.systemFont(ofSize: 32, weight: .ultraLight)
			lbl.translatesAutoresizingMaskIntoConstraints = false
			lbl.tintColor = .label
			lbl.backgroundColor = emptyView.backgroundColor
			lbl.sizeToFit()
			emptyView.addSubview(lbl)
			lbl.x = ceil((emptyView.width - lbl.width) / 2)
			lbl.y = ceil((emptyView.height - lbl.height) / 2)

			tableView.backgroundView = emptyView
		} else {
			tableView.backgroundView = nil
		}
	}

	private func adjustSearchView(duration: Double = 0.4, animationCurve curve: UInt = 7) {
		if searchField.hasText {
			if isFullHeight == false {
				isFullHeight = true
				let fullHeight = (self.keyboardFrame.y - self.searchView.y) - margin
				UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16), animations: {
					self.searchView.height = fullHeight
					self.tableView.height = fullHeight - self.searchField.height
				}, completion: nil)
			}
		} else {
			if isFullHeight == true {
				isFullHeight = false
				UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16), animations: {
					self.searchView.height = 44
					self.tableView.height = 0
				}, completion: nil)
			}
		}
	}

	private func makeDataSource() -> SearchDataSource {
		let dataSource = SearchDataSource(
			tableView: tableView,
			cellProvider: { (tableView, indexPath, musicalEntity) ->
				UITableViewCell? in
				let cell = tableView.dequeueReusableCell(
					withIdentifier: SearchResultTableViewCell.reuseIdentifier,
					for: indexPath) as! SearchResultTableViewCell

				cell.isEvenCell = indexPath.row.isMultiple(of: 2)

				let img: UIImage
				var highlight = true
				var hasCover = false

				switch indexPath.section {
				case 0:
					let album = musicalEntity as! Album
					if let cover = album.asset(ofSize: .small) {
						img = cover
						highlight = false
						hasCover = true
					} else {
						img = UIImage(systemName: "photo")!
					}
				case 1:
					img = UIImage(systemName: "mic")!
				case 2:
					img = UIImage(systemName: "person")!
				default:
					return cell
				}

				cell.lblTitle.text = musicalEntity.name
				cell.imgView.image = hasCover ? img : img.withTintColor(.tertiaryLabel).withRenderingMode(.alwaysOriginal)
				cell.imgView.highlightedImage = highlight ? img.withTintColor(UIColor.shinobuTintColor) : img
				cell.imgView.contentMode = hasCover ? .scaleAspectFit : .center
				cell.buttonAction = {
					switch indexPath.section {
					case 0:
						self.mpdBridge.playAlbum(musicalEntity as! Album, shuffle: false, loop: false)
					case 1:
						let artist = musicalEntity as! Artist
						self.mpdBridge.getAlbumsForArtist(artist) { [weak self] (albums) in
							guard let strongSelf = self else { return }
							strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
								let arr = artist.albums.compactMap(\.tracks).flatMap { $0 }
								strongSelf.mpdBridge.playTracks(arr, shuffle: false, loop: false)
							}
						}
					case 2:
						let artist = musicalEntity as! Artist
						self.mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { [weak self] (albums) in
							guard let strongSelf = self else { return }
							strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
								let arr = artist.albums.compactMap(\.tracks).flatMap { $0 }
								strongSelf.mpdBridge.playTracks(arr, shuffle: false, loop: false)
							}
						}
					default:
						return
					}
				}

				return cell
			})
		return dataSource
	}

	private func applySnapshot(animatingDifferences: Bool = true) {
		var snapshot = SearchSnapshot()
		snapshot.appendSections([.albums, .artists, .albumartists])
		snapshot.appendItems(albumsResults, toSection: .albums)
		snapshot.appendItems(artistsResults, toSection: .artists)
		snapshot.appendItems(albumsartistsResults, toSection: .albumartists)
		// otherwide table header is not actualised ?
		//dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
		dataSource.applySnapshotUsingReloadData(snapshot)
	}
}

// MARK: - UITableViewDelegate
extension SearchVC: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			NotificationCenter.default.postOnMainThreadAsync(name: .showAlbumNotification, object: albumsResults[indexPath.row])
		} else {
			let artist = indexPath.section == 1 ? artistsResults[indexPath.row] : albumsartistsResults[indexPath.row]
			NotificationCenter.default.postOnMainThreadAsync(name: .showArtistNotification, object: artist.name)
		}
		self.dismiss(animated: true, completion: nil)
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		let sectionHeight = CGFloat(40)
		switch section {
		case 0:
			return albumsResults.isEmpty ? 0 : sectionHeight
		case 1:
			return artistsResults.isEmpty ? 0 : sectionHeight
		case 2:
			return albumsartistsResults.isEmpty ? 0 : sectionHeight
		default:
			return 0
		}
	}

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let containerHeight = CGFloat(40)
		let headerView = UIView(frame: CGRect(.zero, tableView.width, containerHeight))
		headerView.backgroundColor = tableView.backgroundColor

		let label = UILabel(frame: CGRect(8, 0, tableView.width - 16, headerView.height))
		label.font = UIFont.systemFont(ofSize: 18, weight: .light)
		label.backgroundColor = headerView.backgroundColor
		label.textColor = .secondaryLabel
		label.textAlignment = .center
		headerView.addSubview(label)

		let text: String
		switch section {
		case 0:
			text = "\(albumsResults.count) \(albumsResults.count == 1 ? NYXLocalizedString("lbl_album") : NYXLocalizedString("lbl_albums"))"
		case 1:
			text = "\(artistsResults.count) \(artistsResults.count == 1 ? NYXLocalizedString("lbl_artist") : NYXLocalizedString("lbl_artists"))"
		case 2:
			text = "\(albumsartistsResults.count) \(albumsartistsResults.count == 1 ? NYXLocalizedString("lbl_albumartist") : NYXLocalizedString("lbl_albumartists"))"
		default:
			text = ""
			return nil
		}

		label.text = text.uppercased()

		return headerView
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 1
	}

	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}

	// MARK: - Fix ugly glitch later
	/*func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
	 return UIContextMenuConfiguration(identifier: "\(indexPath.section):\(indexPath.row)" as NSString, previewProvider: nil, actionProvider: { (_) in
	 switch indexPath.section {
	 case 0:
	 let album = self.albumsResults[indexPath.row]
	 let playAction = UIAction(title: NYXLocalizedString("lbl_play"), image: #imageLiteral(resourceName: "btn-play").withRenderingMode(.alwaysTemplate)) { (_) in
	 self.mpdBridge.playAlbum(album, shuffle: false, loop: false)
	 }

	 let shuffleAction = UIAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), image: #imageLiteral(resourceName: "btn-random").withRenderingMode(.alwaysTemplate)) { (_) in
	 self.mpdBridge.playAlbum(album, shuffle: true, loop: false)
	 }

	 let addQueueAction = UIAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), image: #imageLiteral(resourceName: "btn-add").withRenderingMode(.alwaysTemplate)) { (_) in
	 self.mpdBridge.addAlbumToQueue(album)
	 }

	 return UIMenu(title: "", children: [playAction, shuffleAction, addQueueAction])
	 case 1:
	 let artist = self.artistsResults[indexPath.row]
	 let playAction = UIAction(title: NYXLocalizedString("lbl_play"), image: #imageLiteral(resourceName: "btn-play").withRenderingMode(.alwaysTemplate)) { (_) in
	 self.mpdBridge.getAlbumsForArtist(artist) { [weak self] (albums) in
	 guard let strongSelf = self else { return }
	 strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
	 let arr = artist.albums.compactMap(\.tracks).flatMap { $0 }
	 strongSelf.mpdBridge.playTracks(arr, shuffle: false, loop: false)
	 }
	 }
	 }
	 let shuffleAction = UIAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), image: #imageLiteral(resourceName: "btn-random").withRenderingMode(.alwaysTemplate)) { (_) in
	 self.mpdBridge.getAlbumsForArtist(artist) { [weak self] (albums) in
	 guard let strongSelf = self else { return }
	 strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
	 let arr = artist.albums.compactMap(\.tracks).flatMap { $0 }
	 strongSelf.mpdBridge.playTracks(arr, shuffle: true, loop: false)
	 }
	 }
	 }
	 let addQueueAction = UIAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), image: #imageLiteral(resourceName: "btn-add").withRenderingMode(.alwaysTemplate)) { (_) in
	 self.mpdBridge.getAlbumsForArtist(artist) { [weak self] (albums) in
	 guard let strongSelf = self else { return }
	 for album in artist.albums {
	 strongSelf.mpdBridge.addAlbumToQueue(album)
	 }
	 }
	 }
	 return UIMenu(title: "", children: [playAction, shuffleAction, addQueueAction])
	 case 2:
	 let artist = self.albumsartists[indexPath.row]
	 let playAction = UIAction(title: NYXLocalizedString("lbl_play"), image: #imageLiteral(resourceName: "btn-play").withRenderingMode(.alwaysTemplate)) { (_) in
	 self.mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { [weak self] (albums) in
	 guard let strongSelf = self else { return }
	 strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
	 let arr = artist.albums.compactMap(\.tracks).flatMap { $0 }
	 strongSelf.mpdBridge.playTracks(arr, shuffle: false, loop: false)
	 }
	 }
	 }
	 let shuffleAction = UIAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), image: #imageLiteral(resourceName: "btn-random").withRenderingMode(.alwaysTemplate)) { (_) in
	 self.mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { [weak self] (albums) in
	 guard let strongSelf = self else { return }
	 strongSelf.mpdBridge.getTracksForAlbums(artist.albums) { (tracks) in
	 let arr = artist.albums.compactMap(\.tracks).flatMap { $0 }
	 strongSelf.mpdBridge.playTracks(arr, shuffle: true, loop: false)
	 }
	 }
	 }
	 let addQueueAction = UIAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), image: #imageLiteral(resourceName: "btn-add").withRenderingMode(.alwaysTemplate)) { (_) in
	 self.mpdBridge.getAlbumsForArtist(artist, isAlbumArtist: true) { [weak self] (albums) in
	 guard let strongSelf = self else { return }
	 for album in artist.albums {
	 strongSelf.mpdBridge.addAlbumToQueue(album)
	 }
	 }
	 }
	 return UIMenu(title: "", children: [playAction, shuffleAction, addQueueAction])
	 default:
	 return nil
	 }
	 })
	 }

	 func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
	 guard let identifier = configuration.identifier as? String else { return nil }

	 guard let section = Int(identifier.split(separator: ":").first!), let row = Int(identifier.split(separator: ":").last!) else { return nil }

	 guard let cell = tableView.cellForRow(at: IndexPath(row: row, section: section)) as? SearchResultTableViewCell else { return nil }

	 return UITargetedPreview(view: cell)
	 }

	 func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
	 guard let identifier = configuration.identifier as? String else { return nil }

	 guard let section = Int(identifier.split(separator: ":").first!), let row = Int(identifier.split(separator: ":").last!) else { return nil }

	 guard let cell = tableView.cellForRow(at: IndexPath(row: row, section: section)) as? SearchResultTableViewCell else { return nil }

	 return UITargetedPreview(view: cell)
	 }

	 func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
	 guard let identifier = configuration.identifier as? String else { return }

	 guard let section = Int(identifier.split(separator: ":").first!), let row = Int(identifier.split(separator: ":").last!) else { return }

	 _ = tableView.cellForRow(at: IndexPath(row: row, section: section))
	 }*/
}

// MARK: - SearchFieldDelegate
extension SearchVC: SearchFieldDelegate {
	func searchFieldTextDidBeginEditing() {
		searching = true
	}

	func searchFieldTextDidEndEditing() {
		searching = false
	}

	func textDidChange(text: String?) {
		adjustSearchView()

		if String.isNullOrWhiteSpace(text) {
			albumsResults.removeAll()
			artistsResults.removeAll()
			albumsartistsResults.removeAll()
			applySnapshot(animatingDifferences: true)
			searchField.cancelButton.accessibilityLabel = NYXLocalizedString("lbl_close")
			return
		}

		guard let searchText = text else { return }

		if Defaults[.pref_fuzzySearch] {
			albumsResults = albums.filter { $0.name.fuzzySearch(withString: searchText) }
			artistsResults = artists.filter { $0.name.fuzzySearch(withString: searchText) }
			albumsartistsResults = albumsartists.filter { $0.name.fuzzySearch(withString: searchText) }
		} else {
			albumsResults = albums.filter { $0.name.localizedStandardContains(searchText) }
			artistsResults = artists.filter { $0.name.localizedStandardContains(searchText) }
			albumsartistsResults = albumsartists.filter { $0.name.localizedStandardContains(searchText) }
		}

		applySnapshot(animatingDifferences: true)
	}
}
