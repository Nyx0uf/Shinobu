import UIKit
import ImageIO
import MobileCoreServices


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
		let destX = CGFloat(round((scaledWidth - targetWidth) * 0.5))
		let destY = CGFloat(round((scaledHeight - targetHeight) * 0.5))
		let sourceRect = CGRect(ceil(destX / scaleFactor), destY / scaleFactor, targetWidth / scaleFactor, targetHeight / scaleFactor).integral

		// Create scale-cropped image
		let renderer = UIGraphicsImageRenderer(size: destRect.size)
		return renderer.image() { (rendererContext) in
			let sourceImg = cgImage?.cropping(to: sourceRect) // cropping happens here
			let image = UIImage(cgImage: sourceImg!, scale: 0, orientation: imageOrientation)
			image.draw(in: destRect) // the actual scaling happens here, and orientation is taken care of automatically
		}
	}

	func scaled(toSize fitSize: CGSize) -> UIImage?
	{
		guard let cgImage = cgImage else { return nil }

		let width = ceil(fitSize.width * scale)
		let height = ceil(fitSize.height * scale)

		let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: cgImage.bytesPerRow, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)
		context!.interpolationQuality = .high
		context?.draw(cgImage, in: CGRect(.zero, width, height))

		if let scaledImageRef = context?.makeImage()
		{
			return UIImage(cgImage: scaledImageRef)
		}

		return nil
	}

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
		let rect = CGRect((trueMaxSize.width - goodSize.width) * 0.5, (trueMaxSize.height - goodSize.height) * 0.5, goodSize.width, goodSize.height)
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
