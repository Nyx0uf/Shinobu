import UIKit


final class ZeroConfServerTableViewCell : UITableViewCell
{
	// MARK: - Public properties
	// Track number
	@IBOutlet private(set) var lblName: UILabel!
	// Track title
	@IBOutlet private(set) var lblHostname: UILabel!

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
}
