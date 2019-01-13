// AutoScrollLabel.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit


private let kNYXLabelSpacing = CGFloat(20.0)

enum ScrollDirection
{
	case left
	case right
}


final class AutoScrollLabel : UIView
{
	/// Scroll direction
	public var direction = ScrollDirection.left
	{
		didSet
		{
			scrollLabelIfNeeded()
		}
	}
	/// Scroll speed (px per second)
	public var scrollSpeed = 30.0
	{
		didSet
		{
			scrollLabelIfNeeded()
		}
	}
	/// Pause (seconds)
	public var pauseInterval = 4.0
	/// Is scrolling flag
	private(set) var isScrolling = false
	/// Fade length
	public var fadeLength = CGFloat(8.0)
	{
		didSet
		{
			if fadeLength != oldValue
			{
				refreshLabels()
				applyGradientMaskForFadeLength(fadeLengthIn: fadeLength, fade: false)
			}
		}
	}
	// MARK: UILabel properties
	/// Text
	public var text: String?
	{
		get
		{
			return self.mainLabel.text
		}
		set
		{
			self.setText(text: newValue, refresh: true)
		}
	}
	/// Text color
	public var textColor: UIColor!
	{
		get
		{
			return self.mainLabel.textColor
		}
		set
		{
			self.mainLabel.textColor = newValue
			self.secondaryLabel.textColor = newValue
		}
	}
	/// Font
	public var font: UIFont!
	{
		get
		{
			return self.mainLabel.font
		}
		set
		{
			self.mainLabel.font = newValue
			self.secondaryLabel.font = newValue
			self.refreshLabels()
			self.invalidateIntrinsicContentSize()
		}
	}
	/// Text align (only when not auto-scrolling)
	public var textAlignment = NSTextAlignment.left
	/// Scrollview
	private(set) var scrollView: UIScrollView!
	/// Labels
	private var mainLabel: UILabel!
	private var secondaryLabel: UILabel!
	// MARK: UIView Override
	public override var frame: CGRect
	{
		get
		{
			return super.frame
		}
		set
		{
			super.frame = newValue
			didChangeFrame()
		}
	}
	public override var bounds: CGRect
	{
		get
		{
			return super.bounds
		}
		set
		{
			super.bounds = newValue
			didChangeFrame()
		}
	}
	public override var intrinsicContentSize: CGSize
	{
		get
		{
			return CGSize(width: 0.0, height: self.mainLabel.intrinsicContentSize.height)
		}
	}

	// MARK: - Initializers
	public override init(frame: CGRect)
	{
		super.init(frame: frame)
		self.isUserInteractionEnabled = false
		self.clipsToBounds = true

		self.scrollView = UIScrollView(frame: self.bounds)
		self.scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.scrollView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
		self.scrollView.showsVerticalScrollIndicator = false
		self.scrollView.showsHorizontalScrollIndicator = false
		self.scrollView.isScrollEnabled = false
		self.addSubview(self.scrollView)

		// Create labels
		self.mainLabel = UILabel()
		self.mainLabel.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
		self.scrollView.addSubview(self.mainLabel)

		self.secondaryLabel = UILabel()
		self.secondaryLabel.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
		self.scrollView.addSubview(self.secondaryLabel)
	}

	public required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		self.isUserInteractionEnabled = false
		self.clipsToBounds = true

		self.scrollView = UIScrollView(frame: self.bounds)
		self.scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.scrollView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
		self.scrollView.showsVerticalScrollIndicator = false
		self.scrollView.showsHorizontalScrollIndicator = false
		self.scrollView.isScrollEnabled = false
		self.addSubview(self.scrollView)

		// Create labels
		self.mainLabel = UILabel()
		self.mainLabel.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
		self.scrollView.addSubview(self.mainLabel)

		self.secondaryLabel = UILabel()
		self.secondaryLabel.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
		self.scrollView.addSubview(self.secondaryLabel)
	}

	// MARK: - Private
	private func didChangeFrame()
	{
		refreshLabels()
		applyGradientMaskForFadeLength(fadeLengthIn: fadeLength, fade: isScrolling)
	}

	// MARK: - Public
	public func setText(text: String?, refresh: Bool)
	{
		if text == self.text
		{
			return
		}

		self.mainLabel.text = text
		self.secondaryLabel.text = text

		if refresh
		{
			refreshLabels()
		}
	}

	@objc public func scrollLabelIfNeeded()
	{
		DispatchQueue.main.async {
			if String.isNullOrWhiteSpace(self.text)
			{
				return
			}

			let labelWidth = self.mainLabel.bounds.width
			if labelWidth <= self.bounds.width
			{
				return
			}

			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(AutoScrollLabel.scrollLabelIfNeeded), object: nil)

			self.scrollView.layer.removeAllAnimations()

			let scrollLeft = (self.direction == .left)
			self.scrollView.contentOffset = scrollLeft ? .zero : CGPoint(x: labelWidth + kNYXLabelSpacing, y: 0)

			// Scroll animation
			let duration = Double(labelWidth) / self.scrollSpeed
			UIView.animate(withDuration: duration, delay: self.pauseInterval, options: [.curveLinear, .allowUserInteraction], animations: {() -> Void in
				self.scrollView.contentOffset = scrollLeft ? CGPoint(x: labelWidth + kNYXLabelSpacing, y: 0) : .zero
			}) { finished in
				self.isScrolling = false

				self.applyGradientMaskForFadeLength(fadeLengthIn: self.fadeLength, fade: false)

				if finished
				{
					self.performSelector(inBackground: #selector(AutoScrollLabel.scrollLabelIfNeeded), with: nil)
				}
			}
		}
	}

	private func refreshLabels()
	{
		if mainLabel == nil
		{
			return
		}

		mainLabel.sizeToFit()
		secondaryLabel.sizeToFit()

		var frame1 = mainLabel.frame
		frame1.origin = .zero
		frame1.size.height = bounds.height
		mainLabel.frame = frame1

		var frame2 = secondaryLabel.frame
		frame2.origin = CGPoint(mainLabel.bounds.width + kNYXLabelSpacing, 0);
		frame2.size.height = bounds.height
		secondaryLabel.frame = frame2

		scrollView.contentOffset = .zero
		scrollView.layer.removeAllAnimations()

		// If label is bigger than width => scroll
		if mainLabel.bounds.width > bounds.width
		{
			secondaryLabel.isHidden = false

			var size = CGSize.zero
			size.width = mainLabel.bounds.width + bounds.width + kNYXLabelSpacing
			size.height = self.bounds.height
			scrollView.contentSize = size

			applyGradientMaskForFadeLength(fadeLengthIn: fadeLength, fade: isScrolling)

			scrollLabelIfNeeded()
		}
		else
		{
			secondaryLabel.isHidden = true

			scrollView.contentSize = bounds.size
			mainLabel.frame = bounds
			mainLabel.isHidden = false
			mainLabel.textAlignment = textAlignment

			scrollView.layer.removeAllAnimations()

			applyGradientMaskForFadeLength(fadeLengthIn: 0, fade: false)
		}
	}

	private func applyGradientMaskForFadeLength(fadeLengthIn: CGFloat, fade: Bool)
	{
		if mainLabel == nil
		{
			return
		}

		let fadeLength = (mainLabel.bounds.width <= bounds.width) ? 0 : fadeLengthIn
		if fadeLength != 0
		{
			let gradientMask = CAGradientLayer()
			gradientMask.bounds = layer.bounds
			gradientMask.position = CGPoint(x: bounds.midX, y: bounds.midY)
			gradientMask.shouldRasterize = true
			gradientMask.rasterizationScale = UIScreen.main.scale
			gradientMask.startPoint = CGPoint(x: 0, y: frame.midY)
			gradientMask.endPoint = CGPoint(x: 1, y: frame.midY)
			gradientMask.colors = [#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0).cgColor, #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor, #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor, #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0).cgColor]

			// Calcluate fade
			let fadePoint = fadeLength / bounds.width
			var leftFadePoint = fadePoint
			var rightFadePoint = 1 - fadePoint
			if !fade
			{
				switch (direction)
				{
					case .left:
						leftFadePoint = 0
					case .right:
						leftFadePoint = 0
						rightFadePoint = 1
				}
			}
			gradientMask.locations = [NSNumber(value: 0), NSNumber(value: Double(leftFadePoint)), NSNumber(value: Double(rightFadePoint)), NSNumber(value: 1)]

			CATransaction.begin()
			CATransaction.setDisableActions(true)
			layer.mask = gradientMask
			CATransaction.commit()
		}
		else
		{
			layer.mask = nil
		}
	}
}
