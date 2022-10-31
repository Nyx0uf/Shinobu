import UIKit

final class NYXNavigationTitleView: UIButton {
	// MARK: - Public properties
	// Main text
	private(set) var mainText: String = ""
	// Optional detail text
	private(set) var detailText: String?

	// MARK: - Private properties
	// Button label
	private let label = UILabel()

	// MARK: - Override properties
	override var isHighlighted: Bool {
		didSet {
			if oldValue != isHighlighted {
				updateDisplay()
			}
		}
	}

	override var isSelected: Bool {
		didSet {
			if oldValue != isSelected {
				updateDisplay()
			}
		}
	}

	override var isEnabled: Bool {
		didSet {
			if oldValue != isEnabled {
				updateDisplay()
			}
		}
	}

	// MARK: - Initializers
	override init(frame: CGRect) {
		super.init(frame: frame)

		self.isAccessibilityElement = true

		self.label.frame = CGRect(.zero, frame.size)
		self.label.textAlignment = .center
		self.addSubview(self.label)

		self.accessibilityLabel = NYXLocalizedString("lbl_change_displaytype")
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override var intrinsicContentSize: CGSize {
		UIView.layoutFittingExpandedSize
	}

	// MARK: - Public
	public func setMainText(_ mainText: String, detailText: String?) {
		self.mainText = mainText
		self.detailText = detailText
		updateDisplay()
	}

	// MARK: - Private
	private func updateDisplay() {
		let color = (isHighlighted || isSelected) ? UIColor.shinobuTintColor : .label

		if let detailText = self.detailText {
			label.numberOfLines = 2

			// Main text
			let attrs = NSMutableAttributedString(string: "\(mainText)\n", attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .medium), .foregroundColor: color])
			// Detail text
			attrs.append(NSAttributedString(string: detailText, attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .regular), .foregroundColor: color]))
			label.attributedText = attrs
		} else {
			label.numberOfLines = 1
			label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
			label.textColor = color
			label.text = mainText
		}
	}
}
