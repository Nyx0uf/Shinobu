import UIKit


class MusicalCollectionVC: NYXViewController
{
	// MARK: - Public properties
	// Collection view
	private(set) var collectionView: MusicalCollectionView!
	// Collection viex's data source & delegate
	var dataSource: MusicalCollectionDataSourceAndDelegate!
	// Search view
	private(set) var searchView: UIView! = nil
	// Search bar
	private(set) var searchBar: UISearchBar! = nil
	// Should show the search view, flag
	private(set) var searchBarVisible = false
	// Is currently searching, flag
	private(set) var searching = false
	// Long press gesture is recognized, flag
	var longPressRecognized = false
	// Previewing context for peek & pop
	private(set) var previewingContext: UIViewControllerPreviewing! = nil
	// Long press gesture for devices without force touch
	private(set) var longPress: UILongPressGestureRecognizer! = nil
	// MPD Data source
	let mpdBridge: MPDBridge
	// Allowed display types
	var allowedMusicalEntityTypes: [MusicalEntityType]
	{
		return [.albums, .artists, .albumsartists, .genres, .playlists]
	}

	// MARK: - Private properties
	// View to change the type of items in the collection view
	private var typeChoiceView: TypeChoiceView! = nil

	// MARK: - Initializers
	init(mpdBridge: MPDBridge)
	{
		self.mpdBridge = mpdBridge

		super.init(nibName: nil, bundle: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(collectionViewLayoutShouldChange(_:)), name: .collectionViewLayoutShouldChange, object: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

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

		// Searchbar
		if let navigationBar = navigationController?.navigationBar
		{
			searchView = UIView(frame: CGRect(0, 0, navigationBar.width, navigationBar.maxY))
			searchBar = UISearchBar(frame: CGRect(0, navigationBar.y, navigationBar.width, navigationBar.height))
			searchView.alpha = 0
			searchBar.searchBarStyle = .minimal
			searchBar.showsCancelButton = true
			searchBar.delegate = self
			searchView.addSubview(searchBar)
		}

		// Collection view
		collectionView = MusicalCollectionView(frame: view.bounds, musicalEntityType: dataSource.musicalEntityType)
		collectionView.collectionView.delegate = dataSource
		collectionView.collectionView.dataSource = dataSource
		view.addSubview(collectionView)

		// Longpress
		longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
		longPress.minimumPressDuration = 0.5
		longPress.delaysTouchesBegan = true
		updateLongpressState()

		// Double tap
		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
		doubleTap.numberOfTapsRequired = 2
		doubleTap.numberOfTouchesRequired = 1
		doubleTap.delaysTouchesBegan = true
		collectionView.addGestureRecognizer(doubleTap)

		if allowedMusicalEntityTypes.count > 1
		{
			let y = navigationController != nil ? (navigationController?.navigationBar.maxY)! : 0
			typeChoiceView = TypeChoiceView(frame: CGRect(0, y, collectionView.width, CGFloat(allowedMusicalEntityTypes.count * 44)), musicalEntityTypes: allowedMusicalEntityTypes)
			typeChoiceView.delegate = self
			typeChoiceView.selectedMusicalEntityType = dataSource.musicalEntityType

			titleView.isEnabled = true
			titleView.addTarget(self, action: #selector(changeTypeAction(_:)), for: .touchUpInside)
		}

		initializeTheming()
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		if searchView != nil && searchView.superview == nil
		{
			navigationController?.view.addSubview(searchView)
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		if searchView != nil && searchView.superview != nil
		{
			searchView.removeFromSuperview()
		}
	}

	// MARK: - Gestures
	@objc func longPress(_ gest: UILongPressGestureRecognizer)
	{

	}

	@objc func doubleTap(_ gest: UITapGestureRecognizer)
	{
	}

	// MARK: - Actions
	@objc func showSearchBarAction(_ sender: Any?)
	{
		UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut, animations: {
			self.searchView.alpha = 1
			self.searchBar.becomeFirstResponder()
		}, completion: { (finished) in
			self.searchBarVisible = true
		})
	}

	@objc func changeTypeAction(_ sender: UIButton?)
	{
		if typeChoiceView.superview != nil
		{ // Is visible
			UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
				self.collectionView.frame = CGRect(0, 0, self.collectionView.size)
				//self.view.layoutIfNeeded()
				if self.dataSource.items.count == 0
				{
					self.collectionView.collectionView.contentOffset = CGPoint(0, (self.navigationController?.navigationBar.maxY)!)
				}
				else
				{
					self.collectionView.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
					self.collectionView.collectionView.contentOffset = CGPoint(0, -(self.navigationController?.navigationBar.maxY)!)
				}
			}, completion: { (finished) in
				self.typeChoiceView.removeFromSuperview()
			})
		}
		else
		{ // Is hidden
			typeChoiceView.tableView.reloadData()
			view.insertSubview(typeChoiceView, belowSubview: collectionView)

			UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
				self.collectionView.frame = CGRect(0, self.typeChoiceView.maxY, self.collectionView.size)
				self.collectionView.collectionView.contentInset = .zero
			}, completion: nil)
		}
	}

	// MARK: - Public
	func updateLongpressState()
	{
		if traitCollection.forceTouchCapability == .available
		{
			collectionView.removeGestureRecognizer(longPress)
			longPress.isEnabled = false
			previewingContext = registerForPreviewing(with: self, sourceView: collectionView)
		}
		else
		{
			collectionView.addGestureRecognizer(longPress)
			longPress.isEnabled = true
		}
	}

	func setItems(_ items: [MusicalEntity], forMusicalEntityType type: MusicalEntityType, reload: Bool = true)
	{
		dataSource.setItems(items, forType: type)
		collectionView.musicalEntityType = type
		if reload
		{
			collectionView.setIndexTitles(dataSource.titlesIndex)
			collectionView.reloadData()
		}
	}

	// MARK: - Private
	private func showNavigationBar(animated: Bool = true)
	{
		UIView.animate(withDuration: animated ? 0.35 : 0, delay: 0, options: .curveEaseOut, animations: {
			self.searchBar.resignFirstResponder()
			self.searchView.alpha = 0
		}, completion: { (finished) in
			self.searchBarVisible = false
		})
	}

	// MARK: - Notifications
	@objc private func collectionViewLayoutShouldChange(_ aNotification: Notification)
	{
		collectionView.updateLayout()
		collectionView.reloadData()
	}
}

// MARK: - UISearchBarDelegate
extension MusicalCollectionVC: UISearchBarDelegate
{
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
	{
		searchBar.text = ""
		searching = false
		dataSource.searching = false
		dataSource.setSearchResults([])
		showNavigationBar(animated: true)
		collectionView.setIndexTitles(dataSource.titlesIndex)
		collectionView.reloadData()
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
	{
		searchBar.resignFirstResponder()
		searchBar.endEditing(true)
		collectionView.setIndexTitles(dataSource.searchTitlesIndex)
		collectionView.reloadData()
	}

	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
	{
		// Update flags
		searching = true
		dataSource.searching = true
		// Copy original source to avoid crash when nothing was searched
		dataSource.setSearchResults(dataSource.items)
	}

	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
	{
		if String.isNullOrWhiteSpace(searchText)
		{
			dataSource.setSearchResults(dataSource.items)
			collectionView.setIndexTitles(dataSource.titlesIndex)
			collectionView.reloadData()
			return
		}

		if Settings.shared.bool(forKey: .pref_fuzzySearch)
		{
			dataSource.setSearchResults(dataSource.items.filter { $0.name.fuzzySearch(withString: searchText) })
		}
		else
		{
			dataSource.setSearchResults(dataSource.items.filter { $0.name.lowercased().contains(searchText.lowercased()) })
		}

		collectionView.setIndexTitles(dataSource.searchTitlesIndex)
		collectionView.reloadData()
	}
}

// MARK: - MusicalCollectionDataSourceAndDelegateDelegate
extension MusicalCollectionVC : MusicalCollectionDataSourceAndDelegateDelegate
{
	func coverDownloaded(_ cover: UIImage?, forItemAtIndexPath indexPath: IndexPath)
	{
		if let c = collectionView.collectionView.cellForItem(at: indexPath) as? MusicalEntityBaseCell
		{
			c.image = cover
		}
	}

	@objc func isSearching(actively: Bool) -> Bool
	{
		return actively ? (searching && searchBar.isFirstResponder) : searching
	}

	@objc func didSelectEntity(_ entity: AnyObject)
	{

	}

	@objc func didDisplayCellAtIndexPath(_ indexPath: IndexPath)
	{
		collectionView.setCurrentIndex(indexPath.section)
	}
}

// MARK: - UIViewControllerPreviewingDelegate
extension MusicalCollectionVC: UIViewControllerPreviewingDelegate
{
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
	{
		navigationController?.pushViewController(viewControllerToCommit, animated: true)
	}

	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
	{
		return nil
	}
}

// MARK: - TypeChoiceViewDelegate
extension MusicalCollectionVC: TypeChoiceViewDelegate
{
	@objc func didSelectDisplayType(_ typeAsInt: Int)
	{
	}
}

extension MusicalCollectionVC: Themed
{
	func applyTheme(_ theme: ShinobuTheme)
	{
		searchView.backgroundColor = theme.backgroundColor
		searchBar.tintColor = theme.tintColor
		(searchBar.value(forKey: "searchField") as? UITextField)?.textColor = theme.tableCellMainLabelTextColor
	}
}
