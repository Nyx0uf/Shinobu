import UIKit


final class AlbumHeaderView: UIView
{
	// MARK: - Public properties
	// Album cover
	private(set) var image: UIImage!
	// Album title
	private(set) var lblTitle: UILabel!
	// Album artist
	private(set) var lblArtist: UILabel!
	// Album genre
	private(set) var lblGenre: UILabel!
	// Album year
	private(set) var lblYear: UILabel!
	// Size of the cover
	let coverSize: CGSize

	// MARK: - Initializers
	init(frame: CGRect, coverSize: CGSize)
	{
		self.coverSize = coverSize

		super.init(frame: frame)

		lblTitle = UILabel(frame: .zero)
		lblTitle.font = UIFont.systemFont(ofSize: 16, weight: .bold)
		lblTitle.numberOfLines = 2
		self.addSubview(lblTitle)

		lblArtist = UILabel(frame: .zero)
		lblArtist.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		self.addSubview(lblArtist)

		lblGenre = UILabel(frame: CGRect(coverSize.width + 4, frame.height - 16 - 4, 120, 16))
		lblGenre.font = UIFont.systemFont(ofSize: 12, weight: .light)
		self.addSubview(lblGenre)

		lblYear = UILabel(frame: CGRect(frame.width - 48 - 4, frame.height - 16 - 4, 48, 16))
		lblYear.textAlignment = .right
		lblYear.font = UIFont.systemFont(ofSize: 12, weight: .light)
		self.addSubview(lblYear)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Drawing
	override func draw(_ dirtyRect: CGRect)
	{
		guard let _ = image else { return }
		let imageRect = CGRect(.zero, coverSize)
		image.draw(in: imageRect, blendMode: .sourceAtop, alpha: 1)

		let context = UIGraphicsGetCurrentContext()
		context?.saveGState()
		context?.clip(to: imageRect)

		let startPoint = CGPoint(imageRect.minX, imageRect.midY)
		let endPoint = CGPoint(imageRect.maxX, imageRect.midY)
		let color = backgroundColor!
		let gradientColors: [CGColor] = [color.withAlphaComponent(0.05).cgColor, color.withAlphaComponent(0.75).cgColor, color.withAlphaComponent(0.9).cgColor]
		let locations: [CGFloat] = [0, 0.9, 1]
		let gradient = CGGradient(colorsSpace: CGColorSpace.NYXAppropriateColorSpace(), colors: gradientColors as CFArray, locations: locations)
		context?.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
		context?.restoreGState()
	}

	// MARK: - Public
	func updateHeaderWithAlbum(_ album: Album)
	{
		// Set cover
		var image: UIImage? = nil
		if let coverURL = album.localCoverURL
		{
			if let cover = UIImage.loadFromFileURL(coverURL)
			{
				image = cover
			}
			else
			{
				let string = album.name
				let bgColor = UIColor(rgb: string.djb2())
				image = UIImage.fromString(string, font: UIFont(name: "Chalkduster", size: coverSize.width / 4)!, fontColor: bgColor.inverted(), backgroundColor: bgColor, maxSize: coverSize)
			}
		}
		else
		{
			let string = album.name
			let bgColor = UIColor(rgb: string.djb2())
			image = UIImage.fromString(string, font: UIFont(name: "Chalkduster", size: coverSize.width / 4)!, fontColor: bgColor.inverted(), backgroundColor: bgColor, maxSize: coverSize)
		}
		self.image = image

		// Analyze colors
		let x = KawaiiColors(image: image!, precision: 8, samplingEdge: .right)
		x.analyze()
		backgroundColor = x.edgeColor
		lblTitle.textColor = x.primaryColor
		lblTitle.backgroundColor = backgroundColor
		lblArtist.textColor = x.secondaryColor
		lblArtist.backgroundColor = backgroundColor
		lblGenre.textColor = x.thirdColor
		lblGenre.backgroundColor = backgroundColor
		lblYear.textColor = x.thirdColor
		lblYear.backgroundColor = backgroundColor

		setNeedsDisplay()

		// Update frame for title / artist
		let s = album.name as NSString
		let width = frame.width - (coverSize.width + 8)
		let r = s.boundingRect(with: CGSize(width, 40), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : lblTitle.font!], context: nil)
		lblTitle.frame = CGRect(coverSize.width + 4, 4, ceil(r.width), ceil(r.height))
		lblArtist.frame = CGRect(coverSize.width + 4, lblTitle.maxY + 4, width, 18)

		lblTitle.text = album.name
		lblArtist.text = album.artist
		lblGenre.text = album.genre
		lblYear.text = album.year

		// Accessibility
		var stra = "\(album.name) \(NYXLocalizedString("lbl_by")) \(album.artist)\n"
		if let tracks = album.tracks
		{
			stra += "\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))\n"
			let total = tracks.reduce(Duration(seconds: 0)) { $0 + $1.duration }
			let minutes = total.seconds / 60
			stra += "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))\n"
		}
		accessibilityLabel = stra
	}
}
