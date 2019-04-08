import UIKit


final class ShinobuServerTableViewCell: UITableViewCell
{
	// MARK: - Public properties
	// Server name
	private(set) var label: UILabel!
	// Enable switch
	private(set) var toggle: UISwitch!

	// MARK: - Initializers
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
	{
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		self.backgroundColor = Colors.background
		self.contentView.backgroundColor = self.backgroundColor
		self.isAccessibilityElement = true

		self.label = UILabel(frame: CGRect(16, (64 - 32) / 2, 144, 32))
		self.label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		self.label.textColor = .white
		self.contentView.addSubview(self.label)

		self.toggle = UISwitch()
		self.toggle.tintColor = UITableView.colorActionItem
		self.contentView.addSubview(self.toggle)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override func layoutSubviews()
	{
		super.layoutSubviews()

		label.frame = CGRect(16, (64 - 32) / 2, 144, 32)
		toggle.frame = CGRect(UIScreen.main.bounds.width - 16 - toggle.width, (64 - toggle.height) / 2, toggle.size)
	}

	override func setSelected(_ selected: Bool, animated: Bool)
	{
		super.setSelected(selected, animated: animated)

		if selected
		{
			backgroundColor = Colors.backgroundSelected
		}
		else
		{
			backgroundColor = Colors.background
		}
		contentView.backgroundColor = backgroundColor
		label.backgroundColor = backgroundColor
	}

	override func setHighlighted(_ highlighted: Bool, animated: Bool)
	{
		super.setHighlighted(highlighted, animated: animated)

		if highlighted
		{
			backgroundColor = Colors.backgroundSelected
		}
		else
		{
			backgroundColor = Colors.background
		}
		contentView.backgroundColor = backgroundColor
		label.backgroundColor = backgroundColor
	}
}
