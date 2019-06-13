import UIKit
import ImageIO
import MobileCoreServices

extension UIImage {
	func smartCropped(toSize fitSize: CGSize, highQuality: Bool = false) -> UIImage? {
		guard let imgRef = cgImage else { return nil }

		if let cropped = imgRef.smartCropped(toSize: fitSize, highQuality: highQuality) {
			return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
		}

		return nil
	}

	// MARK: - Filtering
	func tinted(withColor color: UIColor, opacity: CGFloat = 0) -> UIImage? {
		let renderer = UIGraphicsImageRenderer(size: size)
		return renderer.image { (_) in
			let rect = CGRect(.zero, self.size)
			color.set()
			UIRectFill(rect)

			draw(in: rect, blendMode: .destinationIn, alpha: 1)

			if opacity > 0 {
				draw(in: rect, blendMode: .sourceAtop, alpha: opacity)
			}
		}
	}

	public func grayscaled() -> UIImage? {
		guard let imgRef = cgImage else { return nil }

		if let grayscaled = imgRef.grayscaled() {
			return UIImage(cgImage: grayscaled, scale: scale, orientation: imageOrientation)
		}

		return nil
	}

	// MARK: - I/O
	func save(url: URL) -> Bool {
		guard let cgImage = cgImage else {
			return false
		}

		guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeJPEG, 1, nil) else {
			return false
		}

		CGImageDestinationSetProperties(destination, [kCGImageDestinationLossyCompressionQuality as String: 0.75] as CFDictionary)

		CGImageDestinationAddImage(destination, cgImage, nil)

		return CGImageDestinationFinalize(destination)
	}

	class func loadFromFileURL(_ url: URL) -> UIImage? {
		guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
		let props = [kCGImageSourceShouldCache as String: true]
		guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, props as CFDictionary?) else { return nil }
		return UIImage(cgImage: imageRef)
	}

	class func fromString(_ string: String, font: UIFont, fontColor: UIColor, backgroundColor: UIColor, maxSize: CGSize) -> UIImage? {
		// Create an attributed string with string and font information
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineBreakMode = .byWordWrapping
		paragraphStyle.alignment = .center
		let attributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.paragraphStyle: paragraphStyle]
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
		if let imageRef = bmContext.makeImage() {
			let img = UIImage(cgImage: imageRef)
			return img
		} else {
			return nil
		}
	}
}
