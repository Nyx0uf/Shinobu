import UIKit
import Defaults

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	private var observer_columns: Defaults.Observation?
	private var observer_directory: Defaults.Observation?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

		observer_columns = Defaults.observe(.pref_numberOfColumns) { change in
			if change.oldValue != change.newValue {
				// Need to erase downloaded cover because the size will change
				ImageCache.shared.clear(nil)
				NotificationCenter.default.postOnMainThreadAsync(name: .collectionViewLayoutShouldChange, object: nil)
			}
		}

		observer_directory = Defaults.observe(.pref_browseByDirectory) { change in
			if change.oldValue != change.newValue {
				NotificationCenter.default.postOnMainThreadAsync(name: .changeBrowsingTypeNotification, object: nil)

				// Album doesn't meen a thing in directory mode, so disable shake
				if Defaults[.pref_browseByDirectory] == true {
					Defaults[.pref_shakeToPlayRandom] = false
				}
			}
		}

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
