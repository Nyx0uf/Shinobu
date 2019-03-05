import UIKit

func APP_DELEGATE() -> AppDelegate {return UIApplication.shared.delegate as! AppDelegate}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	// Main window
	var window: UIWindow?
	// Container: VC + Menu
	private var containerVC: ContainerVC! = nil

	override init()
	{
		super.init()
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		self._setAppearances()

		Settings.shared.initialize()

		self.containerVC = ContainerVC()
		self.window = UIWindow(frame: UIScreen.main.bounds)
		self.window?.rootViewController = self.containerVC
		self.window?.makeKeyAndVisible()
		return true
	}

	private func _setAppearances()
	{
		let navigationBarAppearance = UINavigationBar.appearance()
		navigationBarAppearance.tintColor = Colors.main
		navigationBarAppearance.isTranslucent = true
		navigationBarAppearance.barStyle = .blackTranslucent

		let tableViewAppearance = UITableView.appearance()
		tableViewAppearance.backgroundColor = Colors.background
		tableViewAppearance.tintColor = Colors.main

		let textFieldAppearance = UITextField.appearance()
		textFieldAppearance.tintColor = Colors.main

		let switchAppearance = UISwitch.appearance()
		switchAppearance.onTintColor = Colors.main

		let sliderAppearance = UISlider.appearance()
		sliderAppearance.tintColor = Colors.main
	}
}
