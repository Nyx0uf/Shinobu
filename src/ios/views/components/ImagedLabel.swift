import UIKit

private let space = CGFloat(4)

final class ImagedLabel: UIControl {
	// MARK: - Public properties
	// Label
	private(set) var label = UILabel()
	// Image
	private(set) var imageView = UIImageView()
	// Alignment (lbl & image)
	var align = NSTextAlignment.left {
		didSet {
			self.label.textAlignment = align
			self.updateFrames()
		}
	}
	// Underline text
	var underlined = false

	// MARK: - Properties override
	override var frame: CGRect {
		didSet {
			self.updateFrames()
		}
	}

	// MARK: - UILabel properties
	// Text
	public var text: String? {
		get {
			self.label.text
		}
		set {
			self.label.text = newValue

			if let s = newValue {
				if underlined {
					let attributedText = NSMutableAttributedString(string: s)
					attributedText.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: s.count))
					self.attributedText = attributedText
				}
			}
		}
	}
	// Attributed text
	public var attributedText: NSAttributedString? {
		get {
			self.label.attributedText
		}
		set {
			self.label.attributedText = newValue
		}
	}
	// Text color
	public var textColor: UIColor! {
		get {
			self.label.textColor
		}
		set {
			self.label.textColor = newValue
		}
	}
	// Highlighted text color
	public var highlightedTextColor: UIColor? {
		get {
			self.label.highlightedTextColor
		}
		set {
			self.label.highlightedTextColor = newValue
		}
	}
	// Font
	public var font: UIFont! {
		get {
			self.label.font
		}
		set {
			self.label.font = newValue
		}
	}

	// MARK: - UIImageView properties
	// Image
	public var image: UIImage? {
		get {
			self.imageView.image
		}
		set {
			self.imageView.image = newValue
		}
	}
	// Highlighted Image
	public var highlightedImage: UIImage? {
		get {
			self.imageView.highlightedImage
		}
		set {
			self.imageView.highlightedImage = newValue
		}
	}

	// MARK: - Override
	override var isHighlighted: Bool {
		willSet {
			self.label.isHighlighted = newValue
			self.imageView.isHighlighted = newValue
		}
		didSet {
			self.label.isHighlighted = self.isHighlighted
			self.imageView.isHighlighted = self.isHighlighted
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
		self.imageView.frame = CGRect(.zero, frame.height, frame.height)
		self.addSubview(self.imageView)

		self.label.frame = CGRect(self.imageView.maxX + space, 0, frame.width - self.imageView.maxX - space, frame.height)
		self.addSubview(self.label)

		// Single tap to request full player view
		let singleTap = UITapGestureRecognizer()
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		singleTap.addTarget(self, action: #selector(singleTap(_:)))
		self.addGestureRecognizer(singleTap)
	}

	// MARK: - Gestures
	@objc func singleTap(_ gest: UITapGestureRecognizer) {
		if gest.state == .ended {
			sendActions(for: .touchUpInside)
		}
	}

	// MARK: - Private
	private func updateFrames() {
		if align == .left {
			imageView.frame = CGRect(.zero, frame.height, frame.height)
			label.frame = CGRect(imageView.maxX + space, 0, frame.width - imageView.maxX - space, frame.height)
		} else {
			imageView.frame = CGRect(frame.width - frame.height, 0, frame.height, frame.height)
			label.frame = CGRect(.zero, frame.width - frame.height - space, frame.height)
		}
	}
}
