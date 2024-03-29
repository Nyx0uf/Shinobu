import UIKit
import Defaults

final class ContainerVC: UIViewController {
	// MARK: - Private properties
	// Bridge to mpd
	private var mpdBridge: MPDBridge!
	// Nav controller for main VC
	private var navController: NYXNavigationController!
	// MARK: - iphone
	// Library VC for iphone
	private var libraryVC: LibraryVC!
	// Browse by directory VC
	private var directoriesVC: DirectoriesVC!
	// Player VC for iphone
	private var playerVC: PlayerVC!
	// MARK: - ipad
	// Player VC for ipad
	private var playerVC_ipad: PlayerVCIPAD!
	// Library VC for ipad
	private var libraryVC_ipad: LibraryVCIPAD!
	// Browse by directory VC for ipad
	private var directoriesVC_ipad: DirectoriesVCIPAD!

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
		if UIDevice.current.isPad() {
			return .lightContent
		} else {
			if playerVC != nil && libraryVC != nil {
				return playerVC.isMinified ? libraryVC.preferredStatusBarStyle : playerVC.preferredStatusBarStyle
			}
			return .default
		}
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		UIDevice.current.isPad() ? [.landscapeLeft, .landscapeRight] : [.portrait, .portraitUpsideDown]
	}

	// MARK: - Notifications
	@objc private func browsingTypeChanged(_ aNotification: Notification) {
		setupVCs()
	}

	// MARK: - Private
	private func setupVCs() {
		mpdBridge = nil
		mpdBridge = MPDBridge(isDirectoryBased: Defaults[.pref_browseByDirectory])

		if UIDevice.current.isPad() {
			if playerVC_ipad != nil {
				playerVC_ipad.remove()
				playerVC_ipad = nil
			}
			if navController != nil {
				navController.remove()
				navController = nil
			}
			if libraryVC_ipad != nil {
				libraryVC_ipad = nil
			}
			if directoriesVC_ipad != nil {
				directoriesVC_ipad = nil
			}

			if Defaults[.pref_browseByDirectory] == false {
				libraryVC_ipad = LibraryVCIPAD(mpdBridge: mpdBridge)
				navController = NYXNavigationController(rootViewController: libraryVC_ipad)
			} else {
				directoriesVC_ipad = DirectoriesVCIPAD(mpdBridge: mpdBridge, path: nil)
				navController = NYXNavigationController(rootViewController: directoriesVC_ipad)
			}
			let primaryWidth = ceil(UIScreen.main.bounds.width * 0.66666)
			navController.view.frame = CGRect(0, 0, primaryWidth, UIScreen.main.bounds.height)
			self.add(navController)

			playerVC_ipad = PlayerVCIPAD(mpdBridge: mpdBridge)
			self.add(playerVC_ipad)
		} else {
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

			if Defaults[.pref_browseByDirectory] == false {
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
}
