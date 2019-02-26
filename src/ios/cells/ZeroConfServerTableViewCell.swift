import UIKit


final class ZeroConfServerTableViewCell : UITableViewCell
{
	// MARK: - Public properties
	// Track number
	private(set) var lblName: UILabel!
	// Track title
	private(set) var lblHostname: UILabel!

	// MARK: - Initializers
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
	{
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		self.backgroundColor = Colors.background
		self.contentView.backgroundColor = self.backgroundColor

		self.lblName = UILabel()
		self.lblName.backgroundColor = self.backgroundColor
		self.lblName.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		self.lblName.font = UIFont.boldSystemFont(ofSize: 14.0)
		self.contentView.addSubview(self.lblName)

		self.lblHostname = UILabel()
		self.lblHostname.backgroundColor = self.backgroundColor
		self.lblHostname.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		self.lblHostname.font = UIFont.systemFont(ofSize: 12.0)
		self.contentView.addSubview(self.lblHostname)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews()
	{
		self.lblName.frame = CGRect(.zero, frame.width, frame.height - 20.0)
		self.lblHostname.frame = CGRect(0.0, self.lblName.bottom, frame.width, 20.0)
	}
}
