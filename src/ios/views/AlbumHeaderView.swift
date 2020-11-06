import UIKit

final class AlbumHeaderView: UIView {
	// MARK: - Public properties
	// Album cover
	private(set) var imageView: UIImageView!
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
	init(frame: CGRect, coverSize: CGSize) {
		self.coverSize = coverSize

		super.init(frame: frame)

		self.backgroundColor = .systemBackground

		self.imageView = UIImageView()
		self.imageView.layer.cornerRadius = 10
		self.imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		self.imageView.layer.masksToBounds = true
		self.addSubview(imageView)
		self.imageView.translatesAutoresizingMaskIntoConstraints = false
		self.imageView.widthAnchor.constraint(equalToConstant: coverSize.width - 16).isActive = true
		self.imageView.heightAnchor.constraint(equalToConstant: coverSize.height - 16).isActive = true
		self.imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
		self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8).isActive = true

		let titleHeight = CGFloat(20)
		let artistHeight = CGFloat(18)
		let yearHeight = CGFloat(16)
		let genreHeight = CGFloat(16)
		let marginTop = CGFloat(5)
		let horizontalAnchor = CGFloat(10)
		let totalInfosHeight = titleHeight + artistHeight + yearHeight + genreHeight + (3 * marginTop)
		let topAnchor = ((frame.height - totalInfosHeight) / 2).rounded()
		self.lblTitle = UILabel(frame: .zero)
		self.lblTitle.font = UIFont.systemFont(ofSize: 16, weight: .black)
		self.lblTitle.textColor = .label
		self.addSubview(lblTitle)
		self.lblTitle.translatesAutoresizingMaskIntoConstraints = false
		self.lblTitle.leadingAnchor.constraint(equalTo: self.imageView.trailingAnchor, constant: horizontalAnchor).isActive = true
		self.lblTitle.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: horizontalAnchor).isActive = true
		self.lblTitle.topAnchor.constraint(equalTo: self.topAnchor, constant: topAnchor).isActive = true

		self.lblArtist = UILabel(frame: .zero)
		self.lblArtist.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
		self.lblArtist.textColor = .secondaryLabel
		self.addSubview(lblArtist)
		self.lblArtist.translatesAutoresizingMaskIntoConstraints = false
		self.lblArtist.leadingAnchor.constraint(equalTo: self.imageView.trailingAnchor, constant: horizontalAnchor).isActive = true
		self.lblArtist.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: horizontalAnchor).isActive = true
		self.lblArtist.topAnchor.constraint(equalTo: self.lblTitle.bottomAnchor, constant: marginTop).isActive = true

		self.lblYear = UILabel(frame: .zero)
		self.lblYear.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		self.lblYear.textColor = .secondaryLabel
		self.addSubview(lblYear)
		self.lblYear.translatesAutoresizingMaskIntoConstraints = false
		self.lblYear.leadingAnchor.constraint(equalTo: self.imageView.trailingAnchor, constant: horizontalAnchor).isActive = true
		self.lblYear.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: horizontalAnchor).isActive = true
		self.lblYear.topAnchor.constraint(equalTo: self.lblArtist.bottomAnchor, constant: marginTop).isActive = true

		self.lblGenre = UILabel(frame: .zero)
		self.lblGenre.font = UIFont.systemFont(ofSize: 12, weight: .light)
		self.lblGenre.textColor = .secondaryLabel
		self.addSubview(lblGenre)
		self.lblGenre.translatesAutoresizingMaskIntoConstraints = false
		self.lblGenre.leadingAnchor.constraint(equalTo: self.imageView.trailingAnchor, constant: horizontalAnchor).isActive = true
		self.lblGenre.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: horizontalAnchor).isActive = true
		self.lblGenre.topAnchor.constraint(equalTo: self.lblYear.bottomAnchor, constant: marginTop).isActive = true
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

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
		lblGenre.text = album.genre
		lblYear.text = album.year

		// Accessibility
		var stra = "\(album.name) \(NYXLocalizedString("lbl_by")) \(album.artist)\n"
		if let tracks = album.tracks {
			stra += "\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))\n"
			let total = tracks.reduce(Duration(seconds: 0)) { $0 + $1.duration }
			let minutes = total.seconds / 60
			stra += "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))\n"
		}
		accessibilityLabel = stra
	}
}
