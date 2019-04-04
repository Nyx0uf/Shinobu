import UIKit


final class NYXButton : UIButton
{
	override init(frame: CGRect)
	{
		super.init(frame: frame)

		self.layer.cornerRadius = frame.width / 2
		self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override var isSelected: Bool {
		willSet {
			self.backgroundColor = isSelected ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5) : UIColor.clear
		}

		didSet {
			self.backgroundColor = isSelected ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5) : UIColor.clear
		}
	}

	override var isHighlighted: Bool {
		willSet {
			self.backgroundColor = isHighlighted ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5) : UIColor.clear
		}

		didSet {
			self.backgroundColor = isHighlighted ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5) : UIColor.clear
		}
	}

	override var buttonType: UIButton.ButtonType
	{
		get
		{
			return .custom
		}
	}
}
