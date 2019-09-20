import UIKit

struct Theme {
	var tintColor: UIColor
}

public enum TintColorType: Int, CaseIterable {
	case blue = 1
	case green = 2
	case pink = 3
	case orange = 4
	case yellow = 5
}

public func colorForTintColorType(_ type: TintColorType) -> UIColor {
	switch type {
	case .orange:
		return UIColor(rgb: 0xFF6600)
	case .blue:
		return UIColor(rgb: 0x2F74FB)
	case .green:
		return UIColor(rgb: 0x1DC021)
	case .yellow:
		return UIColor(rgb: 0xFDB22B)
	case .pink:
		return UIColor(rgb: 0xFF00FF)
	}
}
