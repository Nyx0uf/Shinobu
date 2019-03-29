import UIKit


extension UIColor
{
	// MARK: - Initializers
	public convenience init(rgb: Int32, alpha: CGFloat)
	{
		let red = ((CGFloat)((rgb & 0xFF0000) >> 16)) / 255
		let green = ((CGFloat)((rgb & 0x00FF00) >> 8)) / 255
		let blue = ((CGFloat)(rgb & 0x0000FF)) / 255

		self.init(red: red, green: green, blue: blue, alpha: alpha)
	}

	public convenience init(rgb: Int32)
	{
		self.init(rgb: rgb, alpha: 1.0)
	}

	func inverted() -> UIColor
	{
		var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
		getRed(&r, green: &g, blue: &b, alpha: &a)
		return UIColor(red: 1.0 - r, green: 1.0 - g, blue: 1.0 - b, alpha: 1.0)
	}

	func isBlackOrWhite() -> Bool
	{
		var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
		getRed(&r, green: &g, blue: &b, alpha: &a)
		if r > 0.91 && g > 0.91 && b > 0.91
		{
			return true // white
		}
		if r < 0.09 && g < 0.09 && b < 0.09
		{
			return true // black
		}
		return false
	}

	func isDark() -> Bool
	{
		var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
		getRed(&r, green: &g, blue: &b, alpha: &a)

		let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b

		if lum < 0.5
		{
			return true
		}

		return false
	}

	func colorWithMinimumSaturation(_ minSaturation: CGFloat) -> UIColor
	{
		var h: CGFloat = 0.0, s: CGFloat = 0.0, v: CGFloat = 0.0, a: CGFloat = 0.0
		getHue(&h, saturation: &s, brightness: &v, alpha: &a)

		if s < minSaturation
		{
			return UIColor(hue: h, saturation: s, brightness: v, alpha: a)
		}

		return self
	}

	func isDistinct(fromColor compareColor: UIColor) -> Bool
	{
		var r1: CGFloat = 0.0, g1: CGFloat = 0.0, b1: CGFloat = 0.0, a1: CGFloat = 0.0
		var r2: CGFloat = 0.0, g2: CGFloat = 0.0, b2: CGFloat = 0.0, a2: CGFloat = 0.0

		self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
		compareColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

		let threshold: CGFloat = 0.25

		if abs(r1 - r2) > threshold || abs(g1 - g2) > threshold || abs(b1 - b2) > threshold || abs(a1 - a2) > threshold
		{
			// check for grays, prevent multiple gray colors
			if abs(r1 - g1) < 0.03 && abs(r1 - b1) < 0.03
			{
				if abs(r2 - g2) < 0.03 && abs(r2 - b2) < 0.03
				{
					return false
				}
			}

			return true
		}

		return false
	}

	func isContrasted(fromColor color: UIColor) -> Bool
	{
		var r1: CGFloat = 0.0, g1: CGFloat = 0.0, b1: CGFloat = 0.0, a1: CGFloat = 0.0
		var r2: CGFloat = 0.0, g2: CGFloat = 0.0, b2: CGFloat = 0.0, a2: CGFloat = 0.0
		getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
		color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

		let lum1 = 0.2126 * r1 + 0.7152 * g1 + 0.0722 * b1
		let lum2 = 0.2126 * r2 + 0.7152 * g2 + 0.0722 * b2
		var contrast: CGFloat = 0.0

		if lum1 > lum2
		{
			contrast = (lum1 + 0.05) / (lum2 + 0.05)
		}
		else
		{
			contrast = (lum2 + 0.05) / (lum1 + 0.05)
		}
		return contrast > 1.6
	}
}
