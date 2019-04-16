// Converted and adapted to Swift from : https://github.com/fleitz/ColorArt


import UIKit


private let THRESHOLD = UInt(2)
private let DEFAULT_PRECISION = Int(8) // 8 -> 256


final class KawaiiColors
{
	enum SamplingEdge
	{
		case left
		case right
	}

	// MARK: - Public properties
	// Image to analyze
	let image: UIImage
	// Edge color precision
	private(set) var precision = DEFAULT_PRECISION
	// Sampling edge for background color
	private(set) var samplingEdge = SamplingEdge.right
	// Most dominant color in the whole image
	private(set) var dominantColor: UIColor! = nil
	// Most dominant edge color
	private(set) var edgeColor: UIColor! = nil
	// First contrasting color
	private(set) var primaryColor: UIColor! = nil
	// Second contrasting color
	private(set) var secondaryColor: UIColor! = nil
	// Third contrasting color
	private(set) var thirdColor: UIColor! = nil

	// MARK: - Initializers
	init(image: UIImage)
	{
		self.image = image
	}

	convenience init(image: UIImage, precision: Int)
	{
		self.init(image: image)
		self.precision = clamp(precision, lower:8, upper:256)
	}

	convenience init(image: UIImage, samplingEdge: SamplingEdge)
	{
		self.init(image: image)
		self.samplingEdge = samplingEdge
	}

	convenience init(image: UIImage, precision: Int, samplingEdge: SamplingEdge)
	{
		self.init(image: image, precision: precision)
		self.samplingEdge = samplingEdge
	}

	// MARK: - Public
	func analyze()
	{
		// Find edge color
		var imageColors = [CountedObject<UIColor>]()
		edgeColor = findEdgeColor(&imageColors)
		if edgeColor == nil
		{
			edgeColor = UIColor(rgb: 0xFFFFFF)
		}

		// Find other colors
		findContrastingColors(imageColors)

		// Sanitize
		let darkBackground = edgeColor.isDark()
		if primaryColor == nil
		{
			primaryColor = darkBackground ? UIColor(rgb: 0xFFFFFF) : UIColor(rgb: 0x000000)
		}

		if secondaryColor == nil
		{
			secondaryColor = darkBackground ? UIColor(rgb: 0xFFFFFF) : UIColor(rgb: 0x000000)
		}

		if thirdColor == nil
		{
			thirdColor = darkBackground ? UIColor(rgb: 0xFFFFFF) : UIColor(rgb: 0x000000)
		}
	}

	// MARK: - Private
	private func findEdgeColor(_ colors: inout [CountedObject<UIColor>]) -> UIColor?
	{
		// Get raw image pixels
		guard let cgImage = image.cgImage else
		{
			return nil
		}
		let width = cgImage.width
		let height = cgImage.height

		guard let bmContext = CGContext.RGBABitmapContext(width: width, height: height, withAlpha: false, wideGamut: false) else
		{
			return nil
		}
		bmContext.draw(cgImage, in: CGRect(0, 0, CGFloat(width), CGFloat(height)))
		guard let data = bmContext.data else
		{
			return nil
		}
		let pixels = data.assumingMemoryBound(to: RGBAPixel.self)

		let pp = precision
		let scale = UInt8(256 / pp)
		var rawImageColors: [[[UInt]]] = [[[UInt]]](repeating: [[UInt]](repeating: [UInt](repeating: 0, count: pp), count: pp), count: pp)
		var rawEdgeColors: [[[UInt]]] = [[[UInt]]](repeating: [[UInt]](repeating: [UInt](repeating: 0, count: pp), count: pp), count: pp)

		let edge = samplingEdge == .left ? 0 : width - 1
		for y in 0 ..< height
		{
			for x in 0 ..< width
			{
				let index = x + y * width
				let pixel = pixels[index]
				let r = pixel.r / scale
				let g = pixel.g / scale
				let b = pixel.b / scale
				rawImageColors[Int(r)][Int(g)][Int(b)] += 1
				if x == edge
				{
					rawEdgeColors[Int(r)][Int(g)][Int(b)] += 1
				}
			}
		}

		var edgeColors = [CountedObject<UIColor>]()

		let ppf = CGFloat(pp)
		for b in 0 ..< pp
		{
			for g in 0 ..< pp
			{
				for r in 0 ..< pp
				{
					var count = rawImageColors[r][g][b]
					if count > THRESHOLD
					{
						let color = UIColor(red: CGFloat(r) / ppf, green: CGFloat(g) / ppf, blue: CGFloat(b) / ppf, alpha: 1)
						colors.append(CountedObject(object: color, count: count))
					}

					count = rawEdgeColors[r][g][b]
					if count > THRESHOLD
					{
						let color = UIColor(red: CGFloat(r) / ppf, green: CGFloat(g) / ppf, blue: CGFloat(b) / ppf, alpha: 1)
						edgeColors.append(CountedObject(object: color, count: count))
					}
				}
			}
		}
		colors.sort { (c1: CountedObject<UIColor>, c2: CountedObject<UIColor>) -> Bool in
			return c1.count > c2.count
		}
		dominantColor = colors.count > 0 ? colors[0].object : UIColor(rgb: 0x000000)

		if edgeColors.count > 0
		{
			edgeColors.sort { (c1: CountedObject<UIColor>, c2: CountedObject<UIColor>) -> Bool in
				return c1.count > c2.count
			}

			var proposedEdgeColor = edgeColors[0]
			if proposedEdgeColor.object.isBlackOrWhite() // want to choose color over black/white so we keep looking
			{
				for i in 1 ..< edgeColors.count
				{
					let nextProposedColor = edgeColors[i]

					// make sure the second choice color is 40% as common as the first choice
					if (Double(nextProposedColor.count) / Double(proposedEdgeColor.count)) > 0.4
					{
						if !nextProposedColor.object.isBlackOrWhite()
						{
							proposedEdgeColor = nextProposedColor
							break
						}
					}
					else
					{
						// reached color threshold less than 40% of the original proposed edge color so bail
						break
					}
				}
			}
			return proposedEdgeColor.object
		}
		else
		{
			return nil
		}
	}

	private func findContrastingColors(_ colors: [CountedObject<UIColor>])
	{
		var sortedColors = [CountedObject<UIColor>]()
		let findDarkTextColor = !edgeColor.isDark()

		for countedColor in colors
		{
			let cc = countedColor.object.colorWithMinimumSaturation(0.15)

			if cc.isDark() == findDarkTextColor
			{
				let colorCount = countedColor.count
				sortedColors.append(CountedObject(object: cc, count: colorCount))
			}
		}

		sortedColors.sort { (c1: CountedObject<UIColor>, c2: CountedObject<UIColor>) -> Bool in
			return c1.count > c2.count
		}

		for curContainer in sortedColors
		{
			let curColor = curContainer.object

			if primaryColor == nil
			{
				if curColor.isContrasted(fromColor: edgeColor)
				{
					primaryColor = curColor
				}
			}
			else if secondaryColor == nil
			{
				if !primaryColor.isDistinct(fromColor: curColor) || !curColor.isContrasted(fromColor: edgeColor)
				{
					continue
				}
				secondaryColor = curColor
			}
			else if thirdColor == nil
			{
				if !secondaryColor.isDistinct(fromColor: curColor) || !primaryColor.isDistinct(fromColor: curColor) || !curColor.isContrasted(fromColor: edgeColor)
				{
					continue
				}

				thirdColor = curColor
				break
			}
		}
	}
}
