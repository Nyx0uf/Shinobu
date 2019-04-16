import UIKit


class Slider: UIControl
{
	// MARK: - Public properties
	// Minimum value
	var minimumValue = CGFloat(0)
	// Maximum value
	var maximumValue = CGFloat(100)
	// Current value
	var value = CGFloat(0)
	{
		didSet
		{
			self.updateFrames()
		}
	}

	// MARK: - Private properties
	// Progress
	private var blurEffectView = UIVisualEffectView()

	// MARK: - Properties override
	override var frame: CGRect
	{
		didSet
		{
			self.blurEffectView.frame = CGRect(.zero, 0, frame.height)
			self.enableCorners(withDivisor: 2)
			self.updateFrames()
		}
	}

	// MARK: - Initializers
	init()
	{
		super.init(frame: .zero)

		self.backgroundColor = UIColor(white: 1, alpha: 0.1)

		self.enableCorners(withDivisor: 2)

		self.blurEffectView.effect = UIBlurEffect(style: .light)
		self.blurEffectView.isUserInteractionEnabled = false
		self.addSubview(self.blurEffectView)

		// Single tap to request full player view
		let singleTap = UITapGestureRecognizer()
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		singleTap.addTarget(self, action: #selector(singleTap(_:)))
		self.addGestureRecognizer(singleTap)
	}

	override init(frame: CGRect)
	{
		super.init(frame: frame)

		self.backgroundColor = UIColor(white: 1, alpha: 0.1)

		self.enableCorners(withDivisor: 2)

		self.blurEffectView.effect = UIBlurEffect(style: .light)
		self.blurEffectView.frame = CGRect(.zero, 0, frame.height)
		self.blurEffectView.isUserInteractionEnabled = false
		self.addSubview(self.blurEffectView)

		// Single tap to request full player view
		let singleTap = UITapGestureRecognizer()
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		singleTap.addTarget(self, action: #selector(singleTap(_:)))
		self.addGestureRecognizer(singleTap)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Gestures
	@objc func singleTap(_ gest: UITapGestureRecognizer)
	{
		if gest.state == .ended
		{
			let location = gest.location(in: self)

			let val = (location.x / bounds.width) * maximumValue
			value = clamp(val, lower: minimumValue, upper: maximumValue)
			updateFrames()

			sendActions(for: .touchUpInside)
		}
	}

	// MARK: - Public
	func updateFrames()
	{
		blurEffectView.width = clamp((bounds.width / maximumValue) * value, lower: 0, upper: bounds.width)
	}
}

// MARK: - Tracking
extension Slider
{
	override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool
	{
		return true
	}

	override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool
	{
		let location = touch.location(in: self)

		let val = (location.x / bounds.width) * maximumValue
		value = clamp(val, lower: minimumValue, upper: maximumValue)
		updateFrames()

		sendActions(for: .valueChanged)

		return true
	}

	override func endTracking(_ touch: UITouch?, with event: UIEvent?)
	{
		sendActions(for: .touchUpInside)
	}
}
