import UIKit
import CoreGraphics


// MARK: - Public constants
public let kNYXNumberOfComponentsPerARBGPixel = 4
public let kNYXNumberOfComponentsPerRGBAPixel = 4


extension CGContext
{
	// MARK: - ARGB bitmap context
	class func ARGBBitmapContext(width: Int, height: Int, withAlpha: Bool, wideGamut: Bool) -> CGContext?
	{
		let alphaInfo = withAlpha ? CGImageAlphaInfo.premultipliedFirst : CGImageAlphaInfo.noneSkipFirst
		let bmContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * kNYXNumberOfComponentsPerARBGPixel, space: wideGamut ? CGColorSpace.NYXAppropriateColorSpace() : CGColorSpaceCreateDeviceRGB(), bitmapInfo: alphaInfo.rawValue)
		return bmContext
	}

	// MARK: - RGBA bitmap context
	class func RGBABitmapContext(width: Int, height: Int, withAlpha: Bool, wideGamut: Bool) -> CGContext?
	{
		let alphaInfo = withAlpha ? CGImageAlphaInfo.premultipliedLast : CGImageAlphaInfo.noneSkipLast
		let bmContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * kNYXNumberOfComponentsPerRGBAPixel, space: wideGamut ? CGColorSpace.NYXAppropriateColorSpace() : CGColorSpaceCreateDeviceRGB(), bitmapInfo: alphaInfo.rawValue)
		return bmContext
	}
}

extension CGColorSpace
{
	class func NYXAppropriateColorSpace() -> CGColorSpace
	{
		if UIScreen.main.traitCollection.displayGamut == .P3
		{
			if let p3ColorSpace = CGColorSpace(name: CGColorSpace.displayP3)
			{
				return p3ColorSpace
			}
		}
		return CGColorSpaceCreateDeviceRGB()
	}
}

struct RGBAPixel
{
	var r: UInt8
	var g: UInt8
	var b: UInt8
	var a: UInt8

	init(r: UInt8, g: UInt8, b: UInt8, a: UInt8)
	{
		self.r = r
		self.g = g
		self.b = b
		self.a = a
	}
}
