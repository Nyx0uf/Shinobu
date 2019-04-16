import UIKit


fileprivate let space = CGFloat(4)


final class ImagedLabel: UIView
{
	var label = UILabel()
	var imageView = UIImageView()
	var align = NSTextAlignment.left

	// MARK: - Properties override
	override var frame: CGRect
	{
		didSet
		{
			if align == .left
			{
				self.imageView.frame = CGRect(.zero, frame.height, frame.height)
				self.label.frame = CGRect(self.imageView.maxX + space, 0, frame.width - self.imageView.maxX - space, frame.height)
			}
			else
			{
				self.imageView.frame = CGRect(frame.width - frame.height, 0, frame.height, frame.height)
				self.label.frame = CGRect(.zero, frame.width - frame.height - space, frame.height)
				self.label.textAlignment = .right
			}
		}
	}

	// MARK: - Initializers
	init()
	{
		super.init(frame: .zero)

		self.addSubview(self.imageView)
		self.addSubview(self.label)
	}

	override init(frame: CGRect)
	{
		super.init(frame: frame)

		self.imageView.frame = CGRect(.zero, frame.height, frame.height)
		self.addSubview(self.imageView)

		self.label.frame = CGRect(self.imageView.maxX + space, 0, frame.width - self.imageView.maxX - space, frame.height)
		self.addSubview(self.label)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }
}
