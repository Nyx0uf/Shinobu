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
