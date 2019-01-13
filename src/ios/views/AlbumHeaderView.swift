import UIKit


final class AlbumHeaderView : UIView
{
	// MARK: - Public properties
	// Album cover
	private(set) var image: UIImage!
	// Album title
	@IBOutlet private(set) var lblTitle: TopAlignedLabel!
	// Album artist
	@IBOutlet private(set) var lblArtist: UILabel!
	// Album genre
	@IBOutlet private(set) var lblGenre: UILabel!
	// Album year
	@IBOutlet private(set) var lblYear: UILabel!
	// Size of the cover
	var coverSize: CGSize!

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}

	// MARK: - Drawing
	override func draw(_ dirtyRect: CGRect)
	{
		guard let _ = image else {return}
		let imageRect = CGRect(.zero, coverSize)
		image.draw(in: imageRect, blendMode: .sourceAtop, alpha: 1.0)

		let context = UIGraphicsGetCurrentContext()
		context?.saveGState()
		context?.clip(to: imageRect)

		let startPoint = CGPoint(imageRect.minX, imageRect.midY)
		let endPoint = CGPoint(imageRect.maxX, imageRect.midY)
		let color = backgroundColor!
		let gradientColors: [CGColor] = [color.withAlphaComponent(0.05).cgColor, color.withAlphaComponent(0.75).cgColor, color.withAlphaComponent(0.9).cgColor]
		let locations: [CGFloat] = [0.0, 0.9, 1.0]
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
				//let coverSize = NSKeyedUnarchiver.unarchiveObject(with: Settings.shared.data(forKey: kNYXPrefCoversSize)!) as! NSValue
				let coverSize = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSValue.classForCoder()], from: Settings.shared.data(forKey: kNYXPrefCoversSize)!) as? NSValue
				image = generateCoverForAlbum(album, size: (coverSize?.cgSizeValue)!)
			}
		}
		else
		{
			//let coverSize = NSKeyedUnarchiver.unarchiveObject(with: Settings.shared.data(forKey: kNYXPrefCoversSize)!) as! NSValue
			let coverSize = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSValue.classForCoder()], from: Settings.shared.data(forKey: kNYXPrefCoversSize)!) as? NSValue
			image = generateCoverForAlbum(album, size: (coverSize?.cgSizeValue)!)
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
		let width = frame.width - (coverSize.width + 8.0)
		let r = s.boundingRect(with: CGSize(width, 40.0), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : lblTitle.font], context: nil)
		lblTitle.frame = CGRect(coverSize.width + 4.0, 4.0, ceil(r.width), ceil(r.height))
		lblArtist.frame = CGRect(coverSize.width + 4.0, lblTitle.bottom + 4.0, width - (coverSize.width + 8.0), 18.0)

		lblTitle.text = album.name
		lblArtist.text = album.artist
		lblGenre.text = album.genre
		lblYear.text = album.year

		// Accessibility
		var stra = "\(album.name) \(NYXLocalizedString("lbl_by")) \(album.artist)\n"
		if let tracks = album.tracks
		{
			stra += "\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))\n"
			let total = tracks.reduce(Duration(seconds: 0)){$0 + $1.duration}
			let minutes = total.seconds / 60
			stra += "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))\n"
		}
		accessibilityLabel = stra
	}
}
