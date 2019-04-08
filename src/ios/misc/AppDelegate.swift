import UIKit

func APP_DELEGATE() -> AppDelegate { return UIApplication.shared.delegate as! AppDelegate }

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	// Main window
	var window: UIWindow?

	override init()
	{
		super.init()
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		// Init settings
		Settings.shared.initialize()

		// Global appearance
		setAppearances()

		// URL cache
		URLCache.shared = URLCache(memoryCapacity: 4.MB(), diskCapacity: 32.MB(), diskPath: nil)

		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = NYXNavigationController(rootViewController: LibraryVC())
		window?.makeKeyAndVisible()
		return true
	}

	private func setAppearances()
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
