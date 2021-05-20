import UIKit

final class AlbumHeaderViewIPAD: UIView {
	// MARK: - Public properties
	// Album cover
	private(set) var imageView = UIImageView()
	// Album title
	private(set) var lblTitle = UILabel()
	// Album artist
	private(set) var lblArtist = UILabel()
	// Album year
	private(set) var lblYear = UILabel()
	// Size of the cover
	var coverSize: CGSize = .zero
	// MARK: - Private properties
	// Constraints
	private var titleTopConstraint: NSLayoutConstraint?
	private var titleLeadingConstraint: NSLayoutConstraint?
	private var titleTrailingConstraint: NSLayoutConstraint?
	private var artistTopConstraint: NSLayoutConstraint?
	private var artistLeadingConstraint: NSLayoutConstraint?
	private var artistTrailingConstraint: NSLayoutConstraint?
	private var yearTopConstraint: NSLayoutConstraint?
	private var yearLeadingConstraint: NSLayoutConstraint?
	private var yearTrailingConstraint: NSLayoutConstraint?

	// MARK: - Initializers
	override init(frame: CGRect) {
		super.init(frame: frame)

		self.backgroundColor = .systemBackground

		self.imageView.layer.cornerRadius = 10
		self.imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.imageView.layer.masksToBounds = true
		self.addSubview(imageView)
		self.imageView.translatesAutoresizingMaskIntoConstraints = false

		self.lblTitle.font = UIFont.systemFont(ofSize: 32, weight: .black)
		self.lblTitle.textColor = .label
		self.lblTitle.numberOfLines = 2
		self.addSubview(lblTitle)
		self.lblTitle.translatesAutoresizingMaskIntoConstraints = false

		self.lblArtist.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
		self.lblArtist.textColor = themeProvider.currentTheme.tintColor
		self.lblArtist.numberOfLines = 2
		self.addSubview(lblArtist)
		self.lblArtist.translatesAutoresizingMaskIntoConstraints = false

		self.lblYear.font = UIFont.systemFont(ofSize: 20, weight: .regular)
		self.lblYear.textColor = .secondaryLabel
		self.addSubview(lblYear)
		self.lblYear.translatesAutoresizingMaskIntoConstraints = false

		initializeTheming()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Overrides
	override var frame: CGRect {
		didSet {
			if self.imageView.superview != nil && self.lblTitle.superview != nil && self.lblArtist.superview != nil && self.lblYear.superview != nil {
				self.setConstraints()
			}
		}
	}

	// MARK: - Public
	func updateHeaderWithAlbum(_ album: Album) {
		// Set cover
		var image: UIImage?
		if let cover = album.asset(ofSize: .large) {
			image = imageView.size == .zero ? cover : cover.smartCropped(toSize: imageView.size)
		} else {
			let string = album.name
			let bgColor = UIColor(rgb: string.djb2())
			image = UIImage.fromString(string, font: UIFont(name: "Chalkduster", size: coverSize.width / 4)!, fontColor: bgColor.inverted(), backgroundColor: bgColor, maxSize: coverSize)
		}
		imageView.image = image

		lblTitle.text = album.name
		lblArtist.text = album.artist
		lblYear.text = "\(album.year) • \(album.genre)"

		// Accessibility
		var stra = "\(album.name) \(NYXLocalizedString("lbl_by")) \(album.artist)\n"
		if let tracks = album.tracks {
			stra += "\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))\n"
			let total = tracks.reduce(Duration(seconds: 0)) { $0 + $1.duration }
			let minutes = total.value / 60
			stra += "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))\n"
		}
		accessibilityLabel = stra

		let totalInfosHeight = lblTitle.height + lblArtist.height + lblYear.height + (2 * 8) + imageView.y
		let topAnchor = ((self.height - totalInfosHeight) / 2).rounded()
		titleTopConstraint?.isActive = false
		titleTopConstraint = lblTitle.topAnchor.constraint(equalTo: self.topAnchor, constant: topAnchor)
		titleTopConstraint?.isActive = true
	}

	// MARK: - Private
	private func setConstraints() {
		let imgMargin = ((self.height - coverSize.height) / 2).rounded()
		imageView.widthAnchor.constraint(equalToConstant: coverSize.width).isActive = true
		imageView.heightAnchor.constraint(equalToConstant: coverSize.height).isActive = true
		imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: imgMargin).isActive = true
		imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: imgMargin).isActive = true

		let titleHeight = CGFloat(20)
		let artistHeight = CGFloat(18)
		let yearHeight = CGFloat(16)
		let marginTop = CGFloat(8)
		let totalInfosHeight = titleHeight + artistHeight + yearHeight + (2 * marginTop)
		let topAnchor = ((self.height - totalInfosHeight) / 2).rounded()

		titleTopConstraint?.isActive = false
		titleLeadingConstraint?.isActive = false
		titleTrailingConstraint?.isActive = false
		titleTopConstraint = lblTitle.topAnchor.constraint(equalTo: self.topAnchor, constant: topAnchor)
		titleLeadingConstraint = lblTitle.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: imgMargin)
		titleTrailingConstraint = lblTitle.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: imgMargin)
		titleTopConstraint?.isActive = true
		titleLeadingConstraint?.isActive = true
		titleTrailingConstraint?.isActive = true

		artistTopConstraint?.isActive = false
		artistLeadingConstraint?.isActive = false
		artistTrailingConstraint?.isActive = false
		artistTopConstraint = lblArtist.topAnchor.constraint(equalTo: lblTitle.bottomAnchor, constant: marginTop)
		artistLeadingConstraint = lblArtist.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: imgMargin)
		artistTrailingConstraint = lblArtist.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: imgMargin)
		artistTopConstraint?.isActive = true
		artistLeadingConstraint?.isActive = true
		artistTrailingConstraint?.isActive = true

		yearTopConstraint?.isActive = false
		yearLeadingConstraint?.isActive = false
		yearTrailingConstraint?.isActive = false
		yearTopConstraint = lblYear.topAnchor.constraint(equalTo: lblArtist.bottomAnchor, constant: marginTop)
		yearLeadingConstraint = lblYear.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: imgMargin)
		yearTrailingConstraint = lblYear.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: imgMargin)
		yearTopConstraint?.isActive = true
		yearLeadingConstraint?.isActive = true
		yearTrailingConstraint?.isActive = true
	}
}

extension AlbumHeaderViewIPAD: Themed {
	func applyTheme(_ theme: Theme) {
	}
}
