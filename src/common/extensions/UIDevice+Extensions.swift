import UIKit

extension UIDevice {
	func isPad() -> Bool {
		return userInterfaceIdiom == .pad
	}

	func isPhone() -> Bool {
		return userInterfaceIdiom == .phone
	}

	func isiPhoneX() -> Bool {
		if isPhone() {
			let height = Int(UIScreen.main.nativeBounds.height)
			return height == 2436 || height == 2688 || height == 1792
		}
		return false
	}
}
