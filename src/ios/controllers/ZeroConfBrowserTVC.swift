import UIKit


protocol ZeroConfBrowserTVCDelegate : class
{
	func audioServerDidChange(with server: ShinobuServer)
}


final class ZeroConfBrowserTVC : NYXTableViewController
{
	// MARK: - Public properties
	// Delegate
	weak var delegate: ZeroConfBrowserTVCDelegate? = nil
	// Currently selectd server on the add vc
	var selectedServer: ShinobuServer? = nil

	// MARK: - Private properties
	// Zeroconf explorer
	private var zeroConfExplorer: ZeroConfExplorer! = nil
	// List of servers found
	private var servers = [ShinobuServer]()

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction(_:)))
		self.navigationItem.leftBarButtonItem = done

		// Navigation bar title
		titleView.text = NYXLocalizedString("lbl_header_server_zeroconf")

		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.separatorColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		tableView.rowHeight = 64

		self.zeroConfExplorer = ZeroConfExplorer()
		self.zeroConfExplorer.delegate = self
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		self.zeroConfExplorer.searchForServices(type: "_mpd._tcp.")
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)
		self.zeroConfExplorer.stopSearch()
	}

	// MARK: - Buttons actions
	@objc private func doneAction(_ sender: Any?)
	{
		self.dismiss(animated: true, completion: nil)
	}
}

// MARK: - UITableViewDataSource
extension ZeroConfBrowserTVC
{
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return servers.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "fr.whine.shinobu.cell.zeroconf")
		cell.backgroundColor = Colors.background
		cell.contentView.backgroundColor = Colors.background
		let backgroundView = UIView()
		backgroundView.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
		cell.selectedBackgroundView = backgroundView

		let server = servers[indexPath.row]
		cell.textLabel?.text = server.name
		cell.textLabel?.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
		cell.detailTextLabel?.text = server.mpd.hostname + ":" + String(server.mpd.port)
		cell.detailTextLabel?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)

		if let currentServer = selectedServer
		{
			if currentServer == server
			{
				cell.accessoryType = .checkmark
			}
			else
			{
				cell.accessoryType = .none
			}
		}
		else
		{
			cell.accessoryType = .none
		}

		return cell
	}
}

// MARK: - UITableViewDelegate
extension ZeroConfBrowserTVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		// Check if same server
		let selected = servers[indexPath.row]
		if let currentServer = selectedServer
		{
			if selected == currentServer
			{
				return
			}
		}

		// Different server, update
		self.selectedServer = selected

		delegate?.audioServerDidChange(with: selected)
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
			tableView.reloadData()
		})
	}
}

extension ZeroConfBrowserTVC : ZeroConfExplorerDelegate
{
	internal func didFindServer(_ server: ShinobuServer)
	{
		servers = zeroConfExplorer.services.map({$0.value})
		self.tableView.reloadData()
	}
}
