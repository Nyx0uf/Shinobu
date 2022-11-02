import UIKit
import Defaults

class MusicalCollectionVCIPAD: NYXViewController, TypeChoiceVCDelegate {
	// MARK: - Public properties
	// Collection view
	private(set) var collectionView: MusicalCollectionView!
	// Collection view's data source & delegate
	var dataSource: MusicalCollectionDataSourceAndDelegate!
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
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		// Search button
		let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(showSearchBarAction(_:)))
		searchButton.accessibilityLabel = NYXLocalizedString("lbl_search")
		navigationItem.rightBarButtonItems = [searchButton]

		// Collection view
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
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if let navigationBar = navigationController?.navigationBar {
			let opaqueAppearance = UINavigationBarAppearance()
			opaqueAppearance.configureWithOpaqueBackground()
			opaqueAppearance.shadowColor = .clear
			navigationBar.standardAppearance = opaqueAppearance
		}

		collectionView.frame = view.bounds
	}

	// MARK: - Gestures
	@objc func doubleTap(_ gest: UITapGestureRecognizer) {
	}

	// MARK: - Actions
	@objc func showSearchBarAction(_ sender: Any?) {
		let vc = SearchVC(mpdBridge: mpdBridge)
		vc.modalTransitionStyle = .crossDissolve
		vc.modalPresentationStyle = .overCurrentContext
		guard let rootVC = UIApplication.shared.mainWindow?.rootViewController else { return }
		rootVC.present(vc, animated: true, completion: nil)
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

	// MARK: - Notifications
	@objc private func collectionViewLayoutShouldChange(_ aNotification: Notification) {
		collectionView.updateLayout()
		collectionView.reloadData()
	}

	// MARK: - TypeChoiceVCDelegate
	func didSelectDisplayType(_ type: MusicalEntityType) {
	}
}

// MARK: - MusicalCollectionDataSourceAndDelegateDelegate
extension MusicalCollectionVCIPAD: MusicalCollectionDataSourceAndDelegateDelegate {
	func coverDownloaded(_ cover: UIImage?, forItemAtIndexPath indexPath: IndexPath) {
		if let c = collectionView.collectionView.cellForItem(at: indexPath) as? MusicalEntityCollectionViewCell {
			c.image = cover
		}
	}

	@objc func isSearching(actively: Bool) -> Bool {
		false
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

// MARK: - UIPopoverPresentationControllerDelegate
extension MusicalCollectionVCIPAD: UIPopoverPresentationControllerDelegate {
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		.none
	}
}
