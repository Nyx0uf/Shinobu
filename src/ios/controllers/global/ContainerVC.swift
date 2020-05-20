import UIKit

final class ContainerVC: UIViewController {
	// MARK: - Private properties
	// Bridge to mpd
	private var mpdBridge: MPDBridge!
	// Library VC
	private var libraryVC: LibraryVC!
	// Browse by directory VC
	private var directoriesVC: DirectoriesVC!
	// Player VC
	private var playerVC: PlayerVC!
	// Nav controller for main VC
	private var navController: NYXNavigationController!

	init() {
		super.init(nibName: nil, bundle: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(browsingTypeChanged(_:)), name: .changeBrowsingTypeNotification, object: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override func viewDidLoad() {
		super.viewDidLoad()

		setupVCs()
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		if playerVC != nil && libraryVC != nil {
			return playerVC.isMinified ? libraryVC.preferredStatusBarStyle : playerVC.preferredStatusBarStyle
		}
		return .default
	}

	// MARK: - Notifications
	@objc private func browsingTypeChanged(_ aNotification: Notification) {
		setupVCs()
	}

	// MARK: - Private
	private func setupVCs() {
		mpdBridge = nil
		if playerVC != nil {
			playerVC.remove()
			playerVC = nil
		}
		if navController != nil {
			navController.remove()
			navController = nil
		}
		if libraryVC != nil {
			libraryVC = nil
		}
		if directoriesVC != nil {
			directoriesVC = nil
		}

		self.mpdBridge = MPDBridge(usePrettyDB: AppDefaults.pref_usePrettyDB, isDirectoryBased: AppDefaults.pref_browseByDirectory)

		if AppDefaults.pref_browseByDirectory == false {
			libraryVC = LibraryVC(mpdBridge: mpdBridge)
			navController = NYXNavigationController(rootViewController: libraryVC)
		} else {
			directoriesVC = DirectoriesVC(mpdBridge: mpdBridge, path: nil)
			navController = NYXNavigationController(rootViewController: directoriesVC)
		}
		self.add(navController)

		playerVC = PlayerVC(mpdBridge: mpdBridge)
		self.add(playerVC)
	}
}
