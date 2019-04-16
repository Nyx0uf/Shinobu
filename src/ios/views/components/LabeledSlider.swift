import UIKit


final class LabeledSlider: Slider
{
	// MARK: - Private proerties
	private(set) var label = AutoScrollLabel()

	// MARK: - Properties override
	override var frame: CGRect
	{
		didSet
		{
			self.label.frame = CGRect(5, 0, frame.width - 10, frame.height)
			self.enableCorners(withDivisor: 4)
		}
	}

	// MARK: - Initializers
	override init()
	{
		super.init()

		self.label.backgroundColor = .clear
		self.label.isAccessibilityElement = false
		self.addSubview(self.label)
	}

	override init(frame: CGRect)
	{
		self.label.frame = CGRect((frame.width - frame.height) / 2, 0, frame.height, frame.height)
		self.label.backgroundColor = .clear
		self.label.isAccessibilityElement = false

		super.init(frame: frame)

		self.addSubview(self.label)

		self.enableCorners(withDivisor: 4)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }
}
