import UIKit

final class ContainerVC: UIViewController {
	private var libraryVC: LibraryVC!
	private var playerVC: PlayerVC!

	override func viewDidLoad() {
		super.viewDidLoad()

		libraryVC = LibraryVC()
		let nvc = NYXNavigationController(rootViewController: libraryVC)
		self.add(nvc)

		playerVC = PlayerVC(mpdBridge: libraryVC.mpdBridge)
		self.add(playerVC)
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		if playerVC != nil && libraryVC != nil {
			return playerVC.isMinified ? libraryVC.preferredStatusBarStyle : playerVC.preferredStatusBarStyle
		}
		return .default
	}
}
