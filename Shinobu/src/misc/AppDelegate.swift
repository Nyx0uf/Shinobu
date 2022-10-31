import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		return true
	}

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

	func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
		UIDevice.current.isPad() ? [.landscapeLeft, .landscapeRight] : [.portrait, .portraitUpsideDown]
	}
}

extension AppDelegate {
	override func handle(_ error: Error, from viewController: UIViewController, retryHandler: (() -> Void)?) {
		let alert = UIAlertController(title: NYXLocalizedString("lbl_error_occured"), message: error.localizedDescription, preferredStyle: .alert)

		alert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .default))

		viewController.present(alert, animated: true)
	}
}
