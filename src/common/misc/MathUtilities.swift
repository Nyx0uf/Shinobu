import CoreGraphics


// MARK: - Clamp
public func clamp<T: Comparable>(_ value: T, lower: T, upper: T) -> T
{
	return max(min(value, upper), lower)
}

// MARK: - Degrees/Radians
public func degreesToRadians(_ value: Float) -> Float
{
	return value * Float.pi / 180
}

public func radiansToDegrees(_ value: Float) -> Float
{
	return value * 180 / Float.pi
}

public func degreesToRadians(_ value: Double) -> Double
{
	return value * Double.pi / 180
}

public func radiansToDegrees(_ value: Double) -> Double
{
	return value * 180 / Double.pi
}

public func degreesToRadians(_ value: CGFloat) -> CGFloat
{
	return value * CGFloat.pi / 180
}

public func radiansToDegrees(_ value: CGFloat) -> CGFloat
{
	return value * 180 / CGFloat.pi
}
