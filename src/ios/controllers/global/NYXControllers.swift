import UIKit


final class NYXNavigationController: UINavigationController
{
	private var themedStatusBarStyle: UIStatusBarStyle?

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		if let presentedViewController = presentedViewController
		{
			return presentedViewController.preferredStatusBarStyle
		}

		if let themedStatusBarStyle = themedStatusBarStyle
		{
			return themedStatusBarStyle
		}

//		if let topViewController = topViewController
//		{
//			return topViewController.preferredStatusBarStyle
//		}
		return .lightContent
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()

		initializeTheming()
	}

	override var shouldAutorotate: Bool
	{
		if let topViewController = topViewController
		{
			return topViewController.shouldAutorotate
		}
		return true
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		if let topViewController = topViewController
		{
			return topViewController.supportedInterfaceOrientations
		}
		return .all
	}

	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation
	{
		if let topViewController = topViewController
		{
			return topViewController.preferredInterfaceOrientationForPresentation
		}
		return .portrait
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
	}
}

extension NYXNavigationController: Themed
{
	func applyTheme(_ theme: ShinobuTheme)
	{
		themedStatusBarStyle = theme.statusBarStyle
		navigationBar.barStyle = theme.navigationBarStyle
		navigationBar.tintColor = theme.tintColor
		setNeedsStatusBarAppearanceUpdate()
	}
}

class NYXTableViewController: UITableViewController
{
	// Navigation title
	private(set) var titleView: NYXNavigationTitleView! = nil

	override func viewDidLoad()
	{
		super.viewDidLoad()

		titleView = NYXNavigationTitleView(frame: CGRect(.zero, 160, 44))
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

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		if let navigationBar = navigationController?.navigationBar
		{
			if let shadowImageView = findShadowImage(under: navigationBar)
			{
				shadowImageView.isHidden = true
			}
		}
	}

	func updateNavigationTitle()
	{

	}
}

class NYXViewController: UIViewController
{
	// Navigation title
	private(set) var titleView: NYXNavigationTitleView! = nil

	override func viewDidLoad()
	{
		super.viewDidLoad()

		titleView = NYXNavigationTitleView(frame: CGRect(.zero, 160, 44))
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

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		if let navigationBar = navigationController?.navigationBar
		{
			if let shadowImageView = findShadowImage(under: navigationBar)
			{
				shadowImageView.isHidden = true
			}
		}
	}

	func updateNavigationTitle()
	{

	}
}

class NYXAlertController: UIAlertController
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

	return statusHeight + 44
}

fileprivate func findShadowImage(under view: UIView) -> UIImageView?
{
	if view is UIImageView && view.bounds.size.height <= 1
	{
		return (view as! UIImageView)
	}

	for subview in view.subviews
	{
		if let imageView = findShadowImage(under: subview)
		{
			return imageView
		}
	}
	return nil
}
