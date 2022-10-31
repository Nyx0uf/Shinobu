import UIKit

extension UIDevice {
	func isPad() -> Bool {
		userInterfaceIdiom == .pad
	}

	func isPhone() -> Bool {
		userInterfaceIdiom == .phone
	}

	func isPhoneX() -> Bool {
		if isPhone() {
			let height = Int(UIScreen.main.nativeBounds.height)
			return height == 2436 /* X | Xs | 11 Pro */
				|| height == 2688 /* Xs Max | 11 Pro Max */
				|| height == 1792 /* Xr | 11 */
				|| height == 2532 /* 12 | 12 Pro */
				|| height == 2340 /* 12 Mini */
				|| height == 2778 /* 12 Pro Max */
		}
		return false
	}
}
