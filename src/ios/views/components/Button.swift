import UIKit


final class Button: UIButton
{
	// MARK: - Initializers
	init()
	{
		super.init(frame: .zero)

		self.tintColor = UIColor(rgb: 0xFFFFFF)

		initializeTheming()
	}

	override init(frame: CGRect)
	{
		super.init(frame: frame)

		self.layer.cornerRadius = frame.width / 2
		self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.tintColor = UIColor(rgb: 0xFFFFFF)

		initializeTheming()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Properties override
	override var isSelected: Bool
	{
		willSet
		{
			self.backgroundColor = isSelected ? themeProvider.currentTheme.tintColor.withAlphaComponent(0.2) : UIColor.clear
		}

		didSet
		{
			self.backgroundColor = isSelected ? themeProvider.currentTheme.tintColor.withAlphaComponent(0.2) : UIColor.clear
		}
	}

	override var isHighlighted: Bool
	{
		willSet
		{
			self.backgroundColor = isHighlighted ? themeProvider.currentTheme.tintColor.withAlphaComponent(0.2) : UIColor.clear
		}

		didSet
		{
			self.backgroundColor = isHighlighted ? themeProvider.currentTheme.tintColor.withAlphaComponent(0.2) : UIColor.clear
		}
	}

	override var buttonType: UIButton.ButtonType
	{
		return .custom
	}

	override var frame: CGRect
	{
		didSet
		{
			self.layer.cornerRadius = frame.width / 2
			self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		}
	}

	// MARK: - Public
	func setImage(_ image: UIImage)
	{
		let img = image.withRenderingMode(.alwaysTemplate)
		super.setImage(img.tinted(withColor: themeProvider.currentTheme.miniPlayerButtonColor), for: .normal)
		super.setImage(img.tinted(withColor: themeProvider.currentTheme.tintColor), for: .highlighted)
		super.setImage(img.tinted(withColor: themeProvider.currentTheme.tintColor), for: .selected)
	}
}

extension Button: Themed
{
	func applyTheme(_ theme: Theme)
	{

	}
}
