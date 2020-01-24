import UIKit

class MusicalCollectionVC: NYXViewController {
	// MARK: - Public properties
	// Collection view
	private(set) var collectionView: MusicalCollectionView!
	// Collection view's data source & delegate
	var dataSource: MusicalCollectionDataSourceAndDelegate!
	// Search view
	private(set) var searchView: UIView! = nil
	// Search bar
	private(set) var searchBar: UISearchBar! = nil
	// Should show the search view, flag
	private(set) var searchBarVisible = false
	// Is currently searching, flag
	private(set) var searching = false
	// The type choice menu is displayed
	var navMenuDisplayed = true
	// MPD Data source
	let mpdBridge: MPDBridge
	// Allowed display types
	var allowedMusicalEntityTypes: [MusicalEntityType] {
		return [.albums, .artists, .albumsartists, .genres, .playlists]
	}

	// MARK: - Initializers
	init(mpdBridge: MPDBridge) {
		self.mpdBridge = mpdBridge

		super.init(nibName: nil, bundle: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(collectionViewLayoutShouldChange(_:)), name: .collectionViewLayoutShouldChange, object: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()
		// Remove back button label
		navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "btn-back")
		navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "btn-back")
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		// Search button
		let searchButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-search"), style: .plain, target: self, action: #selector(showSearchBarAction(_:)))
		searchButton.accessibilityLabel = NYXLocalizedString("lbl_search")
		navigationItem.rightBarButtonItems = [searchButton]

		// Searchbar
		if let navigationBar = navigationController?.navigationBar {
			searchView = UIView(frame: CGRect(.zero, navigationBar.width, navigationBar.maxY))
			searchBar = UISearchBar(frame: CGRect(0, navigationBar.y, navigationBar.width, navigationBar.height))
			searchView.alpha = 0
			searchBar.searchBarStyle = .minimal
			searchBar.showsCancelButton = true
			searchBar.delegate = self
			searchView.addSubview(searchBar)
		}

		// Collection view
		self.view.frame = CGRect(.zero, view.width, view.height - heightForMiniPlayer())
		collectionView = MusicalCollectionView(frame: view.bounds, musicalEntityType: dataSource.musicalEntityType)
		collectionView.collectionView.delegate = dataSource
		collectionView.collectionView.dataSource = dataSource
		view.addSubview(collectionView)

		// Double tap
		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
		doubleTap.numberOfTapsRequired = 2
		doubleTap.numberOfTouchesRequired = 1
		doubleTap.delaysTouchesBegan = true
		collectionView.addGestureRecognizer(doubleTap)

		if allowedMusicalEntityTypes.count > 1 {
			titleView.isEnabled = true
			titleView.addTarget(self, action: #selector(changeTypeAction(_:)), for: .touchUpInside)
		}

		initializeTheming()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if searchView != nil && searchView.superview == nil {
			navigationController?.view.addSubview(searchView)
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if searchView != nil && searchView.superview != nil {
			searchView.removeFromSuperview()
		}
	}

	// MARK: - Gestures
	@objc func doubleTap(_ gest: UITapGestureRecognizer) {
	}

	// MARK: - Actions
	@objc func showSearchBarAction(_ sender: Any?) {
		UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut, animations: {
			self.searchView.alpha = 1
			self.searchBar.becomeFirstResponder()
		}, completion: { (_) in
			self.searchBarVisible = true
		})
	}

	@objc func changeTypeAction(_ sender: UIButton?) {
		let avc = TypeChoiceVC(musicalEntityTypes: allowedMusicalEntityTypes)
		avc.modalPresentationStyle = .popover
		avc.delegate = self
		avc.selectedMusicalEntityType = dataSource.musicalEntityType
		if let popController = avc.popoverPresentationController {
			popController.permittedArrowDirections = .up
			popController.sourceRect = titleView.bounds
			popController.sourceView = titleView
			popController.delegate = self
			avc.preferredContentSize = CGSize(280, CGFloat(44 * allowedMusicalEntityTypes.count))
			present(avc, animated: true, completion: {
				self.navMenuDisplayed = true
			})
		}
	}

	// MARK: - Public
	func setItems(_ items: [MusicalEntity], forMusicalEntityType type: MusicalEntityType, reload: Bool = true) {
		dataSource.setItems(items, forType: type)
		collectionView.musicalEntityType = type
		if reload {
			collectionView.setIndexTitles(dataSource.titlesIndex)
			collectionView.reloadData()
		}
	}

	// MARK: - Private
	private func showNavigationBar(animated: Bool = true) {
		UIView.animate(withDuration: animated ? 0.35 : 0, delay: 0, options: .curveEaseOut, animations: {
			self.searchBar.resignFirstResponder()
			self.searchView.alpha = 0
		}, completion: { (_) in
			self.searchBarVisible = false
		})
	}

	// MARK: - Notifications
	@objc private func collectionViewLayoutShouldChange(_ aNotification: Notification) {
		collectionView.updateLayout()
		collectionView.reloadData()
	}
}

// MARK: - UISearchBarDelegate
extension MusicalCollectionVC: UISearchBarDelegate {
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		searchBar.text = ""
		searching = false
		dataSource.searching = false
		dataSource.setSearchResults([])
		showNavigationBar(animated: true)
		collectionView.setIndexTitles(dataSource.titlesIndex)
		collectionView.reloadData()
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
		searchBar.endEditing(true)
		collectionView.setIndexTitles(dataSource.searchTitlesIndex)
		collectionView.reloadData()
	}

	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		// Update flags
		searching = true
		dataSource.searching = true
		// Copy original source to avoid crash when nothing was searched
		dataSource.setSearchResults(dataSource.items)
	}

	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		if String.isNullOrWhiteSpace(searchText) {
			dataSource.setSearchResults(dataSource.items)
			collectionView.setIndexTitles(dataSource.titlesIndex)
			collectionView.reloadData()
			return
		}

		if Settings.shared.bool(forKey: .pref_fuzzySearch) {
			dataSource.setSearchResults(dataSource.items.filter { $0.name.fuzzySearch(withString: searchText) })
		} else {
			dataSource.setSearchResults(dataSource.items.filter { $0.name.lowercased().contains(searchText.lowercased()) })
		}

		collectionView.setIndexTitles(dataSource.searchTitlesIndex)
		collectionView.reloadData()
	}
}

// MARK: - MusicalCollectionDataSourceAndDelegateDelegate
extension MusicalCollectionVC: MusicalCollectionDataSourceAndDelegateDelegate {
	func coverDownloaded(_ cover: UIImage?, forItemAtIndexPath indexPath: IndexPath) {
		if let c = collectionView.collectionView.cellForItem(at: indexPath) as? MusicalEntityCollectionViewCell {
			c.image = cover
		}
	}

	@objc func isSearching(actively: Bool) -> Bool {
		actively ? (searching && searchBar.isFirstResponder) : searching
	}

	@objc func didSelectEntity(_ entity: AnyObject) {

	}

	@objc func didDisplayCellAtIndexPath(_ indexPath: IndexPath) {
		collectionView.setCurrentIndex(indexPath.section)
	}

	func shouldRenamePlaytlist(_ playlist: Playlist) {
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

	@objc func shouldDeletePlaytlist(_ playlist: AnyObject) {
	}
}

// MARK: - TypeChoiceViewDelegate
extension MusicalCollectionVC: TypeChoiceVCDelegate {
	@objc func didSelectDisplayType(_ typeAsInt: Int) {
	}
}

extension MusicalCollectionVC: Themed {
	func applyTheme(_ theme: Theme) {
		view.backgroundColor = .systemGroupedBackground
		searchView.backgroundColor = .systemGroupedBackground
		searchBar.tintColor = theme.tintColor
		(searchBar.value(forKey: "searchField") as? UITextField)?.textColor = .secondaryLabel
	}
}

// MARK: - UIPopoverPresentationControllerDelegate
extension MusicalCollectionVC: UIPopoverPresentationControllerDelegate {
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		.none
	}
}
