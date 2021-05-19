import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	// Main window
	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

		window = UIWindow(frame: UIScreen.main.bounds)
		if UIDevice.current.isPad() {
			window?.overrideUserInterfaceStyle = .dark
		}
		window?.rootViewController = ContainerVC()
		window?.makeKeyAndVisible()
		return true
	}
}
