import UIKit
import QuartzCore


protocol ContainerVCDelegate : class
{
	func toggleMenu()
	func isMenuVisible() -> Bool
	func showServerVC()
}

protocol CenterViewController
{
	var containerDelegate: ContainerVCDelegate? {get set}
}

enum SelectedVCType
{
	case library
	case settings
	case server
}

final class ContainerVC : UIViewController
{
	// MARK: - Private properties
	// Main VC
	private var mainViewController: NYXNavigationController! = nil
	// Menu VC
	private var menuViewController: SideMenuVC? = nil
	// VCs
	private var libraryViewController: NYXNavigationController! = nil
	private var serverViewController: NYXNavigationController! = nil
	private var settingsViewController: NYXNavigationController! = nil
	private var statsViewController: NYXNavigationController! = nil
	// Current display state
	private var menuVisible = false
	{
		didSet
		{
			self.toggleShadow(menuVisible)
		}
	}
	// Current displayed VC
	private var selectedVCType = SelectedVCType.library
	// Pan gesture
	private var panGestureRecognizer: UIPanGestureRecognizer! = nil

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
		panGestureRecognizer.delegate = self

		self._updateCenterVC()
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return mainViewController != nil ? mainViewController.preferredStatusBarStyle : .lightContent
	}

	// MARK: - Gestures
	@objc func pan(_ recognizer: UIPanGestureRecognizer)
	{
		let leftToRight = (recognizer.velocity(in: view).x > 0)

		switch recognizer.state
		{
		case .began:
			if menuVisible == false
			{
				if leftToRight
				{
					self.addMenuViewController()
				}
				else
				{
					recognizer.isEnabled = false
				}
				self.toggleShadow(true)
			}
		case .changed:
			if let rview = recognizer.view
			{
				rview.center.x = rview.center.x + recognizer.translation(in: view).x
				recognizer.setTranslation(.zero, in: view)
			}
		case .ended:
			if let _ = menuViewController, let rview = recognizer.view
			{
				let hasMovedGreaterThanHalfway = rview.center.x > view.bounds.size.width
				self.showMenu(expand: hasMovedGreaterThanHalfway)
			}
			recognizer.isEnabled = true
		case .cancelled:
			recognizer.isEnabled = true
		default:
			break
		}
	}

	// MARK: - Private
	private func _updateCenterVC()
	{
		// Remove current VC
		if let currentCenterVC = mainViewController
		{
			if let currentCenterVCView = currentCenterVC.view
			{
				currentCenterVCView.removeGestureRecognizer(panGestureRecognizer)
			}
			currentCenterVC.remove()
		}

		// Add the new VC
		switch selectedVCType
		{
			case .library:
				if libraryViewController == nil
				{
					let vc = LibraryVC()
					let nvc = NYXNavigationController(rootViewController: vc)
					libraryViewController = nvc//UIStoryboard.libraryVC()
				}
				mainViewController = libraryViewController
			case .server:
				if serverViewController == nil
				{
					let vc = ServerListTVC()
					let nvc = NYXNavigationController(rootViewController: vc)
					serverViewController = nvc
					//serverViewController = UIStoryboard.serverTVC()
				}
				mainViewController = serverViewController
			case .settings:
				if settingsViewController == nil
				{
					let vc = SettingsVC()
					let nvc = NYXNavigationController(rootViewController: vc)
					settingsViewController = nvc
					//settingsViewController = UIStoryboard.settingsTVC()
				}
				mainViewController = settingsViewController
		}
		self.add(mainViewController)

		var vc = mainViewController.topViewController as! CenterViewController
		vc.containerDelegate = self

		mainViewController.view.addGestureRecognizer(panGestureRecognizer)
	}

	private func addMenuViewController()
	{
		guard menuViewController == nil else { return }

		/*if let vc = UIStoryboard.leftViewController()
		{
			vc.menuDelegate = self
			view.insertSubview(vc.view, at: 0)

			addChild(vc)
			vc.didMove(toParent: self)

			menuViewController = vc
		}*/
		let vc = SideMenuVC()
		vc.menuDelegate = self
		view.insertSubview(vc.view, at: 0)
		
		addChild(vc)
		vc.didMove(toParent: self)
		
		menuViewController = vc
	}

	private func showMenu(expand: Bool)
	{
		if expand
		{
			menuVisible = true
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
				self.mainViewController.view.frame.origin.x = self.mainViewController.view.frame.width - (UIScreen.main.bounds.width / 3.0)
			}, completion: { finished in
			})
		}
		else
		{
			// First time loading a VC
			if Int(mainViewController.view.frame.origin.x) == 0
			{
				mainViewController.view.frame.origin.x = mainViewController.view.frame.width - (UIScreen.main.bounds.width / 3.0)
			}
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
				self.mainViewController.view.frame.origin.x = 0.0
			}, completion: { finished in
				self.menuVisible = false
				self.menuViewController?.view.removeFromSuperview()
				self.menuViewController = nil
			})
		}
	}

	private func toggleShadow(_ showShadow: Bool)
	{
		mainViewController.view.layer.shadowOpacity = showShadow ? 0.8 : 0.0
	}
}

// MARK: - ContainerVCDelegate
extension ContainerVC : ContainerVCDelegate
{
	func toggleMenu()
	{
		if menuVisible == false
		{
			self.addMenuViewController()
		}

		self.showMenu(expand: menuVisible == false)
	}

	func isMenuVisible() -> Bool
	{
		return menuVisible
	}

	func showServerVC()
	{
		if selectedVCType != .server
		{
			selectedVCType = .server
			self._updateCenterVC()
			if menuVisible
			{
				self.toggleMenu()
			}
		}
	}
}

// MARK: - SideMenuVCDelegate
extension ContainerVC : SideMenuVCDelegate
{
	func didSelectMenuItem(_ selectedVC: SelectedVCType)
	{
		if selectedVCType != selectedVC
		{
			selectedVCType = selectedVC
			self._updateCenterVC()
			self.toggleMenu()
		}
	}

	func getSelectedController() -> SelectedVCType
	{
		return selectedVCType
	}
}

// MARK: - UIGestureRecognizerDelegate
extension ContainerVC : UIGestureRecognizerDelegate
{
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
	{
		if selectedVCType == .library
		{
			if let topVC = mainViewController.topViewController
			{
				if topVC.isKind(of: LibraryVC.classForCoder()) == false
				{
					return false
				}
			}
		}
		return true
	}
}

/*private extension UIStoryboard
{
	static func main() -> UIStoryboard
	{
		return UIStoryboard(name: "main-iphone", bundle: .main)
	}

	static func leftViewController() -> SideMenuVC?
	{
		return main().instantiateViewController(withIdentifier: "SideMenuVC") as? SideMenuVC
	}

	static func libraryVC() -> NYXNavigationController?
	{
		return main().instantiateViewController(withIdentifier: "LibraryNVC") as? NYXNavigationController
	}

	static func serverTVC() -> NYXNavigationController?
	{
		return main().instantiateViewController(withIdentifier: "ServerNVC") as? NYXNavigationController
	}

	static func statsTVC() -> NYXNavigationController?
	{
		return main().instantiateViewController(withIdentifier: "StatsNVC") as? NYXNavigationController
	}

	static func settingsTVC() -> NYXNavigationController?
	{
		return main().instantiateViewController(withIdentifier: "SettingsNVC") as? NYXNavigationController
	}
}*/
