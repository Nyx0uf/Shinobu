import UIKit
import Accelerate

// Grayscale stuff
private let gray_redCoeff = Float(0.2126)
private let gray_greenCoeff = Float(0.7152)
private let gray_blueCoeff = Float(0.0722)
private let gray_divisor = Int32(0x1000)
private let gray_fDivisor = Float(gray_divisor)
private var gray_coefficientsMatrix = [
	Int16(gray_redCoeff * gray_fDivisor),
	Int16(gray_greenCoeff * gray_fDivisor),
	Int16(gray_blueCoeff * gray_fDivisor)
]
private let gray_preBias: [Int16] = [0, 0, 0, 0]
private let gray_postBias = Int32(0)

extension CGImage {
	func vImageFormat() -> vImage_CGImageFormat? {
		guard let colorSpace = self.colorSpace else {
			return nil
		}

		return vImage_CGImageFormat(
			bitsPerComponent: UInt32(self.bitsPerComponent),
			bitsPerPixel: UInt32(self.bitsPerPixel),
			colorSpace: Unmanaged.passRetained(colorSpace),
			bitmapInfo: self.bitmapInfo,
			version: 0,
			decode: nil,
			renderingIntent: self.renderingIntent)
	}

	func smartCropped(toSize fitSize: CGSize, highQuality: Bool = false) -> CGImage? {
		let sourceWidth = CGFloat(width)
		let sourceHeight = CGFloat(height)
		let targetWidth = fitSize.width
		let targetHeight = fitSize.height

		// Calculate aspect ratios
		let sourceRatio = sourceWidth / sourceHeight
		let targetRatio = targetWidth / targetHeight

		// Determine what side of the source image to use for proportional scaling
		let scaleWidth = (sourceRatio <= targetRatio)

		// Proportionally scale source image
		var scalingFactor: CGFloat, scaledWidth: CGFloat, scaledHeight: CGFloat
		if scaleWidth {
			scalingFactor = 1 / sourceRatio
			scaledWidth = targetWidth
			scaledHeight = CGFloat(round(targetWidth * scalingFactor))
		} else {
			scalingFactor = sourceRatio
			scaledWidth = CGFloat(round(targetHeight * scalingFactor))
			scaledHeight = targetHeight
		}
		let scaleFactor = scaledHeight / sourceHeight

		// Crop center
		let destX = CGFloat(round((scaledWidth - targetWidth) / 2))
		let destY = CGFloat(round((scaledHeight - targetHeight) / 2))
		let originalRect = CGRect(.zero, sourceWidth, sourceHeight)
		let sourceRect = CGRect(ceil(destX / scaleFactor), destY / scaleFactor, targetWidth / scaleFactor, targetHeight / scaleFactor).integral

		guard let cgImage = originalRect != sourceRect ? self.cropping(to: sourceRect) : self else { return nil }

		// Source & destination vImage buffers
		var sourceBuffer = vImage_Buffer()
		var destinationBuffer = vImage_Buffer()

		defer {
			free(destinationBuffer.data)
			free(sourceBuffer.data)
		}

		guard var format = cgImage.vImageFormat() else { return nil }
		guard vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, vImage_Flags(kvImageNoFlags)) == kvImageNoError else { return nil }

		guard vImageBuffer_Init(&destinationBuffer, UInt(fitSize.height * UIScreen.main.scale), UInt(fitSize.width * UIScreen.main.scale), format.bitsPerPixel, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
			return nil
		}

		if cgImage.alphaInfo == .premultipliedFirst || cgImage.alphaInfo == .premultipliedLast { // Premultiplied case
			guard vImageUnpremultiplyData_ARGB8888(&sourceBuffer, &sourceBuffer, vImage_Flags(kvImageNoFlags))  == kvImageNoError else { return nil }
			guard vImageScale_ARGB8888(&sourceBuffer, &destinationBuffer, nil, vImage_Flags(highQuality ? kvImageHighQualityResampling : kvImageNoFlags)) == kvImageNoError else { return nil }
			guard vImagePremultiplyData_ARGB8888(&destinationBuffer, &destinationBuffer, vImage_Flags(kvImageNoFlags))  == kvImageNoError else { return nil }
		} else {
			guard vImageScale_ARGB8888(&sourceBuffer, &destinationBuffer, nil, vImage_Flags(highQuality ? kvImageHighQualityResampling : kvImageNoFlags)) == kvImageNoError else { return nil }
		}

		guard let result = vImageCreateCGImageFromBuffer(&destinationBuffer, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil) else { return nil }

		return result.takeRetainedValue()
	}

	public func grayscaled() -> CGImage? {
		// Source & destination vImage buffers
		var sourceBuffer = vImage_Buffer()
		var destinationBuffer = vImage_Buffer()

		defer {
			free(destinationBuffer.data)
			free(sourceBuffer.data)
		}

		// Create vImage src buffer
		guard var format = self.vImageFormat() else { return nil }
		guard vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, self, vImage_Flags(kvImageNoFlags)) == kvImageNoError else { return nil }

		// Create vImage dst buffer
		guard vImageBuffer_Init(&destinationBuffer, sourceBuffer.height, sourceBuffer.width, 8, vImage_Flags(kvImageNoFlags)) == kvImageNoError else { return nil }

		guard vImageMatrixMultiply_ARGB8888ToPlanar8(&sourceBuffer, &destinationBuffer, &gray_coefficientsMatrix, gray_divisor, gray_preBias, gray_postBias, vImage_Flags(kvImageNoFlags)) == kvImageNoError else { return nil }

		// Create a 1-channel, 8-bit grayscale format that's used to generate a displayable image
		var monoFormat = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8, colorSpace: Unmanaged.passRetained(CGColorSpaceCreateDeviceGray()), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue), version: 0, decode: nil, renderingIntent: .defaultIntent)

		// Create a Core Graphics image from the grayscale destination buffer
		guard let result = vImageCreateCGImageFromBuffer(&destinationBuffer, &monoFormat, nil, nil, vImage_Flags(kvImageNoFlags), nil) else { return nil }

		return result.takeRetainedValue()
	}
}
