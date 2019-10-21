import CoreGraphics

extension CGRect {
	// MARK: - Initializers
	public init(_ origin: CGPoint, _ size: CGSize) {
		self.init(origin: origin, size: size)
	}

	public init(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
		self.init(x: x, y: y, width: width, height: height)
	}

	public init(_ x: CGFloat, _ y: CGFloat, _ size: CGSize) {
		self.init(origin: CGPoint(x, y), size: size)
	}

	public init(_ origin: CGPoint, _ width: CGFloat, _ height: CGFloat) {
		self.init(origin: origin, size: CGSize(width, height))
	}

	// MARK: - Shortcuts
	public var x: CGFloat {
		get { return origin.x }
		set { origin.x = newValue }
	}

	public var y: CGFloat {
		get { return origin.y }
		set { origin.y = newValue }
	}

	// MARK: - Round / Ceil
	func ceilled() -> CGRect {
		return CGRect(origin.ceilled(), size.ceilled())
	}
}
