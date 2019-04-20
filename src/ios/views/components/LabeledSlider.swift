import UIKit


fileprivate let marginX = CGFloat(5)


final class LabeledSlider: Slider
{
	// MARK: - Private proerties
	private(set) var label = AutoScrollLabel()

	// MARK: - Properties override
	override var frame: CGRect
	{
		didSet
		{
			self.label.frame = CGRect(marginX, 0, frame.width - 2 * marginX, frame.height)
			self.enableCorners(withDivisor: 4)
		}
	}

	// MARK: - Initializers
	override init()
	{
		super.init()

		commonInit()
	}

	override init(frame: CGRect)
	{
		super.init(frame: frame)

		commonInit()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	private func commonInit()
	{
		self.label.frame = CGRect(marginX, 0, frame.width - 2 * marginX, frame.height)
		self.label.backgroundColor = .clear
		self.label.isAccessibilityElement = false
		self.addSubview(self.label)

		self.enableCorners(withDivisor: 4)
	}
}
