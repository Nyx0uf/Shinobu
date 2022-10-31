import UIKit

extension UIView {
	// MARK: - Shortcuts
	var x: CGFloat {
		get { frame.origin.x }
		set { frame.origin.x = newValue }
	}

	var y: CGFloat {
		get { frame.origin.y }
		set { frame.origin.y = newValue }
	}

	var width: CGFloat {
		get { frame.width }
		set { frame.size.width = newValue }
	}

	var height: CGFloat {
		get { frame.height }
		set { frame.size.height = newValue }
	}

	var origin: CGPoint {
		get { frame.origin }
		set { frame.origin = newValue }
	}

	var size: CGSize {
		get { frame.size }
		set { frame.size = newValue }
	}

	// MARK: - Edges
	public var maxX: CGFloat {
		get { x + width }
		set { x = newValue - width }
	}

	public var maxY: CGFloat {
		get { y + height }
		set { y = newValue - height }
	}

	// MARK: - Animations
	public func shake(duration: Double, removeAtEnd: Bool = false) {
		let origTransform = transform
		let dur = duration / 3
		UIView.animate(withDuration: dur, delay: 0, options: .curveEaseInOut, animations: {
			let radians = 30 / 180 * CGFloat.pi
			let rotation = origTransform.rotated(by: radians)
			self.transform = rotation
		}, completion: { (_) in
			UIView.animate(withDuration: dur, delay: 0, options: .curveEaseInOut, animations: {
				let radians = -30 / 180 * CGFloat.pi
				let rotation = origTransform.rotated(by: radians)
				self.transform = rotation
			}, completion: { (_) in
				UIView.animate(withDuration: dur, delay: 0, options: .curveEaseInOut, animations: {
					self.transform = origTransform
				}, completion: { (_) in
					if removeAtEnd {
						self.removeFromSuperview()
					}
				})
			})
		})
	}

	public func enableCorners(withDivisor divisor: CGFloat = 10) {
		layer.cornerRadius = min(self.width, self.height) / divisor
		layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		clipsToBounds = true
	}

	public func circleize() {
		layer.cornerRadius = width / 2
		layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		clipsToBounds = true
	}
}
