import UIKit

final class TrackTableViewCellIPAD: UITableViewCell, ReuseIdentifying {
	// MARK: - Public properties
	// Track number
	private(set) var lblTrack = UILabel()
	// Track title
	private(set) var lblTitle = UILabel()
	// Artist
	private(set) var lblArtist = UILabel()
	// Track duration
	private(set) var lblDuration = UILabel()
	//
	var isEvenCell = false {
		didSet {
			if traitCollection.userInterfaceStyle == .dark {
				backgroundColor = isEvenCell ? .black : UIColor(rgb: 0x121212)
			} else {
				backgroundColor = isEvenCell ? .systemBackground : .secondarySystemBackground
			}
		}
	}

	// MARK: - Initializers
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		self.lblTrack.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		self.lblTrack.textAlignment = .center
		self.lblTrack.numberOfLines = 1
		//self.lblTrack.backgroundColor = .green
		self.contentView.addSubview(self.lblTrack)
		self.lblTrack.translatesAutoresizingMaskIntoConstraints = false
		self.lblTrack.widthAnchor.constraint(equalToConstant: 22).isActive = true
		self.lblTrack.heightAnchor.constraint(equalToConstant: 20).isActive = true
		self.lblTrack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 17).isActive = true
		self.lblTrack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8).isActive = true

		self.lblDuration.font = UIFont.systemFont(ofSize: 14, weight: .light)
		self.lblDuration.textAlignment = .right
		self.lblDuration.numberOfLines = 1
		//self.lblDuration.backgroundColor = .red
		self.contentView.addSubview(self.lblDuration)
		self.lblDuration.translatesAutoresizingMaskIntoConstraints = false
		self.lblDuration.widthAnchor.constraint(equalToConstant: 36).isActive = true
		self.lblDuration.heightAnchor.constraint(equalToConstant: 20).isActive = true
		self.lblDuration.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 17).isActive = true
		self.lblDuration.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8).isActive = true

		self.lblArtist.font = UIFont.systemFont(ofSize: 18, weight: .regular)
		self.lblArtist.textAlignment = .left
		self.lblArtist.numberOfLines = 1
		//self.lblArtist.backgroundColor = .yellow
		self.contentView.addSubview(self.lblArtist)
		self.lblArtist.translatesAutoresizingMaskIntoConstraints = false
		self.lblArtist.widthAnchor.constraint(equalToConstant: 128).isActive = true
		self.lblArtist.heightAnchor.constraint(equalToConstant: 24).isActive = true
		self.lblArtist.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15).isActive = true
		self.lblArtist.trailingAnchor.constraint(equalTo: self.lblDuration.leadingAnchor, constant: -8).isActive = true

		self.lblTitle.font = UIFont.systemFont(ofSize: 18, weight: .medium)
		self.lblTitle.textAlignment = .left
		self.lblTitle.numberOfLines = 1
		//self.lblTitle.backgroundColor = .blue
		self.contentView.addSubview(self.lblTitle)
		self.lblTitle.translatesAutoresizingMaskIntoConstraints = false
		self.lblTitle.heightAnchor.constraint(equalToConstant: 24).isActive = true
		self.lblTitle.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15).isActive = true
		self.lblTitle.leadingAnchor.constraint(equalTo: self.lblTrack.trailingAnchor, constant: 8).isActive = true
		self.lblTitle.trailingAnchor.constraint(equalTo: self.lblArtist.leadingAnchor, constant: -8).isActive = true
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }
}
