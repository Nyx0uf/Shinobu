import UIKit


final class NYXNavigationController : UINavigationController
{
	override var shouldAutorotate: Bool
	{
		if let topViewController = self.topViewController
		{
			return topViewController.shouldAutorotate
		}
		return true
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		if let topViewController = self.topViewController
		{
			return topViewController.supportedInterfaceOrientations
		}
		return .all
	}

	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation
	{
		if let topViewController = self.topViewController
		{
			return topViewController.preferredInterfaceOrientationForPresentation
		}
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		if let presentedViewController = self.presentedViewController
		{
			return presentedViewController.preferredStatusBarStyle
		}
		if let topViewController = self.topViewController
		{
			return topViewController.preferredStatusBarStyle
		}
		return .lightContent
	}
}

class NYXTableViewController : UITableViewController
{
	// Navigation title
	private(set) var titleView: NYXNavigationTitleView! = nil

	override func viewDidLoad()
	{
		super.viewDidLoad()

		titleView = NYXNavigationTitleView(frame: CGRect(0.0, 0.0, 160.0, 44.0))
		titleView.isEnabled = false
		navigationItem.titleView = titleView
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return [.portrait, .portraitUpsideDown]
	}

	override var shouldAutorotate: Bool
	{
		return true
	}

	func updateNavigationTitle()
	{

	}
}

class NYXViewController : UIViewController
{
	// Navigation title
	private(set) var titleView: NYXNavigationTitleView! = nil

	override func viewDidLoad()
	{
		super.viewDidLoad()

		titleView = NYXNavigationTitleView(frame: CGRect(0.0, 0.0, 160.0, 44.0))
		titleView.isEnabled = false
		navigationItem.titleView = titleView
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return [.portrait, .portraitUpsideDown]
	}

	override var shouldAutorotate: Bool
	{
		return true
	}

	func updateNavigationTitle()
	{

	}
}

class NYXAlertController : UIAlertController
{
	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return [.portrait, .portraitUpsideDown]
	}

	override var shouldAutorotate: Bool
	{
		return true
	}
}


public func NavigationBarHeight() -> CGFloat
{
	let statusHeight: CGFloat
	if let top = UIApplication.shared.keyWindow?.safeAreaInsets.top
	{
		statusHeight = top < 20 ? 20 : top
	}
	else
	{
		statusHeight = 20
	}

	return statusHeight + 44.0
}
