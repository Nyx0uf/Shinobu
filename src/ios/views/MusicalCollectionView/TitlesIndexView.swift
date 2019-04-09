import UIKit


protocol TitlesIndexViewDelegate: class
{
	func didSelectIndex(_ index: Int)
	func didScrollToIndex(_ index: Int)
}


fileprivate let LETTER_VIEW_HEIGHT = CGFloat(16)
fileprivate let OVERLAY_VIEW_HEIGHT = CGFloat(24)


final class TitlesIndexView: UIView
{
	// MARK: - Public roperties
	// Delegate
	weak var delegate: TitlesIndexViewDelegate? = nil

	// MARK: - Private roperties
	// Indexes
	private var lettersView = [LetterView]()
	// Last selected index
	private var lastSelectedIndex = 0
	// Overlay to indicate which letter is selected during panning
	private var overlayView = LetterView(frame: CGRect(.zero, OVERLAY_VIEW_HEIGHT, OVERLAY_VIEW_HEIGHT), letter: "", big: true)
	// Flag to indicate we are panning
	private var isPanning = false

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame: frame)

		// Single tap
		let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		self.addGestureRecognizer(singleTap)

		// Pan
		let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
		self.addGestureRecognizer(pan)

		overlayView.isSelected = true
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Public
	func setTitles(_ titles: [String], selectedIndex: Int)
	{
		// Clear
		lettersView.forEach {
			$0.removeFromSuperview()
		}
		lettersView.removeAll()

		var y = ((frame.height) - (CGFloat(titles.count) * LETTER_VIEW_HEIGHT)) / 2 // Center
		var index = 0
		for title in titles
		{
			let letterView = LetterView(frame: CGRect(0, y, LETTER_VIEW_HEIGHT, LETTER_VIEW_HEIGHT), letter: title)
			letterView.isSelected = (index == selectedIndex)
			letterView.tag = index
			addSubview(letterView)

			lettersView.append(letterView)

			y += LETTER_VIEW_HEIGHT
			index += 1
		}

		lastSelectedIndex = selectedIndex
	}

	func setCurrentIndex(_ index: Int)
	{
		if isPanning && lastSelectedIndex >= 0
		{
			lettersView[lastSelectedIndex].isSelected = false
			return
		}

		// Same index, no update needed
		if lastSelectedIndex == index
		{
			return
		}

		// Unselected previous
		let previousView = lettersView[lastSelectedIndex]
		previousView.isSelected = false

		// Select new
		let nextView = lettersView[index]
		nextView.isSelected = true

		lastSelectedIndex = index
	}

	// MARK: - Private
	private func letterViewAtPoint(_ point: CGPoint) -> LetterView?
	{
		for view in lettersView
		{
			if view.frame.contains(point)
			{
				return view
			}
		}
		return nil
	}

	// MARK: - Gestures
	@objc func singleTap(_ gest: UITapGestureRecognizer)
	{
		let point = gest.location(in: self)

		guard let letterView = letterViewAtPoint(point) else { return }

		addSubview(overlayView)
		overlayView.frame = CGRect(-width - 32, (letterView.y) - (overlayView.height - LETTER_VIEW_HEIGHT) / 2, OVERLAY_VIEW_HEIGHT, OVERLAY_VIEW_HEIGHT)
		overlayView.letter = letterView.letter
		overlayView.shake(removeAtEnd: true)

		delegate?.didSelectIndex(letterView.tag)
	}

	@objc func pan(_ gest: UIPanGestureRecognizer)
	{
		let point = gest.location(in: self)

		switch gest.state
		{
			case .began:
				isPanning = true
				addSubview(overlayView)
			case .changed:
				if let letterView = letterViewAtPoint(point)
				{
					overlayView.frame = CGRect(-width - 32, (letterView.y) - (overlayView.height - LETTER_VIEW_HEIGHT) / 2, OVERLAY_VIEW_HEIGHT, OVERLAY_VIEW_HEIGHT)
					if overlayView.letter != letterView.letter
					{
						overlayView.letter = letterView.letter
					}
					delegate?.didScrollToIndex(letterView.tag)
				}
			default:
				isPanning = false

				overlayView.shake(removeAtEnd: true)

				DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
					if let letterView = self.letterViewAtPoint(point)
					{
						self.setCurrentIndex(letterView.tag)
					}
				})
		}
	}
}
