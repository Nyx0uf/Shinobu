import UIKit


final class NYXNavigationTitleView : UIButton
{
	// MARK: - Public properties
	// Main text
	private(set) var mainText: String = ""
	// Optional detail text
	private(set) var detailText: String? = nil

	// MARK: - Private properties
	// Button label
	private let label = UILabel()

	// MARK: - Override properties
	override var isHighlighted: Bool
	{
		didSet
		{
			if oldValue != isHighlighted
			{
				updateDisplay()
			}
		}
	}

	override var isSelected: Bool
	{
		didSet
		{
			if oldValue != isSelected
			{
				updateDisplay()
			}
		}
	}

	override var isEnabled: Bool
	{
		didSet
		{
			if oldValue != isEnabled
			{
				updateDisplay()
			}
		}
	}

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame: frame)

		self.isAccessibilityElement = true

		self.label.frame = CGRect(0, 0, frame.size)
		self.label.textAlignment = .center
		self.addSubview(self.label)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Public
	public func setMainText(_ mainText: String, detailText: String?)
	{
		self.mainText = mainText
		self.detailText = detailText
		self.updateDisplay()
	}

	// MARK: - Private
	private func updateDisplay()
	{
		let color = self.isHighlighted || self.isSelected ? Colors.mainEnabled : #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

		if let detailText = self.detailText
		{
			self.label.numberOfLines = 2

			// Main text
			let attrs = NSMutableAttributedString(string: "\(mainText)\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15, weight: .medium), NSAttributedString.Key.foregroundColor : color])
			// Detail text
			attrs.append(NSAttributedString(string: detailText, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .regular), NSAttributedString.Key.foregroundColor : color]))
			self.label.attributedText = attrs
		}
		else
		{
			self.label.numberOfLines = 1
			self.label.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
			self.label.textColor = color
			self.label.text = mainText
		}
	}
}
