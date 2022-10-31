import UIKit

extension UIApplication {
	var mainWindow: UIWindow? {
		if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
			return windowScene.windows.first
		} else {
			return nil
		}
	}
}
