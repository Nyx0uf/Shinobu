import CoreGraphics


extension CGSize
{
	// MARK: - Initializers
	public init(_ width: CGFloat, _ height: CGFloat)
	{
		self.init()
		self.width = width
		self.height = height
	}

	func ceilled() -> CGSize
	{
		return CGSize(CoreGraphics.ceil(width), CoreGraphics.ceil(height))
	}
}

func * (lhs: CGSize, rhs: CGFloat) -> CGSize
{
	return CGSize(lhs.width * rhs, lhs.height * rhs)
}
