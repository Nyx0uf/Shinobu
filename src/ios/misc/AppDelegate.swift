import UIKit

func APP_DELEGATE() -> AppDelegate {return UIApplication.shared.delegate as! AppDelegate}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		self._setAppearances()

		Settings.shared.initialize()

		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = ContainerVC()
		window?.makeKeyAndVisible()
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
	}
}
