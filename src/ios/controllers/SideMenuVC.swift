import UIKit


protocol SideMenuVCDelegate : class
{
	func didSelectMenuItem(_ selectedVC: SelectedVCType)
	func getSelectedController() -> SelectedVCType
}

final class SideMenuVC : UIViewController
{
	// MARK: - Public properties
	// Menu delegate
	weak var menuDelegate: SideMenuVCDelegate? = nil
	// MARK: - Private properties
	// Table view
	private var tableView: UITableView!
	// Number of table rows
	private let numberOfRows = 3

	override func viewDidLoad()
	{
		super.viewDidLoad()

		tableView.register(MenuViewTableViewCell.classForCoder(), forCellReuseIdentifier: "fr.whine.mpdremote.cell.menu")
		tableView.scrollsToTop = false
	}
}

// MARK: - UITableViewDataSource
extension SideMenuVC : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return numberOfRows + 1
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.mpdremote.cell.menu", for: indexPath) as! MenuViewTableViewCell

		var selected = false
		var image: UIImage! = nil
		switch (indexPath.row)
		{
		case 0:
			cell.accessibilityLabel = NYXLocalizedString("lbl_section_home")
			image = #imageLiteral(resourceName: "img-home")
			selected = menuDelegate?.getSelectedController() == .library
		case 1:
			cell.accessibilityLabel = NYXLocalizedString("lbl_section_server")
			image = #imageLiteral(resourceName: "img-server")
			selected = menuDelegate?.getSelectedController() == .server
		case 2:
			cell.accessibilityLabel = NYXLocalizedString("lbl_section_settings")
			image = #imageLiteral(resourceName: "img-settings")
			selected = menuDelegate?.getSelectedController() == .settings
		default:
			break
		}
		if image != nil
		{
			cell.ivLogo.image = image.withRenderingMode(.alwaysTemplate)
			cell.ivLogo.frame = CGRect(24.0, (cell.height - image.size.height) * 0.5, image.size)
			cell.lblSection.text = cell.accessibilityLabel
			cell.lblSection.frame = CGRect(96.0, (cell.height - cell.lblSection.height) * 0.5, cell.lblSection.size)
		}

		if selected
		{
			cell.ivLogo.tintColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
			cell.lblSection.textColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
			cell.lblSection.font = UIFont.boldSystemFont(ofSize: 13.0)
		}
		else
		{
			cell.ivLogo.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			cell.lblSection.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			cell.lblSection.font = UIFont.systemFont(ofSize: 13.0)
		}

		return cell
	}
}

// MARK: - UITableViewDelegate
extension SideMenuVC : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		tableView.deselectRow(at: indexPath, animated: false)
		var selectedVC = SelectedVCType.library
		switch (indexPath.row)
		{
			case 0:
				selectedVC = .library
			case 1:
				selectedVC = .server
			case 2:
				selectedVC = .settings
			case numberOfRows:
				return
			default:
				break
		}

		/*if newTopViewController === APP_DELEGATE().homeVC
		{
			APP_DELEGATE().window?.bringSubview(toFront: MiniPlayerView.shared)
		}*/
		menuDelegate?.didSelectMenuItem(selectedVC)
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		if indexPath.row == numberOfRows
		{
			return tableView.height
		}
		return 64.0
	}
}
