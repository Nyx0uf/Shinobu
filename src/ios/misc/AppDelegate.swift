import UIKit

func APP_DELEGATE() -> AppDelegate {return UIApplication.shared.delegate as! AppDelegate}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		let appearance = UINavigationBar.appearance()
		appearance.tintColor = Colors.main
		appearance.isTranslucent = true
		appearance.barStyle = .blackTranslucent

		let tableViewAppearance = UITableView.appearance()
		tableViewAppearance.backgroundColor = Colors.background

		UITextField.appearance().tintColor = Colors.main

		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = ContainerVC()
		window?.makeKeyAndVisible()
		return true
	}
}
