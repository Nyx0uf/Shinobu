import UIKit


extension UIDevice
{
	func isPad() -> Bool
	{
		return userInterfaceIdiom == .pad
	}

	func isPhone() -> Bool
	{
		return userInterfaceIdiom == .phone
	}

	func isiPhoneX() -> Bool
	{
		return isPhone() && Int(UIScreen.main.nativeBounds.height) == 2436
	}
}
