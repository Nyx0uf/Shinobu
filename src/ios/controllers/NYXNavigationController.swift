import UIKit


final class NYXNavigationController : UINavigationController
{
	override var shouldAutorotate: Bool
	{
		if let topViewController = self.topViewController
		{
			return topViewController.shouldAutorotate
		}
		return false
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
	var titleView: UILabel! = nil

	override func viewDidLoad()
	{
		super.viewDidLoad()

		titleView = UILabel(frame: CGRect(0.0, 0.0, 100.0, 44.0))
		titleView.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
		navigationItem.titleView = titleView
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}
}

class NYXViewController : UIViewController
{
	// Navigation title
	var titleView: UILabel! = nil

	override func viewDidLoad()
	{
		super.viewDidLoad()

		titleView = UILabel(frame: CGRect(0.0, 0.0, 100.0, 44.0))
		titleView.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
		navigationItem.titleView = titleView
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
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
		return .portrait
	}
}
