import UIKit

struct Theme {
	let statusBarStyle: UIStatusBarStyle
	let navigationBarStyle: UIBarStyle
	let blurEffect: UIBlurEffect
	let blurEffectAlt: UIBlurEffect
	var tintColor: UIColor
	let backgroundColor: UIColor
	let backgroundColorAlt: UIColor
	let navigationTitleTextColor: UIColor
	let tableSectionHeaderTextColor: UIColor
	let tableCellColor: UIColor
	let tableCellMainLabelTextColor: UIColor
	let tableCellDetailLabelTextColor: UIColor
	let tableSeparatorColor: UIColor
	let tableTextFieldTextColor: UIColor
	let switchTintColor: UIColor
	let textFieldPlaceholderTextColor: UIColor
	let miniPlayerButtonColor: UIColor
	let miniPlayerMainTextColor: UIColor
	let miniPlayerDetailTextColor: UIColor
	let miniPlayerProgressColor: UIColor
	let collectionImageViewBackgroundColor: UIColor
}

extension Theme {
	static let light = Theme(
		statusBarStyle: .default,
		navigationBarStyle: .default,
		blurEffect: .init(style: .light),
		blurEffectAlt: .init(style: .dark),
		tintColor: colorForTintColorType(TintColorType(rawValue: Settings.shared.integer(forKey: .pref_tintColor))!),
		backgroundColor: UIColor(rgb: 0xEFEFEF),
		backgroundColorAlt: UIColor(rgb: 0xE0E0E0),
		navigationTitleTextColor: UIColor(rgb: 0x222222),
		tableSectionHeaderTextColor: UIColor(rgb: 0x101010),
		tableCellColor: UIColor(rgb: 0xFFFFFF),
		tableCellMainLabelTextColor: UIColor(rgb: 0x222222),
		tableCellDetailLabelTextColor: UIColor(rgb: 0x999999),
		tableSeparatorColor: UIColor(rgb: 0xE0E0E0),
		tableTextFieldTextColor: UIColor(rgb: 0x000000),
		switchTintColor: UIColor(rgb: 0xE0E0E0),
		textFieldPlaceholderTextColor: UIColor(rgb: 0x999999),
		miniPlayerButtonColor: UIColor(rgb: 0x000000),
		miniPlayerMainTextColor: UIColor(rgb: 0x000000),
		miniPlayerDetailTextColor: UIColor(rgb: 0x222222),
		miniPlayerProgressColor: UIColor(rgb: 0x000000),
		collectionImageViewBackgroundColor: UIColor(rgb: 0x555555)
	)

	static let dark = Theme(
		statusBarStyle: .lightContent,
		navigationBarStyle: .black,
		blurEffect: .init(style: .dark),
		blurEffectAlt: .init(style: .extraLight),
		tintColor: colorForTintColorType(TintColorType(rawValue: Settings.shared.integer(forKey: .pref_tintColor))!),
		backgroundColor: UIColor(rgb: 0x111111),
		backgroundColorAlt: UIColor(rgb: 0x222222),
		navigationTitleTextColor: UIColor(rgb: 0xCCCCCC),
		tableSectionHeaderTextColor: UIColor(rgb: 0xAAAAAA),
		tableCellColor: UIColor(rgb: 0x000000),
		tableCellMainLabelTextColor: UIColor(rgb: 0xCCCCCC),
		tableCellDetailLabelTextColor: UIColor(rgb: 0x555555),
		tableSeparatorColor: UIColor(rgb: 0x1C1C1C),
		tableTextFieldTextColor: UIColor(rgb: 0xFFFFFF),
		switchTintColor: UIColor(rgb: 0xFFFFFF),
		textFieldPlaceholderTextColor: UIColor(rgb: 0x555555),
		miniPlayerButtonColor: UIColor(rgb: 0xFFFFFF),
		miniPlayerMainTextColor: UIColor(rgb: 0xFFFFFF),
		miniPlayerDetailTextColor: UIColor(rgb: 0xCCCCCC),
		miniPlayerProgressColor: UIColor(rgb: 0xFFFFFF),
		collectionImageViewBackgroundColor: UIColor(rgb: 0x999999)
	)
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
