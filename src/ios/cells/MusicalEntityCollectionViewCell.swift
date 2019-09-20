import UIKit

final class MusicalEntityCollectionViewCell: UICollectionViewCell {
	// MARK: - Public properties
	// Album cover view
	var imageView: UIImageView! = nil
	// Entity name
	var label: UILabel! = nil
	// Cover
	var image: UIImage? = nil {
		didSet {
			imageView.image = image
		}
	}
	// Flag to indicate that the cell is being long pressed
	var longPressed: Bool = false {
		didSet {
			if longPressed {
				UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
					self.label.textColor = self.themeProvider.currentTheme.tintColor
					let anim = CABasicAnimation(keyPath: "borderWidth")
					anim.fromValue = 0
					anim.toValue = 1
					anim.duration = 0.2
					anim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
					self.imageView.layer.add(anim, forKey: "kawaii-anim")
				}, completion: { (_) in
					self.imageView.layer.borderWidth = 1
				})
			} else {
				UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
					self.label.textColor = .secondaryLabel
					let anim = CABasicAnimation(keyPath: "borderWidth")
					anim.fromValue = 1
					anim.toValue = 0
					anim.duration = 0.2
					anim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
					self.imageView.layer.add(anim, forKey: "kawaii-anim")
				}, completion: { (_) in
					self.imageView.layer.borderWidth = 0
				})
			}
		}
	}
	// Flag to indicate the type of entity for the cell
	var type: MusicalEntityType = .albums {
		didSet {
			var cornerRadius = CGFloat(0)
			var contentMode = UIView.ContentMode.scaleToFill
			switch type {
			case .albums:
				cornerRadius = 12.0
			case .artists, .albumsartists:
				contentMode = .center
				cornerRadius = imageView.width / 2.0
			case .genres:
				cornerRadius = imageView.width
			case .playlists:
				cornerRadius = 0.0
			default:
				cornerRadius = 0.0
			}
			imageView.layer.cornerRadius = cornerRadius
			imageView.contentMode = contentMode
		}
	}
	//
	private(set) var imageTintColor: UIColor!

	// MARK: - Initializers
	override init(frame: CGRect) {
		super.init(frame: frame)

		self.isAccessibilityElement = true
		self.backgroundColor = .systemGroupedBackground

		self.imageView = UIImageView(frame: CGRect(.zero, frame.width, frame.height - 20))
		self.imageView.isAccessibilityElement = false
		self.imageView.enableCorners(withDivisor: 4)
		self.contentView.addSubview(self.imageView)

		self.label = UILabel(frame: CGRect(0, self.imageView.maxY, frame.width, 20))
		self.label.backgroundColor = self.backgroundColor
		self.label.isAccessibilityElement = false
		self.label.textAlignment = .center
		self.label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
		self.label.textColor = .secondaryLabel
		self.contentView.addSubview(self.label)

		initializeTheming()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override func layoutSubviews() {
		imageView.frame = CGRect(.zero, frame.width, frame.height - 20)
		label.frame = CGRect(0, imageView.maxY, frame.width, 20)
	}
}

extension MusicalEntityCollectionViewCell: Themed {
	func applyTheme(_ theme: Theme) {
		imageView.layer.borderColor = theme.tintColor.cgColor
	}
}
