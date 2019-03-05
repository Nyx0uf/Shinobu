import UIKit


final class ShinobuServerTableViewCell : UITableViewCell
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

		self.label = UILabel(frame: CGRect(16.0, (64 - 32) / 2, 144.0, 32.0))
		self.label.font = UIFont.systemFont(ofSize: 16.0)
		self.label.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		self.contentView.addSubview(self.label)

		self.toggle = UISwitch()
		self.contentView.addSubview(self.toggle)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()

		self.label.frame = CGRect(16.0, (64 - 32) / 2, 144.0, 32.0)
		self.toggle.frame = CGRect(UIScreen.main.bounds.width - 16.0 - self.toggle.width, (64 - self.toggle.height) / 2, self.toggle.size)
	}

	override func setSelected(_ selected: Bool, animated: Bool)
	{
		super.setSelected(selected, animated: animated)

		if selected
		{
			backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
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
			backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
		}
		else
		{
			backgroundColor = Colors.background
		}
		contentView.backgroundColor = backgroundColor
		label.backgroundColor = backgroundColor
	}
}
