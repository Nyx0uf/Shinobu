import UIKit

final class ControlButton: UIControl {
	// MARK: - Public properties
	// Selected & Highlighted color
	private(set) var selectedTintColor = UIColor.clear
	// Button image
	private(set) var image = UIImage()
	private(set) var imageView = UIImageView()

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
		self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.layer.cornerRadius = frame.width / 2

		self.imageView.frame = bounds
		self.imageView.contentMode = .center
		self.addSubview(self.imageView)
	}

	// MARK: - Properties override
	override var frame: CGRect {
		didSet {
			self.layer.cornerRadius = frame.width / 2
			self.imageView.frame = CGRect(.zero, frame.size)
		}
	}

	override var isSelected: Bool {
		willSet {
			if self.isSelected {
				self.backgroundColor = self.selectedTintColor.withAlphaComponent(0.2)
				self.imageView.image = self.image.withTintColor(self.selectedTintColor)
			} else {
				self.backgroundColor = UIColor.clear
				self.imageView.image = self.image.withTintColor(self.tintColor)
			}
		}

		didSet {
			if self.isSelected {
				self.backgroundColor = self.selectedTintColor.withAlphaComponent(0.2)
				self.imageView.image = self.image.withTintColor(self.selectedTintColor)
			} else {
				self.backgroundColor = UIColor.clear
				self.imageView.image = self.image.withTintColor(self.tintColor)
			}
		}
	}

	override var isHighlighted: Bool {
		willSet {
			if self.isHighlighted {
				self.backgroundColor = self.selectedTintColor.withAlphaComponent(0.2)
				self.imageView.image = self.image.withTintColor(self.selectedTintColor)
			} else {
				self.backgroundColor = UIColor.clear
				self.imageView.image = self.image.withTintColor(self.tintColor)
			}
		}

		didSet {
			if self.isHighlighted {
				self.backgroundColor = self.selectedTintColor.withAlphaComponent(0.2)
				self.imageView.image = self.image.withTintColor(self.selectedTintColor)
			} else {
				self.backgroundColor = UIColor.clear
				self.imageView.image = self.image.withTintColor(self.tintColor)
			}
		}
	}

	// MARK: - Public
	func setImage(_ img: UIImage, tintColor: UIColor, selectedTintColor: UIColor) {
		self.image = img.withRenderingMode(.alwaysTemplate)
		self.tintColor = tintColor
		self.selectedTintColor = selectedTintColor
		imageView.image = self.image.withTintColor(tintColor)
	}
}
