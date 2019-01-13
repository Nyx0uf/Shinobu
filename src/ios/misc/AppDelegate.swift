import UIKit

func APP_DELEGATE() -> AppDelegate {return UIApplication.shared.delegate as! AppDelegate}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = UIViewController()
		window?.makeKeyAndVisible()
		return true
	}
}
