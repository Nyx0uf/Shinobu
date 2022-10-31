import CoreGraphics

extension CGSize {
	// MARK: - Initializers
	public init(_ width: CGFloat, _ height: CGFloat) {
		self.init(width: width, height: height)
	}

	// MARK: - Round / Ceil
	func ceilled() -> CGSize {
		CGSize(ceil(width), ceil(height))
	}
}

// MARK: - Operators
func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
	CGSize(lhs.width * rhs, lhs.height * rhs)
}
