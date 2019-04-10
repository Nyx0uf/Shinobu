import UIKit


struct ShinobuTheme
{
	var tintColor: UIColor
	let statusBarStyle: UIStatusBarStyle
	let navigationBarStyle: UIBarStyle
	let blurEffect: UIBlurEffect
	let blurEffectAlt: UIBlurEffect
	let backgroundColor: UIColor
	let backgroundColorSelected: UIColor
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

extension ShinobuTheme
{
	static let light = ShinobuTheme(
		tintColor: colorForTintColorType(TintColorType(rawValue: Settings.shared.integer(forKey: .pref_tintColor))!),
		statusBarStyle: .default,
		navigationBarStyle: .default,
		blurEffect: .init(style: .light),
		blurEffectAlt: .init(style: .dark),
		backgroundColor: UIColor.groupTableViewBackground,
		backgroundColorSelected: UIColor(red: 224/255.0, green: 224/255.0, blue: 224/255.0, alpha: 1),
		backgroundColorAlt: UIColor(red: 224/255.0, green: 224/255.0, blue: 224/255.0, alpha: 1),
		navigationTitleTextColor: .black,
		tableSectionHeaderTextColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.8),
		tableCellColor: .white,
		tableCellMainLabelTextColor: .black,
		tableCellDetailLabelTextColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.8),
		tableSeparatorColor: UIColor(red: 224/255.0, green: 224/255.0, blue: 224/255.0, alpha: 1),
		tableTextFieldTextColor: .black,
		switchTintColor: UIColor(red: 224/255.0, green: 224/255.0, blue: 224/255.0, alpha: 1),
		textFieldPlaceholderTextColor: UIColor(red: 224/255.0, green: 224/255.0, blue: 224/255.0, alpha: 1),
		miniPlayerButtonColor: .black,
		miniPlayerMainTextColor: .black,
		miniPlayerDetailTextColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.8),
		miniPlayerProgressColor: .black,
		collectionImageViewBackgroundColor: UIColor(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
	)

	static let dark = ShinobuTheme(
		tintColor: colorForTintColorType(TintColorType(rawValue: Settings.shared.integer(forKey: .pref_tintColor))!),
		statusBarStyle: .lightContent,
		navigationBarStyle: .blackTranslucent,
		blurEffect: .init(style: .dark),
		blurEffectAlt: .init(style: .extraLight),
		backgroundColor: UIColor(red: 0.06666666667, green: 0.06666666667, blue: 0.06666666667, alpha: 1),
		backgroundColorSelected: UIColor(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1),
		backgroundColorAlt: UIColor(red: 0.1725490196, green: 0.1725490196, blue: 0.1725490196, alpha: 1),
		navigationTitleTextColor: UIColor(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1),
		tableSectionHeaderTextColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.8),
		tableCellColor: .black,
		tableCellMainLabelTextColor: UIColor(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1),
		tableCellDetailLabelTextColor: UIColor(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1),
		tableSeparatorColor: UIColor(red: 0.1019607843, green: 0.1019607843, blue: 0.1019607843, alpha: 1),
		tableTextFieldTextColor: .white,
		switchTintColor: .white,
		textFieldPlaceholderTextColor: UIColor(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1),
		miniPlayerButtonColor: .white,
		miniPlayerMainTextColor: .white,
		miniPlayerDetailTextColor: UIColor(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1),
		miniPlayerProgressColor: .white,
		collectionImageViewBackgroundColor: UIColor(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
	)
}

public enum TintColorType: Int, CaseIterable
{
	case blue = 1
	case green = 2
	case pink = 3
	case orange = 4
	case yellow = 5
}

public func colorForTintColorType(_ type: TintColorType) -> UIColor
{
	switch type
	{
		case .orange:
			return UIColor(red: 1, green: 0.4, blue: 0, alpha: 1)
		case .blue:
			return UIColor(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
		case .green:
			return UIColor(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
		case .yellow:
			return UIColor(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
		case .pink:
			return UIColor(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
	}
}
