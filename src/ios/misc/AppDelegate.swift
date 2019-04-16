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

		// URL cache
		URLCache.shared = URLCache(memoryCapacity: 4.MB(), diskCapacity: 32.MB(), diskPath: nil)

		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = ContainerVC()
		window?.makeKeyAndVisible()
		return true
	}
}
