import UIKit

protocol TitlesIndexViewDelegate: class {
	func didSelectIndex(_ index: Int)
	func didScrollToIndex(_ index: Int)
}

private let LETTER_VIEW_HEIGHT = CGFloat(16)
private let OVERLAY_VIEW_HEIGHT = CGFloat(24)

final class TitlesIndexView: UIView {
	// MARK: - Public roperties
	// Delegate
	weak var delegate: TitlesIndexViewDelegate?

	// MARK: - Private roperties
	// Indexes
	private var lettersView = [LetterView]()
	// Last selected index
	private var lastSelectedIndex = 0
	// Overlay to indicate which letter is selected during panning
	private var bigLetterView = LetterView(frame: CGRect(.zero, OVERLAY_VIEW_HEIGHT, OVERLAY_VIEW_HEIGHT), letter: "", big: true)
	// Flag to indicate we are panning
	private var isPanning = false
	// Overlay over the selected letter
	private var overlayView = UIVisualEffectView()

	// MARK: - Initializers
	override init(frame: CGRect) {
		super.init(frame: frame)

		// Single tap
		let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		self.addGestureRecognizer(singleTap)

		// Pan
		let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
		self.addGestureRecognizer(pan)

		self.bigLetterView.isSelected = true

		initializeTheming()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Public
	func setTitles(_ titles: [String], selectedIndex: Int) {
		// Clear
		lettersView.forEach {
			$0.removeFromSuperview()
		}
		lettersView.removeAll()
		overlayView.removeFromSuperview()

		// Create and add letters
		var y = ((frame.height) - (CGFloat(titles.count) * LETTER_VIEW_HEIGHT)) / 2 // Center
		var index = 0
		for title in titles {
			let letterView = LetterView(frame: CGRect(0, y, LETTER_VIEW_HEIGHT, LETTER_VIEW_HEIGHT), letter: title)
			letterView.isSelected = (index == selectedIndex)
			letterView.tag = index
			addSubview(letterView)

			if index == selectedIndex {
				overlayView.frame = letterView.frame
			}

			lettersView.append(letterView)

			y += LETTER_VIEW_HEIGHT
			index += 1
		}

		// Add overlay view
		insertSubview(overlayView, at: 0)
		overlayView.enableCorners(withDivisor: 4)

		// Set index
		lastSelectedIndex = selectedIndex
	}

	func setCurrentIndex(_ newIndex: Int) {
		// If a pan is occuring, ignore
		if isPanning {
			// Clear the selection during the pan
			if lastSelectedIndex >= 0 && lettersView[lastSelectedIndex].isSelected {
				lettersView[lastSelectedIndex].isSelected = false
			}
			// Fade out the overlay
			if Int(overlayView.alpha) == 1 {
				UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
					self.overlayView.alpha = 0
				}, completion: nil)
			}
			return
		}

		// Same index, no update needed
		if lastSelectedIndex == newIndex {
			return
		}

		let nextView = lettersView[newIndex]
		if Int(overlayView.alpha) == 0 {
			overlayView.frame = nextView.frame // Necessary when paning
			overlayView.alpha = 1
		}
		UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear, animations: {
			// Unselected previous
			self.lettersView[self.lastSelectedIndex].isSelected = false
			// Select new
			nextView.isSelected = true
			// Animate frame
			self.overlayView.frame = nextView.frame
		}, completion: nil)

		// Save the index
		lastSelectedIndex = newIndex
	}

	// MARK: - Private
	private func letterViewAtPoint(_ point: CGPoint) -> LetterView? {
		for view in lettersView {
			if view.frame.contains(point) {
				return view
			}
		}
		return nil
	}

	// MARK: - Gestures
	@objc func singleTap(_ gest: UITapGestureRecognizer) {
		// Get letter view if any
		let point = gest.location(in: self)
		guard let letterView = letterViewAtPoint(point) else { return }

		// Indicate which view was selected
		addSubview(bigLetterView)
		bigLetterView.frame = CGRect(-width - 32, (letterView.y) - (bigLetterView.height - LETTER_VIEW_HEIGHT) / 2, OVERLAY_VIEW_HEIGHT, OVERLAY_VIEW_HEIGHT)
		bigLetterView.letter = letterView.letter
		bigLetterView.shake(duration: 0.36, removeAtEnd: true)

		// Avoid frame animation
		overlayView.frame = letterView.frame

		// Will call setCurrentIndex
		delegate?.didSelectIndex(letterView.tag)
	}

	@objc func pan(_ gest: UIPanGestureRecognizer) {
		let point = gest.location(in: self)

		switch gest.state {
		case .began:
			isPanning = true
			addSubview(bigLetterView)
		case .changed:
			if let letterView = letterViewAtPoint(point) {
				if bigLetterView.letter != letterView.letter {
					bigLetterView.frame = CGRect(-width - 32, (letterView.y) - (bigLetterView.height - LETTER_VIEW_HEIGHT) / 2, OVERLAY_VIEW_HEIGHT, OVERLAY_VIEW_HEIGHT)
					bigLetterView.letter = letterView.letter
					delegate?.didScrollToIndex(letterView.tag)
				}
			}
		default:
			isPanning = false
			bigLetterView.shake(duration: 0.36, removeAtEnd: true)

			DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
				if let letterView = self.letterViewAtPoint(point) {
					self.setCurrentIndex(letterView.tag)
				}
			})
		}
	}
}

extension TitlesIndexView: Themed {
	func applyTheme(_ theme: Theme) {
		overlayView.effect = theme.blurEffectAlt
	}
}
