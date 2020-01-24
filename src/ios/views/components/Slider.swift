import UIKit

class Slider: UIControl {
	// MARK: - Public properties
	// Minimum value
	var minimumValue = CGFloat(0)
	// Maximum value
	var maximumValue = CGFloat(100)
	// Current value
	var value = CGFloat(0) {
		didSet {
			self.updateFrames()
		}
	}

	// MARK: - Private properties
	// Progress
	private var blurEffectView = UIVisualEffectView()

	// MARK: - Properties override
	override var frame: CGRect {
		didSet {
			self.blurEffectView.frame = CGRect(.zero, 0, frame.height)
			self.enableCorners(withDivisor: 2)
			self.updateFrames()
		}
	}

	// MARK: - Initializers
	init() {
		super.init(frame: .zero)

		commonInit()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		commonInit()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	private func commonInit() {
		self.backgroundColor = UIColor(white: 1, alpha: 0.1)

		self.enableCorners(withDivisor: 2)

		self.blurEffectView.effect = UIBlurEffect(style: .light)
		self.blurEffectView.frame = CGRect(.zero, 0, frame.height)
		self.blurEffectView.isUserInteractionEnabled = false
		self.addSubview(self.blurEffectView)

		// Single tap
		let singleTap = UITapGestureRecognizer()
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		singleTap.addTarget(self, action: #selector(singleTap(_:)))
		self.addGestureRecognizer(singleTap)
	}

	// MARK: - Gestures
	@objc func singleTap(_ gest: UITapGestureRecognizer) {
		if gest.state == .ended {
			updateValueForLocation(gest.location(in: self))
			updateFrames()

			sendActions(for: .touchUpInside)
		}
	}

	// MARK: - Internal
	internal func updateFrames() {
		blurEffectView.width = clamp((bounds.width / maximumValue) * value, lower: 0, upper: bounds.width)
	}

	// MARK: - Private
	private func updateValueForLocation(_ location: CGPoint) {
		let val = (location.x / bounds.width) * maximumValue
		value = clamp(val, lower: minimumValue, upper: maximumValue)
	}
}

// MARK: - Tracking
extension Slider {
	override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		true
	}

	override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		updateValueForLocation(touch.location(in: self))
		updateFrames()

		sendActions(for: .valueChanged)

		return true
	}

	override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
	}
}
