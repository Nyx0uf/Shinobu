import UIKit
import Defaults
import Logging

final class DirectoriesVC: NYXViewController {
	// MARK: - Public properties
	// MPD Data source
	let mpdBridge: MPDBridge
	// Selected path
	let path: String?

	// MARK: - Private properties
	// Table view
	private var tableView: UITableView!
	// Image view for displaying cover file if any
	private let imageView = UIImageView(frame: .zero)
	// Cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.dir"
	// All items in current folder
	private var allItems = [MPDEntity]()
	// Items displayed
	private var songs = [MPDEntity]()
	// Is an image present in the list of items
	private var hasImage = false
	// Local URL for the cover
	private(set) lazy var localCoverURL: URL = {
		let cachesDirectoryURL = FileManager.default.cachesDirectory()
		let coversDirectoryURL = cachesDirectoryURL.appendingPathComponent(Defaults[.coversDirectory], isDirectory: true)
		if FileManager.default.fileExists(atPath: coversDirectoryURL.absoluteString) == false {
			try! FileManager.default.createDirectory(at: coversDirectoryURL, withIntermediateDirectories: true, attributes: nil)
		}
		return coversDirectoryURL
	}()
	// Logger
	private let logger = Logger(label: "logger.DirectoriesVC")

	// MARK: - Initializers
	init(mpdBridge: MPDBridge, path: String?) {
		self.mpdBridge = mpdBridge
		self.path = path

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()
		self.edgesForExtendedLayout = UIRectEdge()

		// Remove back button label
		navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "btn-back")
		navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "btn-back")
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		if path == nil {
			// Servers button
			let serversButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-server"), style: .plain, target: self, action: #selector(showServersListAction(_:)))
			serversButton.accessibilityLabel = NYXLocalizedString("lbl_header_server_list")
			// Settings button
			let settingsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-settings"), style: .plain, target: self, action: #selector(showSettingsAction(_:)))
			settingsButton.accessibilityLabel = NYXLocalizedString("lbl_section_settings")
			navigationItem.leftBarButtonItems = [serversButton, settingsButton]
		}

		var miniHeight = CGFloat(64)
		if let bottom = UIApplication.shared.mainWindow?.safeAreaInsets.bottom {
			miniHeight += bottom
		}

		self.view.frame = CGRect(.zero, view.width, view.height - miniHeight)
		tableView = UITableView(frame: view.bounds, style: .plain)
		tableView.dataSource = self
		tableView.delegate = self
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
		tableView.tintColor = themeProvider.currentTheme.tintColor
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.tableFooterView = UIView()
		view.addSubview(tableView)

		imageView.layer.cornerRadius = 10
		imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		imageView.layer.masksToBounds = true

		initializeTheming()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		checkInit()
	}

	// MARK: - Overrides
	override func updateNavigationTitle() {
		DispatchQueue.main.async {
			self.titleView.setMainText(self.path ?? "/", detailText: nil)
		}
	}

	// MARK: - Buttons actions
	@objc func showServersListAction(_ sender: Any?) {
		let serverVC = ServerVC(mpdBridge: mpdBridge)
		let nvc = NYXNavigationController(rootViewController: serverVC)
		nvc.presentationController?.delegate = self
		navigationController?.present(nvc, animated: true, completion: nil)
	}

	@objc func showSettingsAction(_ sender: Any?) {
		let settingsVC = SettingsVC()
		let nvc = NYXNavigationController(rootViewController: settingsVC)
		nvc.presentationController?.delegate = self
		nvc.modalTransitionStyle = .flipHorizontal
		UIApplication.shared.delegate?.window??.rootViewController?.present(nvc, animated: true, completion: nil)
	}

	// MARK: - Private
	private func checkInit() {
		// Initialize the mpd connection
		if mpdBridge.server == nil {
			if let server = ServerManager().getServer() {
				// Data source
				mpdBridge.server = server.mpd
				let resultDataSource = mpdBridge.initialize()
				switch resultDataSource {
				case .failure(let error):
					MessageView.shared.showWithMessage(message: error.message)
				case .success:
					refreshDirectories()
				}
			}
		} else {
			refreshDirectories()
		}
	}

	private func refreshDirectories() {
		mpdBridge.getDirectoryListAtPath(path) { [weak self] (entities: [MPDEntity]) in
			guard let strongSelf = self else { return }
			DispatchQueue.main.async {
				let hasCover = entities.filter { $0.type == .image && $0.name.lowercased().contains("cover") }.isEmpty == false
				strongSelf.hasImage = hasCover
				strongSelf.allItems = entities
				strongSelf.songs = entities.filter { $0.type == .song || $0.type == .directory }

				strongSelf.handleCover()

				strongSelf.tableView.reloadData()
				strongSelf.updateNavigationTitle()
				strongSelf.toggleCoverImage()
			}
		}
	}

	private func handleEmptyView(tableView: UITableView, isEmpty: Bool) {
		if isEmpty {
			let emptyView = UIView(frame: tableView.bounds)
			emptyView.translatesAutoresizingMaskIntoConstraints = false
			emptyView.backgroundColor = tableView.backgroundColor

			let lbl = UILabel(frame: .zero)
			lbl.text = ""
			lbl.font = UIFont.systemFont(ofSize: 16, weight: .ultraLight)
			lbl.translatesAutoresizingMaskIntoConstraints = false
			lbl.tintColor = .label
			lbl.sizeToFit()
			emptyView.addSubview(lbl)
			lbl.x = ceil((emptyView.width - lbl.width) / 2)
			lbl.y = ceil((emptyView.height - lbl.height) / 2)

			tableView.backgroundView = emptyView
			tableView.separatorStyle = .none
		} else {
			tableView.backgroundView = nil
			tableView.separatorStyle = .singleLine
		}
	}

	private func toggleCoverImage() {
		if hasImage {
			var miniHeight = CGFloat(64)
			if let bottom = UIApplication.shared.mainWindow?.safeAreaInsets.bottom {
				miniHeight += bottom
			}

			let size = (view.width / 3).rounded()
			imageView.frame = CGRect(((view.width - size) / 2).rounded(), 10, size, size)
			tableView.frame = CGRect(view.x, imageView.maxY + 10, view.width, view.height - (imageView.maxY + 10) - miniHeight)
			view.insertSubview(imageView, at: 0)
		} else {
			imageView.removeFromSuperview()
			tableView.frame = view.bounds
		}
	}

	private func handleCover() {
		if hasImage == false {
			return
		}

		guard let aSong = songs.filter({ $0.type == .song }).first?.name else { return }

		let songUri = self.path == nil ? aSong : self.path! + "/" + aSong
		let coverUri = self.path == nil ? aSong : self.path!
		let hashedUri = coverUri.sha256() + ".jpg"
		let coverURL = self.localCoverURL.appendingPathComponent(hashedUri)
		if let cover = UIImage.loadFromFileURL(coverURL) {
			DispatchQueue.main.async {
				self.imageView.image = cover
			}
		} else {
			self.mpdBridge.getCoverForDirectoryAtPath(songUri) { [weak self] (data: Data) in
				guard let strongSelf = self else { return }

				DispatchQueue.global(qos: .userInteractive).async {
					guard let img = UIImage(data: data) else { return }

					let cropSize = CoverOperations.cropSizes()[.large]!
					if let cropped = img.smartCropped(toSize: cropSize, highQuality: false, screenScale: true) {
						DispatchQueue.main.async {
							strongSelf.imageView.image = cropped
						}
						if cropped.save(url: coverURL) == false {
							strongSelf.logger.error("Failed to save cover for <\(coverURL)>")
						}
					}
				}
			}
		}
	}
}

// MARK: - UITableViewDataSource
extension DirectoriesVC: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		handleEmptyView(tableView: tableView, isEmpty: allItems.isEmpty)
		return songs.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

		let item = songs[indexPath.row]

		cell.textLabel?.text = item.name
		cell.textLabel?.textColor = .label
		cell.textLabel?.highlightedTextColor = themeProvider.currentTheme.tintColor
		cell.textLabel?.isAccessibilityElement = false
		let image: UIImage? = item.type == .directory ? #imageLiteral(resourceName: "icon_folder") : (item.type == .song ? #imageLiteral(resourceName: "icon_note") : (item.type == .image ? #imageLiteral(resourceName: "icon_image") : nil))
		cell.imageView?.image = image?.withTintColor(.label)
		cell.imageView?.highlightedImage = image?.withTintColor(themeProvider.currentTheme.tintColor)
		cell.accessibilityLabel = item.name
		cell.accessoryType = item.type == .directory ? .disclosureIndicator : .none
		cell.selectionStyle = item.type == .directory || item.type == .song ? .default : .none

		let view = UIView()
		view.backgroundColor = themeProvider.currentTheme.tintColor.withAlphaComponent(0.2)
		cell.selectedBackgroundView = view

		return cell
	}
}

// MARK: - UITableViewDelegate
extension DirectoriesVC: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = songs[indexPath.row]
		if item.type == .directory {
			let newPath = self.path == nil ? item.name : self.path! + "/" + item.name
			let vc = DirectoriesVC(mpdBridge: mpdBridge, path: newPath)
			self.navigationController?.pushViewController(vc, animated: true)
		} else if item.type == .song {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
				tableView.deselectRow(at: indexPath, animated: true)
			})

			let track = Track(name: "", artist: "", duration: Duration(seconds: 0), trackNumber: 0, uri: self.path! + "/" + item.name)
			mpdBridge.playTracks([track], shuffle: false, loop: false)
		}
	}

	func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in
			let item = self.songs[indexPath.row]
			let rename = UIAction(title: NYXLocalizedString("lbl_play"), image: #imageLiteral(resourceName: "btn-play").withRenderingMode(.alwaysTemplate)) { _ in
				let path = self.path == nil ? item.name : self.path! + "/" + item.name
				let track = Track(name: "", artist: "", duration: Duration(seconds: 0), trackNumber: 0, uri: path)
				self.mpdBridge.playTracks([track], shuffle: false, loop: false)
			}
			return UIMenu(title: "", children: [rename])
		})
	}
}

extension DirectoriesVC: Themed {
	func applyTheme(_ theme: Theme) {
	}
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension DirectoriesVC: UIAdaptivePresentationControllerDelegate {
	func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		checkInit()
	}

	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return self.modalStyleForController(controller)
	}

	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		return self.modalStyleForController(controller)
	}

	private func modalStyleForController(_ controller: UIPresentationController) -> UIModalPresentationStyle {
		guard let nvc = controller.presentedViewController as? NYXNavigationController else { return .automatic }
		guard let tvc = nvc.topViewController else { return .automatic }

		return tvc.isKind(of: SettingsVC.self) ? .fullScreen : .automatic
	}
}
