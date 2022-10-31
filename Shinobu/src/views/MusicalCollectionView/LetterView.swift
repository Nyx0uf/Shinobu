import UIKit

final class LetterView: UIView {
	// MARK: - Public properties
	var letter = "" {
		didSet {
			self.letterLayer.string = letter
		}
	}
	// selected state
	var isSelected = false {
		didSet {
			self.letterLayer.font = UIFont.systemFont(ofSize: self.big ? 16 : 12, weight: self.isSelected ? .black : .semibold)
			self.letterLayer.foregroundColor = self.isSelected ? UIColor.black.cgColor : UIColor.secondaryLabel.cgColor
			if self.big {
				self.blurEffectView.isHidden = !self.isSelected
			}
		}
	}

	// MARK: - Private properties
	// Blur effect selection
	private var blurEffectView: UIVisualEffectView!
	// Actual letter view
	private var letterLayer: CenteredTextLayer!
	// Big text
	private var big = false

	// MARK: - Initializers
	init(frame: CGRect, letter: String, big: Bool = false) {
		super.init(frame: frame)

		// Blur background
		self.big = big
		if big {
			self.enableCorners(withDivisor: 4)

			self.blurEffectView = UIVisualEffectView()
			self.blurEffectView.frame = self.bounds
			self.addSubview(self.blurEffectView)
		}

		self.letterLayer = CenteredTextLayer()
		self.letterLayer.frame = self.bounds
		self.letterLayer.backgroundColor = UIColor.clear.cgColor
		self.letterLayer.alignmentMode = .center
		self.letterLayer.font = UIFont.systemFont(ofSize: big ? 16 : 12, weight: .semibold)
		self.letterLayer.string = letter
		self.letterLayer.allowsFontSubpixelQuantization = true
		self.letterLayer.contentsScale = UIScreen.main.scale
		self.layer.addSublayer(self.letterLayer)

		self.letter = letter
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }
}

fileprivate final class CenteredTextLayer: CATextLayer {
	public override init() {
		super.init()
	}

	override init(layer: Any) {
		super.init(layer: layer)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override var font: CFTypeRef? {
		didSet {
			self.fontSize = (self.font as? UIFont)?.pointSize ?? 12
		}
	}

	public override func draw(in ctx: CGContext) {
		guard let text = string as? NSString, let font = font as? UIFont else {
			super.draw(in: ctx)
			return
		}

		let attributes = [NSAttributedString.Key.font: font]
		let textSize = text.size(withAttributes: attributes)
		let yDiff = (bounds.height - textSize.height) / 2

		ctx.saveGState()
		ctx.translateBy(x: 0, y: yDiff)
		super.draw(in: ctx)
		ctx.restoreGState()
	}
}
