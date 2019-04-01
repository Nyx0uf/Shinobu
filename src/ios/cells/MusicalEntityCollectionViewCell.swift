import UIKit


final class MusicalEntityBaseCell : UICollectionViewCell
{
	// MARK: - Public properties
	// Album cover view
	var imageView: UIImageView! = nil
	// Entity name
	var label: UILabel! = nil
	// Cover
	var image: UIImage? = nil
	{
		didSet
		{
			imageView.image = image
		}
	}
	// Flag to indicate that the cell is being long pressed
	var longPressed: Bool = false
	{
		didSet
		{
			if longPressed
			{
				UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
					self.label.textColor = Colors.main
					let anim = CABasicAnimation(keyPath: "borderWidth")
					anim.fromValue = 0
					anim.toValue = 1
					anim.duration = 0.2
					anim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
					self.imageView.layer.add(anim, forKey: "kawaii-anim")
				}, completion:{ finished in
					self.imageView.layer.borderWidth = 1
				})
			}
			else
			{
				UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
					self.label.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
					let anim = CABasicAnimation(keyPath: "borderWidth")
					anim.fromValue = 1
					anim.toValue = 0
					anim.duration = 0.2
					anim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
					self.imageView.layer.add(anim, forKey: "kawaii-anim")
				}, completion:{ finished in
					self.imageView.layer.borderWidth = 0
				})
			}
		}
	}
	//
	var type: MusicalEntityType = .albums
	{
		didSet
		{
			var cornerRadius = CGFloat(0)
			var contentMode = UIView.ContentMode.scaleToFill
			switch type
			{
				case .albums:
					cornerRadius = 12.0
				case .artists, .albumsartists:
					contentMode = .center
					cornerRadius = self.imageView.width / 2.0
				case .genres:
					cornerRadius = self.imageView.width
				case .playlists:
					cornerRadius = 0.0
				default:
					cornerRadius = 0.0
			}
			self.imageView.layer.cornerRadius = cornerRadius
			self.imageView.contentMode = contentMode
		}
	}

	// MARK: - Private properties
	private var associatedKey = "fr.whine.key.cell"

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		self.backgroundColor = Colors.background
		self.isAccessibilityElement = true

		self.imageView = UIImageView(frame: CGRect(.zero, frame.width, frame.height - 20.0))
		self.imageView.isAccessibilityElement = false
		self.imageView.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		self.imageView.layer.borderColor = Colors.main.cgColor
		self.imageView.clipsToBounds = true
		self.imageView.layer.cornerRadius = 12.0
		self.imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.contentView.addSubview(self.imageView)

		self.label = UILabel(frame: CGRect(0.0, self.imageView.bottom, frame.width, 20.0))
		self.label.isAccessibilityElement = false
		self.label.backgroundColor = self.backgroundColor
		self.label.textAlignment = .center
		self.label.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		self.label.font = UIFont.systemFont(ofSize: 10.0, weight: .semibold)
		self.contentView.addSubview(self.label)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews()
	{
		self.imageView.frame = CGRect(.zero, frame.width, frame.height - 20.0)
		self.label.frame = CGRect(0.0, self.imageView.bottom, frame.width, 20.0)
	}

	// MARK: - Overrides
	override var isSelected: Bool
	{
		didSet
		{
			if isSelected
			{
				label.font = UIFont.systemFont(ofSize: 10.0, weight: .black)
				imageView.layer.borderWidth = 1
			}
			else
			{
				label.font = UIFont.systemFont(ofSize: 10.0, weight: .semibold)
				imageView.layer.borderWidth = 0
			}
		}
	}

	override var isHighlighted: Bool
	{
		didSet
		{
			if isHighlighted
			{
				label.font = UIFont.systemFont(ofSize: 10.0, weight: .black)
				imageView.layer.borderWidth = 1
			}
			else
			{
				label.font = UIFont.systemFont(ofSize: 10.0, weight: .semibold)
				imageView.layer.borderWidth = 0
			}
		}
	}

	var associatedObject: Any?
	{
		set
		{
			objc_setAssociatedObject(self, &associatedKey, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
		get
		{
			return objc_getAssociatedObject(self, &associatedKey)
		}
	}
}
