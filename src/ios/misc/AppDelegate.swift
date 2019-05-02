import UIKit

func APP_DELEGATE() -> AppDelegate { return UIApplication.shared.delegate as! AppDelegate }

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	// Main window
	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		// Init settings
		Settings.shared.initialize()

		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = ContainerVC()
		window?.makeKeyAndVisible()
		return true
	}
}
