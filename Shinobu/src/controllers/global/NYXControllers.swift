import UIKit

final class NYXNavigationController: UINavigationController {
	private var themedStatusBarStyle: UIStatusBarStyle?

	override var preferredStatusBarStyle: UIStatusBarStyle {
		if let presentedViewController = presentedViewController {
			return presentedViewController.preferredStatusBarStyle
		}

		if let themedStatusBarStyle = themedStatusBarStyle {
			return themedStatusBarStyle
		}

		return .lightContent
	}

	override var shouldAutorotate: Bool {
		if let topViewController = topViewController {
			return topViewController.shouldAutorotate
		}
		return true
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		if let topViewController = topViewController {
			return topViewController.supportedInterfaceOrientations
		}
		return UIDevice.current.isPad() ? [.landscapeLeft, .landscapeRight] : [.portrait, .portraitUpsideDown]
	}

	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		if let topViewController = topViewController {
			return topViewController.preferredInterfaceOrientationForPresentation
		}
		return UIDevice.current.isPad() ? .landscapeLeft : .portrait
	}
}

class NYXTableViewController: UITableViewController {
	// Navigation title
	private(set) var titleView = NYXNavigationTitleView(frame: CGRect(.zero, 160, 44))

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	override init(style: UITableView.Style) {
		super.init(style: style)
	}

	required init?(coder: NSCoder) { fatalError("no coder") }

	override func viewDidLoad() {
		super.viewDidLoad()

		titleView.isEnabled = false
		navigationItem.titleView = titleView
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		UIDevice.current.isPad() ? [.landscapeLeft, .landscapeRight] : [.portrait, .portraitUpsideDown]
	}

	func updateNavigationTitle() {

	}

	func heightForMiniPlayer() -> CGFloat {
		if UIDevice.current.isPad() {
			return 0
		}

		var miniHeight = CGFloat(64)
		if let bottom = UIApplication.shared.mainWindow?.safeAreaInsets.bottom {
			miniHeight += bottom
		}
		return miniHeight
	}
}

class NYXViewController: UIViewController {
	// Navigation title
	private(set) var titleView = NYXNavigationTitleView(frame: CGRect(.zero, 160, 44))

	override func viewDidLoad() {
		super.viewDidLoad()

		titleView.isEnabled = false
		navigationItem.titleView = titleView
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		UIDevice.current.isPad() ? [.landscapeLeft, .landscapeRight] : [.portrait, .portraitUpsideDown]
	}

	func updateNavigationTitle() {

	}

	func heightForMiniPlayer() -> CGFloat {
		if UIDevice.current.isPad() {
			return 0
		}

		var miniHeight = CGFloat(64)
		if let bottom = UIApplication.shared.mainWindow?.safeAreaInsets.bottom {
			miniHeight += bottom
		}
		return miniHeight
	}
}

class NYXAlertController: UIAlertController {
	private var themedStatusBarStyle: UIStatusBarStyle?

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		UIDevice.current.isPad() ? [.landscapeLeft, .landscapeRight] : [.portrait, .portraitUpsideDown]
	}
}

public func NavigationBarHeight() -> CGFloat {
	let statusHeight: CGFloat
	if let top = UIApplication.shared.mainWindow?.safeAreaInsets.top {
		statusHeight = top < 20 ? 20 : top
	} else {
		statusHeight = 20
	}

	return statusHeight + 44
}

private func findShadowImage(under view: UIView) -> UIImageView? {
	if view is UIImageView && view.height <= 1 {
		return (view as! UIImageView)
	}

	for subview in view.subviews {
		if let imageView = findShadowImage(under: subview) {
			return imageView
		}
	}
	return nil
}
