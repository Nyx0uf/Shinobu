import UIKit

extension UIColor {
	// MARK: - Initializers
	public convenience init(rgb: Int32, alpha: CGFloat) {
		let red = ((CGFloat)((rgb & 0xFF0000) >> 16)) / 255
		let green = ((CGFloat)((rgb & 0x00FF00) >> 8)) / 255
		let blue = ((CGFloat)(rgb & 0x0000FF)) / 255

		self.init(red: red, green: green, blue: blue, alpha: alpha)
	}

	public convenience init(rgb: Int32) {
		self.init(rgb: rgb, alpha: 1)
	}

	func inverted() -> UIColor {
		var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
		getRed(&red, green: &green, blue: &blue, alpha: &alpha)
		return UIColor(red: 1 - red, green: 1 - green, blue: 1 - blue, alpha: 1)
	}

	func isBlackOrWhite() -> Bool {
		var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
		getRed(&red, green: &green, blue: &blue, alpha: &alpha)
		if red > 0.91 && green > 0.91 && blue > 0.91 {
			return true // white
		}
		if red < 0.09 && green < 0.09 && blue < 0.09 {
			return true // black
		}
		return false
	}

	func isDark() -> Bool {
		var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
		getRed(&red, green: &green, blue: &blue, alpha: &alpha)

		let lum = 0.2126 * red + 0.7152 * green + 0.0722 * blue

		if lum < 0.5 {
			return true
		}

		return false
	}

	func colorWithMinimumSaturation(_ minSaturation: CGFloat) -> UIColor {
		var hue: CGFloat = 0, sat: CGFloat = 0, val: CGFloat = 0, alpha: CGFloat = 0
		getHue(&hue, saturation: &sat, brightness: &val, alpha: &alpha)

		if sat < minSaturation {
			return UIColor(hue: hue, saturation: sat, brightness: val, alpha: alpha)
		}

		return self
	}

	func isDistinct(fromColor compareColor: UIColor) -> Bool {
		var red1: CGFloat = 0, green1: CGFloat = 0, blue1: CGFloat = 0, alpha1: CGFloat = 0
		var red2: CGFloat = 0, green2: CGFloat = 0, blue2: CGFloat = 0, alpha2: CGFloat = 0

		getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
		compareColor.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)

		let threshold: CGFloat = 0.25

		if abs(red1 - red2) > threshold || abs(green1 - green2) > threshold || abs(blue1 - blue2) > threshold || abs(alpha1 - alpha2) > threshold {
			// check for grays, prevent multiple gray colors
			if abs(red1 - green1) < 0.03 && abs(red1 - blue1) < 0.03 {
				if abs(red2 - green2) < 0.03 && abs(red2 - blue2) < 0.03 {
					return false
				}
			}

			return true
		}

		return false
	}

	func isContrasted(fromColor color: UIColor) -> Bool {
		var red1: CGFloat = 0, green1: CGFloat = 0, blue1: CGFloat = 0, alpha1: CGFloat = 0
		var red2: CGFloat = 0, green2: CGFloat = 0, blue2: CGFloat = 0, alpha2: CGFloat = 0
		getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
		color.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)

		let lum1 = 0.2126 * red1 + 0.7152 * green1 + 0.0722 * blue1
		let lum2 = 0.2126 * red2 + 0.7152 * green2 + 0.0722 * blue2
		var contrast: CGFloat = 0

		if lum1 > lum2 {
			contrast = (lum1 + 0.05) / (lum2 + 0.05)
		} else {
			contrast = (lum2 + 0.05) / (lum1 + 0.05)
		}
		return contrast > 1.6
	}
}
