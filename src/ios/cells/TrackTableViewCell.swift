import UIKit


final class TrackTableViewCell : UITableViewCell
{
	// MARK: - Public properties
	// Track number
	private(set) var lblTrack: UILabel!
	// Track title
	private(set) var lblTitle: UILabel!
	// Track duration
	private(set) var lblDuration: UILabel!
	// Separator
	private(set) var separator: UIView!

	// MARK: - Initializers
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
	{
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = Colors.background
		self.contentView.backgroundColor = self.backgroundColor

		self.lblTrack = UILabel()
		self.lblTrack.backgroundColor = Colors.background
		self.lblTrack.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		self.lblTrack.font = UIFont.systemFont(ofSize: 10, weight: .regular)
		self.lblTrack.textAlignment = .center
		self.contentView.addSubview(self.lblTrack)
		self.lblTrack.translatesAutoresizingMaskIntoConstraints = false
		self.lblTrack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8.0).isActive = true
		self.lblTrack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15.0).isActive = true
		self.lblTrack.heightAnchor.constraint(equalToConstant: 14.0).isActive = true
		self.lblTrack.widthAnchor.constraint(equalToConstant: 18.0).isActive = true

		self.lblDuration = UILabel()
		self.lblDuration.backgroundColor = Colors.background
		self.lblDuration.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		self.lblDuration.font = UIFont.systemFont(ofSize: 10, weight: .light)
		self.lblDuration.textAlignment = .right
		self.contentView.addSubview(self.lblDuration)
		self.lblDuration.translatesAutoresizingMaskIntoConstraints = false
		self.lblDuration.heightAnchor.constraint(equalToConstant: 14.0).isActive = true
		self.lblDuration.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
		self.lblDuration.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15.0).isActive = true
		self.lblDuration.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8.0).isActive = true

		self.lblTitle = UILabel()
		self.lblTitle.backgroundColor = Colors.background
		self.lblTitle.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		self.lblTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
		self.lblTitle.textAlignment = .left
		self.contentView.addSubview(self.lblTitle)
		self.lblTitle.translatesAutoresizingMaskIntoConstraints = false
		self.lblTitle.leadingAnchor.constraint(equalTo: self.lblTrack.trailingAnchor, constant: 8.0).isActive = true
		self.lblTitle.trailingAnchor.constraint(equalTo: self.lblDuration.leadingAnchor, constant: 8.0).isActive = true
		self.lblTitle.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 13.0).isActive = true
		self.lblTitle.heightAnchor.constraint(equalToConstant: 18.0).isActive = true

		self.separator = UIView()
		self.separator.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		self.contentView.addSubview(self.separator)
		self.separator.translatesAutoresizingMaskIntoConstraints = false
		self.separator.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8.0).isActive = true
		self.separator.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8.0).isActive = true
		self.separator.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0.0).isActive = true
		self.separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override func setSelected(_ selected: Bool, animated: Bool)
	{
		super.setSelected(selected, animated: animated)

		if selected
		{
			backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		}
		else
		{
			backgroundColor = Colors.background
		}
		contentView.backgroundColor = backgroundColor
		lblTitle.backgroundColor = backgroundColor
		lblDuration.backgroundColor = backgroundColor
		lblTrack.backgroundColor = backgroundColor
	}

	override func setHighlighted(_ highlighted: Bool, animated: Bool)
	{
		super.setHighlighted(highlighted, animated: animated)

		if highlighted
		{
			backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		}
		else
		{
			backgroundColor = Colors.background
		}
		contentView.backgroundColor = backgroundColor
		lblTitle.backgroundColor = backgroundColor
		lblDuration.backgroundColor = backgroundColor
		lblTrack.backgroundColor = backgroundColor
	}
}
