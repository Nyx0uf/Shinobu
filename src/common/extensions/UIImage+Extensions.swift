import UIKit
import ImageIO
import MobileCoreServices
import Accelerate

// Grayscale stuff
fileprivate let gray_redCoeff = Float(0.2126)
fileprivate let gray_greenCoeff = Float(0.7152)
fileprivate let gray_blueCoeff = Float(0.0722)
fileprivate let gray_divisor = Int32(0x1000)
fileprivate let gray_fDivisor = Float(gray_divisor)
fileprivate var gray_coefficientsMatrix = [
	Int16(gray_redCoeff * gray_fDivisor),
	Int16(gray_greenCoeff * gray_fDivisor),
	Int16(gray_blueCoeff * gray_fDivisor)
]
fileprivate let gray_preBias: [Int16] = [0, 0, 0, 0]
fileprivate let gray_postBias = Int32(0)


extension UIImage
{
	func smartCropped(toSize fitSize: CGSize) -> UIImage?
	{
		let sourceWidth = size.width * scale
		let sourceHeight = size.height * scale
		let targetWidth = fitSize.width
		let targetHeight = fitSize.height

		// Calculate aspect ratios
		let sourceRatio = sourceWidth / sourceHeight
		let targetRatio = targetWidth / targetHeight

		// Determine what side of the source image to use for proportional scaling
		let scaleWidth = (sourceRatio <= targetRatio)

		// Proportionally scale source image
		var scalingFactor: CGFloat, scaledWidth: CGFloat, scaledHeight: CGFloat
		if scaleWidth
		{
			scalingFactor = 1 / sourceRatio
			scaledWidth = targetWidth
			scaledHeight = CGFloat(round(targetWidth * scalingFactor))
		}
		else
		{
			scalingFactor = sourceRatio
			scaledWidth = CGFloat(round(targetHeight * scalingFactor))
			scaledHeight = targetHeight
		}
		let scaleFactor = scaledHeight / sourceHeight

		let destRect = CGRect(.zero, fitSize).integral
		// Crop center
		let destX = CGFloat(round((scaledWidth - targetWidth) / 2))
		let destY = CGFloat(round((scaledHeight - targetHeight) / 2))
		let sourceRect = CGRect(ceil(destX / scaleFactor), destY / scaleFactor, targetWidth / scaleFactor, targetHeight / scaleFactor).integral

		guard let cgImage = self.cgImage?.cropping(to: sourceRect) else { return nil }

		guard let colorSpace = cgImage.colorSpace else { return nil }

		// Source & destination vImage buffers
		var sourceBuffer = vImage_Buffer()
		var destinationBuffer = vImage_Buffer()

		defer
		{
			free(destinationBuffer.data)
			free(sourceBuffer.data)
		}

		var format = vImage_CGImageFormat(bitsPerComponent: UInt32(cgImage.bitsPerComponent), bitsPerPixel: UInt32(cgImage.bitsPerPixel), colorSpace: Unmanaged.passRetained(colorSpace), bitmapInfo: cgImage.bitmapInfo, version: 0, decode: nil, renderingIntent: cgImage.renderingIntent)
		guard vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, vImage_Flags(kvImageNoFlags)) == kvImageNoError else { return nil }

		guard vImageBuffer_Init(&destinationBuffer, UInt(destRect.height * UIScreen.main.scale), UInt(destRect.width * UIScreen.main.scale), format.bitsPerPixel, vImage_Flags(kvImageNoFlags)) == kvImageNoError else
		{
			return nil
		}

		// Scale
		guard vImageScale_ARGB8888(&sourceBuffer, &destinationBuffer, nil, vImage_Flags(kvImageNoFlags)) == kvImageNoError else
		{
			return nil
		}

		guard let result = vImageCreateCGImageFromBuffer(&destinationBuffer, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil) else { return nil}

		return UIImage(cgImage: result.takeRetainedValue(), scale: scale, orientation: imageOrientation)
	}

	// MARK: - Filtering
	func tinted(withColor color: UIColor, opacity: CGFloat = 0) -> UIImage?
	{
		let renderer = UIGraphicsImageRenderer(size: size)
		return renderer.image() { (rendererContext) in
			let rect = CGRect(.zero, self.size)
			color.set()
			UIRectFill(rect)

			draw(in: rect, blendMode: .destinationIn, alpha: 1)

			if opacity > 0
			{
				draw(in: rect, blendMode: .sourceAtop, alpha: opacity)
			}
		}
	}

	public func grayscaled() -> UIImage?
	{
		guard let cgImage = self.cgImage else { return nil }

		guard let colorSpace = cgImage.colorSpace else { return nil }

		// Source & destination vImage buffers
		var sourceBuffer = vImage_Buffer()
		var destinationBuffer = vImage_Buffer()

		defer
		{
			free(destinationBuffer.data)
			free(sourceBuffer.data)
		}

		// Create vImage src buffer
		var format = vImage_CGImageFormat(bitsPerComponent: UInt32(cgImage.bitsPerComponent), bitsPerPixel: UInt32(cgImage.bitsPerPixel), colorSpace: Unmanaged.passRetained(colorSpace), bitmapInfo: cgImage.bitmapInfo, version: 0, decode: nil, renderingIntent: cgImage.renderingIntent)
		guard vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, vImage_Flags(kvImageNoFlags)) == kvImageNoError else { return nil }

		// Create vImage dst buffer
		guard vImageBuffer_Init(&destinationBuffer, sourceBuffer.height, sourceBuffer.width, 8, vImage_Flags(kvImageNoFlags)) == kvImageNoError else { return nil }

		guard vImageMatrixMultiply_ARGB8888ToPlanar8(&sourceBuffer, &destinationBuffer, &gray_coefficientsMatrix, gray_divisor, gray_preBias, gray_postBias, vImage_Flags(kvImageNoFlags)) == kvImageNoError else { return nil }

		// Create a 1-channel, 8-bit grayscale format that's used to generate a displayable image
		var monoFormat = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8, colorSpace: Unmanaged.passRetained(CGColorSpaceCreateDeviceGray()), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue), version: 0, decode: nil, renderingIntent: .defaultIntent)

		// Create a Core Graphics image from the grayscale destination buffer
		guard let result = vImageCreateCGImageFromBuffer(&destinationBuffer, &monoFormat, nil, nil, vImage_Flags(kvImageNoFlags), nil) else { return nil }

		return UIImage(cgImage: result.takeRetainedValue(), scale: self.scale, orientation: self.imageOrientation)
	}

	// MARK: - I/O
	func save(url: URL) -> Bool
	{
		guard let cgImage = cgImage else
		{
			return false
		}

		guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeJPEG, 1, nil) else
		{
			return false
		}

		CGImageDestinationSetProperties(destination, [kCGImageDestinationLossyCompressionQuality as String : 0.75] as CFDictionary)

		CGImageDestinationAddImage(destination, cgImage, nil)

		return CGImageDestinationFinalize(destination)
	}

	class func loadFromFileURL(_ url: URL) -> UIImage?
	{
		guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
		let props = [kCGImageSourceShouldCache as String : true]
		guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, props as CFDictionary?) else { return nil }
		return UIImage(cgImage: imageRef)
	}

	class func fromString(_ string: String, font: UIFont, fontColor: UIColor, backgroundColor: UIColor, maxSize: CGSize) -> UIImage?
	{
		// Create an attributed string with string and font information
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineBreakMode = .byWordWrapping
		paragraphStyle.alignment = .center
		let attributes = [NSAttributedString.Key.font : font, NSAttributedString.Key.foregroundColor : fontColor, NSAttributedString.Key.paragraphStyle : paragraphStyle]
		let attrString = NSAttributedString(string: string, attributes: attributes)
		let scale = UIScreen.main.scale
		let trueMaxSize = maxSize * scale

		// Figure out how big an image we need
		let framesetter = CTFramesetterCreateWithAttributedString(attrString)
		var osef = CFRange(location: 0, length: 0)
		let goodSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, osef, nil, trueMaxSize, &osef).ceilled()
		let rect = CGRect((trueMaxSize.width - goodSize.width) / 2, (trueMaxSize.height - goodSize.height) / 2, goodSize.width, goodSize.height)
		let path = CGPath(rect: rect, transform: nil)
		let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)

		// Create the context and fill it
		guard let bmContext = CGContext.ARGBBitmapContext(width: Int(trueMaxSize.width), height: Int(trueMaxSize.height), withAlpha: true, wideGamut: true) else { return nil }
		bmContext.setFillColor(backgroundColor.cgColor)
		bmContext.fill(CGRect(.zero, trueMaxSize))

		// Draw the text
		bmContext.setAllowsAntialiasing(true)
		bmContext.setAllowsFontSmoothing(true)
		bmContext.interpolationQuality = .high
		CTFrameDraw(frame, bmContext)

		// Save
		if let imageRef = bmContext.makeImage()
		{
			let img = UIImage(cgImage: imageRef)
			return img
		}
		else
		{
			return nil
		}
	}
}
