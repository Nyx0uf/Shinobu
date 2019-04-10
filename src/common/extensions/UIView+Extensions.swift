import UIKit


extension UIView
{
	// MARK: - Shortcuts
	var x: CGFloat
	{
		get { return frame.origin.x }
		set { frame.origin.x = newValue }
	}

	var y: CGFloat
	{
		get { return frame.origin.y }
		set { frame.origin.y = newValue }
	}

	var width: CGFloat
	{
		get { return frame.width }
		set { frame.size.width = newValue }
	}

	var height: CGFloat
	{
		get { return frame.height }
		set { frame.size.height = newValue }
	}

	var origin: CGPoint
	{
		get { return frame.origin }
		set { frame.origin = newValue }
	}

	var size: CGSize
	{
		get { return frame.size }
		set { frame.size = newValue }
	}

	// MARK: - Edges
	public var maxX: CGFloat
	{
		get { return x + width }
		set { x = newValue - width }
	}

	public var maxY: CGFloat
	{
		get { return y + height }
		set { y = newValue - height }
	}

	// MARK: - Animations
	public func shake(removeAtEnd: Bool = false)
	{
		let origTransform = transform
		UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseOut, animations: {
			let radians = 30 / 180 * CGFloat.pi
			let rotation = origTransform.rotated(by: radians)
			self.transform = rotation
		}, completion:{ (finished) in
			UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseOut, animations: {
				let radians = -30 / 180 * CGFloat.pi
				let rotation = origTransform.rotated(by: radians)
				self.transform = rotation
			}, completion:{ (finished) in
				UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseOut, animations: {
					self.transform = origTransform
				}, completion:{ (finished) in
					if removeAtEnd
					{
						self.removeFromSuperview()
					}
				})
			})
		})
	}
}
