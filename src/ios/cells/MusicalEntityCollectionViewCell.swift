import UIKit


final class MusicalEntityBaseCell : UICollectionViewCell
{
	// MARK: - Public properties
	// Album cover
	var imageView: UIImageView! = nil
	// Entity name
	var label: UILabel! = nil
	// auxiliary label (optional)
	var detailLabel: UILabel! = nil
	// Original image set
	var image: UIImage? = nil
	{
		didSet
		{
			imageView.image = image
		}
	}
	var layoutList = false
	// Flag to indicate that the cell is being long pressed
	var longPressed: Bool = false
	{
		didSet
		{
			if longPressed
			{
				UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
					self.label.textColor = Colors.main
					self.detailLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
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
					self.detailLabel.textColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
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
			if oldValue != type
			{
				var cornerRadius = CGFloat(0)
				switch type
				{
					case .albums:
						cornerRadius = 12.0
					case .artists, .albumsartists:
						cornerRadius = self.imageView.width / 2.0
					case .genres:
						cornerRadius = self.imageView.width
					case .playlists:
						cornerRadius = 0.0
				}
				self.imageView.layer.cornerRadius = cornerRadius
			}
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

		self.imageView = UIImageView(frame: .zero)
		self.imageView.isAccessibilityElement = false
		self.imageView.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		self.imageView.layer.borderColor = Colors.main.cgColor
		self.imageView.clipsToBounds = true
		self.imageView.layer.cornerRadius = 12.0
		self.imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.contentView.addSubview(self.imageView)

		self.label = UILabel(frame: .zero)
		self.label.isAccessibilityElement = false
		self.label.backgroundColor = self.backgroundColor
		self.label.textAlignment = .center
		self.label.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		self.label.font = UIFont.systemFont(ofSize: 10.0, weight: .semibold)
		self.contentView.addSubview(self.label)

		self.detailLabel = UILabel(frame: .zero)
		self.detailLabel.isAccessibilityElement = false
		self.detailLabel.backgroundColor = self.backgroundColor
		self.detailLabel.textAlignment = .left
		self.detailLabel.textColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
		self.detailLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .thin)
		self.contentView.addSubview(self.detailLabel)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews()
	{
		if layoutList
		{
			self.imageView.frame = CGRect(4.0, 4.0, (frame.height - 8.0), (frame.height - 8.0))
			self.label.frame = CGRect(self.imageView.width + 10.0, (frame.height - 20.0) / 2.0, frame.width - self.imageView.width - 20.0, 20.0)
			self.label.textAlignment = .left
			self.label.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
			self.detailLabel.frame = CGRect(self.imageView.width + 10.0, frame.height - 24.0, frame.width - self.imageView.width - 20.0, 20.0)
			self.detailLabel.isHidden = false
		}
		else
		{
			self.imageView.frame = CGRect(.zero, frame.width, frame.height - 20.0)
			self.label.frame = CGRect(0.0, self.imageView.bottom, frame.width, 20.0)
			self.label.textAlignment = .center
			self.label.font = UIFont.systemFont(ofSize: 10.0, weight: .semibold)
			self.detailLabel.isHidden = true
		}
	}

	// MARK: - Overrides
	override var isSelected: Bool
	{
		didSet
		{
			if isSelected
			{
				label.font = UIFont.systemFont(ofSize: layoutList ? 14.0 : 10.0, weight: .black)
				imageView.layer.borderWidth = 1
			}
			else
			{
				label.font = UIFont.systemFont(ofSize: layoutList ? 14.0 : 10.0, weight: .semibold)
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
				label.font = UIFont.systemFont(ofSize: layoutList ? 14.0 : 10.0, weight: .black)
				imageView.layer.borderWidth = 1
			}
			else
			{
				label.font = UIFont.systemFont(ofSize: layoutList ? 14.0 : 10.0, weight: .semibold)
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
