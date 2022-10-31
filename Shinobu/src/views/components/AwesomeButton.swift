import UIKit

enum ImagePosition {
	case top
	case bottom
	case left
	case right
}

final class AwesomeButton: UIControl {
	// MARK: - Private properties
	// Label
	private let label = UILabel()
	// Image view
	private let symbolView = UIImageView()
	// Actual SFSymbol image
	private var image: UIImage?

	// MARK: - Public properties
	// Image name (SFSymbol)
	var symbolName: String {
		didSet {
			self.image = UIImage(systemName: symbolName, withConfiguration: symbolConfiguration)
			symbolView.image = image
			self.updateLayout()
		}
	}
	// Symbol configuration
	var symbolConfiguration: UIImage.SymbolConfiguration {
		didSet {
			self.image = UIImage(systemName: symbolName, withConfiguration: symbolConfiguration)
			symbolView.image = image
			self.updateLayout()
		}
	}
	// Selected & Highlighted color
	var selectedTintColor = UIColor.clear {
		didSet {
			label.highlightedTextColor = selectedTintColor
		}
	}
	// Image position
	var imagePosition: ImagePosition {
		didSet {
			switch imagePosition {
			case .top, .bottom:
				label.textAlignment = .center
			case .left:
				label.textAlignment = .left
			case .right:
				label.textAlignment = .right
			}
			self.updateLayout()
		}
	}
	// Margin (top,right,bottom,left) between image and label
	let space = CGFloat(4)
	// Should underline text
	var isUnderlined = false {
		didSet {
			self.text = self.label.text // Trigger update
		}
	}

	// MARK: - Initializers
	init(text: String, font: UIFont, symbolName: String, symbolConfiguration: UIImage.SymbolConfiguration, imagePosition: ImagePosition) {
		self.imagePosition = imagePosition
		self.symbolConfiguration = symbolConfiguration
		self.symbolName = symbolName

		self.image = UIImage(systemName: symbolName, withConfiguration: symbolConfiguration)

		super.init(frame: .zero)

		self.symbolView.image = image
		self.symbolView.isUserInteractionEnabled = false
		self.addSubview(self.symbolView)

		self.text = text
		self.font = font
		self.label.numberOfLines = 1
		self.label.isUserInteractionEnabled = false
		self.addSubview(self.label)

		self.updateLayout()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Gestures
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesBegan(touches, with: event)
		symbolView.tintColor = self.selectedTintColor
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesEnded(touches, with: event)
		symbolView.tintColor = self.tintColor
	}

	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesCancelled(touches, with: event)
		symbolView.tintColor = self.tintColor
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesMoved(touches, with: event)
		symbolView.tintColor = self.selectedTintColor
	}

	// MARK: - Private
	private func updateLayout() {
		let imageSize = self.image?.size ?? .zero
		let textSize = self.text?.size(withFont: font) ?? .zero
		let viewSize = AwesomeButton.sizeForSelf(imageSize: imageSize, textSize: textSize, imagePosition: imagePosition, space: space)
		self.size = viewSize.ceilled()

		switch imagePosition {
		case .top:
			symbolView.frame = CGRect((viewSize.width - imageSize.width) / 2, 0, imageSize).ceilled()
			label.frame = CGRect((viewSize.width - textSize.width) / 2, imageSize.height, textSize).ceilled()
		case .bottom:
			symbolView.frame = CGRect((viewSize.width - imageSize.width) / 2, textSize.height, imageSize).ceilled()
			label.frame = CGRect((viewSize.width - textSize.width) / 2, 0, textSize).ceilled()
		case .left:
			symbolView.frame = CGRect(0, (viewSize.height - imageSize.height) / 2, imageSize).ceilled()
			label.frame = CGRect(imageSize.width + space, (viewSize.height - textSize.height) / 2, textSize).ceilled()
		case .right:
			symbolView.frame = CGRect(textSize.width + space, (viewSize.height - imageSize.height) / 2, imageSize).ceilled()
			label.frame = CGRect(0, (viewSize.height - textSize.height) / 2, textSize).ceilled()
		}
	}
}

// MARK: - Static
extension AwesomeButton {
	private static func sizeForSelf(imageSize: CGSize, textSize: CGSize, imagePosition: ImagePosition, space: CGFloat) -> CGSize {
		var size = CGSize.zero
		switch imagePosition {
		case .top, .bottom:
			size.width = max(imageSize.width, textSize.width)
			size.height = imageSize.height + textSize.height + space
		case .left, .right:
			size.width = imageSize.width + textSize.width + space
			size.height = max(imageSize.height, textSize.height)
		}
		return size
	}
}

// MARK: - UILabel properties
extension AwesomeButton {
	// Text
	public var text: String? {
		get {
			return self.label.text
		}
		set {
			self.label.text = newValue

			if let s = newValue, isUnderlined == true {
				let attributedText = NSMutableAttributedString(string: s)
				attributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: s.count))
				self.attributedText = attributedText
			} else {
				self.updateLayout()
			}
		}
	}

	// Attributed text
	public var attributedText: NSAttributedString? {
		get {
			return self.label.attributedText
		}
		set {
			self.label.attributedText = newValue
			self.updateLayout()
		}
	}

	// Text color
	public var textColor: UIColor! {
		get {
			return self.label.textColor
		}
		set {
			self.label.textColor = newValue
		}
	}

	// Font
	public var font: UIFont! {
		get {
			return self.label.font
		}
		set {
			self.label.font = newValue
			self.updateLayout()
		}
	}
}

// MARK: - UIView properties
extension AwesomeButton {
	override var backgroundColor: UIColor? {
		willSet {
			self.label.backgroundColor = newValue
			self.symbolView.backgroundColor = newValue
		}
	}

	override var isHighlighted: Bool {
		willSet {
			self.label.isHighlighted = newValue
			self.symbolView.isHighlighted = newValue
		}
		didSet {
			self.label.isHighlighted = self.isHighlighted
			self.symbolView.isHighlighted = self.isHighlighted
		}
	}
}
