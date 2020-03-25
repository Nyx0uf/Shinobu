import UIKit

final class TrackTableViewCell: UITableViewCell {
	// MARK: - Public properties
	// Track number
	private(set) var lblTrack: UILabel!
	// Track title
	private(set) var lblTitle: UILabel!
	// Track duration
	private(set) var lblDuration: UILabel!
	//
	var isEvenCell = false {
		didSet {
			backgroundColor = isEvenCell ? .systemBackground : .secondarySystemBackground
			contentView.backgroundColor = backgroundColor
		}
	}

	// MARK: - Initializers
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		self.lblTrack = UILabel()
		self.lblTrack.font = UIFont.systemFont(ofSize: 10, weight: .regular)
		self.lblTrack.textAlignment = .center
		self.contentView.addSubview(self.lblTrack)
		self.lblTrack.translatesAutoresizingMaskIntoConstraints = false
		self.lblTrack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8).isActive = true
		self.lblTrack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15).isActive = true
		self.lblTrack.heightAnchor.constraint(equalToConstant: 14).isActive = true
		self.lblTrack.widthAnchor.constraint(equalToConstant: 18).isActive = true

		self.lblDuration = UILabel()
		self.lblDuration.font = UIFont.systemFont(ofSize: 10, weight: .light)
		self.lblDuration.textAlignment = .right
		self.contentView.addSubview(self.lblDuration)
		self.lblDuration.translatesAutoresizingMaskIntoConstraints = false
		self.lblDuration.heightAnchor.constraint(equalToConstant: 14).isActive = true
		self.lblDuration.widthAnchor.constraint(equalToConstant: 32).isActive = true
		self.lblDuration.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15).isActive = true
		self.lblDuration.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8).isActive = true

		self.lblTitle = UILabel()
		self.lblTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
		self.lblTitle.textAlignment = .left
		self.contentView.addSubview(self.lblTitle)
		self.lblTitle.translatesAutoresizingMaskIntoConstraints = false
		self.lblTitle.leadingAnchor.constraint(equalTo: self.lblTrack.trailingAnchor, constant: 8).isActive = true
		self.lblTitle.trailingAnchor.constraint(equalTo: self.lblDuration.leadingAnchor, constant: 8).isActive = true
		self.lblTitle.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 13).isActive = true
		self.lblTitle.heightAnchor.constraint(equalToConstant: 18).isActive = true
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }
}
