import UIKit


final class ContainerVC : UIViewController
{
	private var libraryVC: LibraryVC!
	private var playerVC: PlayerVC!
	private var themedStatusBarStyle: UIStatusBarStyle?

	override func viewDidLoad()
	{
		super.viewDidLoad()
		self.view.backgroundColor = .green

		libraryVC = LibraryVC()
		let nc = NYXNavigationController(rootViewController: libraryVC)
		self.add(nc)

		playerVC = PlayerVC(mpdBridge: libraryVC.mpdBridge)
		self.add(playerVC)

		initializeTheming()
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		if playerVC != nil && libraryVC != nil
		{
			return playerVC.isMinified ? libraryVC.preferredStatusBarStyle : playerVC.preferredStatusBarStyle
		}
		return themedStatusBarStyle ?? .default
	}
}

extension ContainerVC: Themed
{
	func applyTheme(_ theme: Theme)
	{
		themedStatusBarStyle = theme.statusBarStyle
		setNeedsStatusBarAppearanceUpdate()
	}
}
