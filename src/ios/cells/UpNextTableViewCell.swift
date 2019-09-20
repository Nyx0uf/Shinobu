import UIKit

final class UpNextTableViewCell: UITableViewCell {
	// MARK: - Public properties
	// Track number
	private(set) var lblTrack: UILabel!
	// Track title
	private(set) var lblArtistAlbum: UILabel!
	// Track duration
	private(set) var lblDuration: UILabel!

	// MARK: - Initializers
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		self.lblDuration = UILabel()
		self.lblDuration.font = UIFont.systemFont(ofSize: 10, weight: .light)
		self.lblDuration.textAlignment = .right
		self.contentView.addSubview(self.lblDuration)
		self.lblDuration.translatesAutoresizingMaskIntoConstraints = false
		self.lblDuration.heightAnchor.constraint(equalToConstant: 14).isActive = true
		self.lblDuration.widthAnchor.constraint(equalToConstant: 32).isActive = true
		self.lblDuration.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15).isActive = true
		self.lblDuration.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8).isActive = true

		self.lblTrack = UILabel()
		self.lblTrack.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
		self.lblTrack.textAlignment = .left
		self.contentView.addSubview(self.lblTrack)
		self.lblTrack.translatesAutoresizingMaskIntoConstraints = false
		self.lblTrack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8).isActive = true
		self.lblTrack.trailingAnchor.constraint(equalTo: self.lblDuration.leadingAnchor, constant: 8).isActive = true
		self.lblTrack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8).isActive = true
		self.lblTrack.heightAnchor.constraint(equalToConstant: 18).isActive = true

		self.lblArtistAlbum = UILabel()
		self.lblArtistAlbum.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		self.lblArtistAlbum.textAlignment = .left
		self.contentView.addSubview(self.lblArtistAlbum)
		self.lblArtistAlbum.translatesAutoresizingMaskIntoConstraints = false
		self.lblArtistAlbum.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8).isActive = true
		self.lblArtistAlbum.trailingAnchor.constraint(equalTo: self.lblDuration.leadingAnchor, constant: 8).isActive = true
		self.lblArtistAlbum.topAnchor.constraint(equalTo: self.lblTrack.bottomAnchor, constant: 2).isActive = true
		self.lblArtistAlbum.heightAnchor.constraint(equalToConstant: 16).isActive = true
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }
}
