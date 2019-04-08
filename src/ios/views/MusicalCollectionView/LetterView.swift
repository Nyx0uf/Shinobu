import UIKit
import CoreGraphics


final class LetterView: UIView
{
	// MARK: - Public roperties
	// Letter to draw
	var letter = ""
	{
		didSet
		{
			self.letterView.letter = letter
		}
	}
	// selected state
	var isSelected = false
	{
		didSet
		{
			self.blurEffectView.isHidden = !isSelected
			self.letterView.isSelected = isSelected
		}
	}

	// MARK: - Private roperties
	// Blur effect selection
	private var blurEffectView: UIVisualEffectView!
	// Actual letter view
	private var letterView: SimpleLetterView!

	// MARK: - Initializers
	init(frame: CGRect, letter: String, big: Bool = false)
	{
		super.init(frame: frame)

		self.layer.cornerRadius = 5
		self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.clipsToBounds = true

		// Blur background
		blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
		blurEffectView.frame = self.bounds
		self.addSubview(blurEffectView)

		letterView = SimpleLetterView(frame: self.bounds, letter: letter, big: big)
		self.addSubview(letterView)

		self.letter = letter
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }
}


fileprivate final class SimpleLetterView: UIView
{
	// MARK: - Public properties
	// Letter to draw
	var letter = ""
	{
		didSet
		{
			createStrings()
			self.setNeedsDisplay()
		}
	}
	// selected state
	var isSelected = false
	{
		didSet
		{
			self.setNeedsDisplay()
		}
	}

	// MARK: - Private properties
	// Big text
	private var isBigText = false
	// Selected attributed string
	private var letterSelected: NSAttributedString!
	// Unselected attributed string
	private var letterUnselected: NSAttributedString!

	init(frame: CGRect, letter: String, big: Bool)
	{
		super.init(frame: frame)

		self.backgroundColor = .clear

		self.isBigText = big
		self.letter = letter
		createStrings()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override func draw(_ rect: CGRect)
	{
		guard let context = UIGraphicsGetCurrentContext() else { return }
		context.translateBy(x: 0, y: rect.height)
		context.scaleBy(x: 1, y: -1)

		// Figure out how big an image we need
		let framesetter = CTFramesetterCreateWithAttributedString(isSelected ? letterSelected : letterUnselected)
		var osef = CFRange(location: 0, length: 0)
		let goodSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, osef, nil, rect.size, &osef).ceilled()
		let rect = CGRect((rect.width - goodSize.width) * 0.5, (rect.height - goodSize.height) * 0.5, goodSize.width, goodSize.height)
		let path = CGPath(rect: rect, transform: nil)
		let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)

		// Draw the text
		context.setAllowsAntialiasing(true)
		context.setAllowsFontSmoothing(true)
		context.interpolationQuality = .high
		CTFrameDraw(frame, context)
	}

	private func createStrings()
	{
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineBreakMode = .byWordWrapping
		paragraphStyle.alignment = .center

		var attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: isBigText ? 16 : 12, weight: .black), NSAttributedString.Key.foregroundColor : Colors.background, NSAttributedString.Key.paragraphStyle : paragraphStyle]
		letterSelected = NSAttributedString(string: letter, attributes: attributes as [NSAttributedString.Key : Any])
		attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: isBigText ? 16 : 12, weight: .semibold), NSAttributedString.Key.foregroundColor : Colors.mainText, NSAttributedString.Key.paragraphStyle : paragraphStyle]
		letterUnselected = NSAttributedString(string: letter, attributes: attributes as [NSAttributedString.Key : Any])
	}
}
