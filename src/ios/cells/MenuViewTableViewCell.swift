import UIKit


final class MenuViewTableViewCell : UITableViewCell
{
	// MARK: - Public properties
	// Section image
	private(set) var ivLogo: UIImageView!
	// Section label
	private(set) var lblSection: UILabel!

	// MARK: - Initializers
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
	{
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 0)
		self.isAccessibilityElement = true
		self.selectionStyle = .none
		self.layoutMargins = .zero

		let logoSize = CGSize(96.0, 96.0)
		self.ivLogo = UIImageView(frame: CGRect(48.0, (128.0 - logoSize.height) * 0.5, logoSize))
		self.contentView.addSubview(self.ivLogo)

		self.lblSection = UILabel(frame: CGRect(0.0, 0.0, logoSize.width + 32.0, 32.0))
		self.lblSection.font = UIFont.systemFont(ofSize: 14.0)
		self.contentView.addSubview(self.lblSection)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
}
