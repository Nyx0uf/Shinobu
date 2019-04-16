import UIKit


final class ImagedSlider: Slider
{
	// MARK: - Private properties
	private var imageView = UIImageView()
	private var imageMin: UIImage? = nil
	private var imageMid: UIImage? = nil
	private var imageMax: UIImage? = nil

	// MARK: - Properties override
	override var value: CGFloat
	{
		didSet
		{
			self.updateImage()
			self.updateFrames()
		}
	}

	override var frame: CGRect
		{
		didSet
		{
			self.imageView.frame = CGRect((frame.width - frame.height) / 2, 0, frame.height, frame.height)
		}
	}

	// MARK: - Initializers
	override init()
	{
		super.init()

		self.imageView.backgroundColor = .clear
		self.imageView.contentMode = .center
		self.addSubview(self.imageView)
	}

	override init(frame: CGRect)
	{
		super.init(frame: frame)

		self.imageView.frame = CGRect((frame.width - frame.height) / 2, 0, frame.height, frame.height)
		self.imageView.backgroundColor = .clear
		self.imageView.contentMode = .center
		self.addSubview(self.imageView)
	}

	init(minImage: UIImage, midImage: UIImage, maxImage: UIImage)
	{
		super.init()

		self.imageView.backgroundColor = .clear
		self.imageView.contentMode = .center
		self.addSubview(self.imageView)

		self.setImages(min: minImage, mid: midImage, max: maxImage)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Public
	func setImages(min: UIImage, mid: UIImage, max: UIImage)
	{
		imageMin = min.withRenderingMode(.alwaysTemplate).tinted(withColor: UIColor(rgb: 0xFFFFFF))
		imageMid = mid.withRenderingMode(.alwaysTemplate).tinted(withColor: UIColor(rgb: 0xFFFFFF))
		imageMax = max.withRenderingMode(.alwaysTemplate).tinted(withColor: UIColor(rgb: 0xFFFFFF))
		updateImage()
	}

	// MARK: - Private
	private func updateImage()
	{
		if value <= minimumValue
		{
			imageView.image = imageMin
		}
		else if value >= maximumValue
		{
			imageView.image = imageMax
		}
		else if value > minimumValue && value < maximumValue
		{
			imageView.image = imageMid
		}
	}

	// MARK: - Override
	override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool
	{
		let ret = super.continueTracking(touch, with: event)

		updateImage()

		return ret
	}
}
