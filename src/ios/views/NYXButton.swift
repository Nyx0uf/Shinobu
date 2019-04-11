import UIKit


final class NYXButton: UIButton
{
	override init(frame: CGRect)
	{
		super.init(frame: frame)

		self.layer.cornerRadius = frame.width / 2
		self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.tintColor = .white

		initializeTheming()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override var isSelected: Bool
	{
		willSet
		{
			self.backgroundColor = isSelected ? themeProvider.currentTheme.tintColor : UIColor.clear
		}

		didSet
		{
			self.backgroundColor = isSelected ? themeProvider.currentTheme.tintColor : UIColor.clear
		}
	}

	override var isHighlighted: Bool
	{
		willSet
		{
			self.backgroundColor = isHighlighted ? themeProvider.currentTheme.tintColor : UIColor.clear
		}

		didSet
		{
			self.backgroundColor = isHighlighted ? themeProvider.currentTheme.tintColor : UIColor.clear
		}
	}

	override var buttonType: UIButton.ButtonType
	{
		return .custom
	}
}

extension NYXButton: Themed
{
	func applyTheme(_ theme: Theme)
	{

	}
}
