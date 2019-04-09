import UIKit


private struct ServerData
{
	// Server name
	let name: String
	// Is this the active server?
	let isSelected: Bool
}

final class ServersListVC: NYXTableViewController
{
	// MARK: - Private properties
	// List of servers
	private var servers = [ServerData]()
	// Tableview cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.server"
	// Add/Edit server VC
	private var addServerVC: ServerAddVC? = nil
	// MPD Data source
	private let mpdBridge: MPDBridge
	// Servers manager
	private let serversManager: ServersManager

	// MARK: - Initializers
	init(mpdBridge: MPDBridge)
	{
		self.mpdBridge = mpdBridge
		self.serversManager = ServersManager()

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }
	
	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Remove back button label
		navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "btn-back")
		navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "btn-back")
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		let closeButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-close"), style: .plain, target: self, action: #selector(closeAction(_:)))
		closeButton.accessibilityLabel = NYXLocalizedString("lbl_close")
		navigationItem.leftBarButtonItem = closeButton
		let addButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-add"), style: .plain, target: self, action: #selector(addMpdServerAction(_:)))
		addButton.accessibilityLabel = NYXLocalizedString("lbl_add_mpd_server")
		navigationItem.rightBarButtonItem = addButton
		
		tableView.register(ShinobuServerTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.separatorColor = .black
		tableView.rowHeight = 64
	}
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		refreshServers()
	}

	// MARK: - Buttons actions
	@objc func closeAction(_ sender: Any?)
	{
		dismiss(animated: true, completion: nil)
	}

	@objc func addMpdServerAction(_ sender: Any?)
	{
		showServerVC(with: nil)
	}
	
	// MARK: - Private
	private func refreshServers()
	{
		let serversList = serversManager.getServersList()

		let enabledServerName = serversManager.getSelectedServerName()
		servers = serversList.compactMap { ServerData(name: $0.name, isSelected: ($0.name == enabledServerName)) }
		tableView.reloadData()

		// Navigation bar title
		titleView.setMainText(NYXLocalizedString("lbl_header_server_list"), detailText: "(\(servers.count))")
	}

	private func showServerVC(with server: ShinobuServer?)
	{
		if addServerVC == nil
		{
			addServerVC = ServerAddVC(mpdBridge: mpdBridge)
		}

		if let vc = addServerVC
		{
			vc.selectedServer = server
			navigationController?.pushViewController(vc, animated: true)
		}
	}

	@objc private func toggleServer(_ sender: UISwitch!)
	{
		guard let s = sender else { return }
		serversManager.setSelectedServerName(s.isOn ? servers[s.tag].name : "")
		refreshServers()

		NotificationCenter.default.postOnMainThreadAsync(name: .audioServerConfigurationDidChange, object: serversManager.getSelectedServer()?.mpd, userInfo: nil)
	}
}

// MARK: - UITableViewDataSource
extension ServersListVC
{
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return servers.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ShinobuServerTableViewCell
		
		let server = servers[indexPath.row]

		cell.label.text = server.name
		cell.toggle.isOn = server.isSelected
		cell.toggle.tag = indexPath.row
		cell.toggle.addTarget(self, action: #selector(toggleServer(_:)), for: .valueChanged)
		cell.accessibilityLabel = "\(server.name) \(NYXLocalizedString("lbl_is")) \(NYXLocalizedString(server.isSelected ? "lbl_current_selected_server" : "lbl_current_selected_server_not"))"

		return cell
	}
}

// MARK: - UITableViewDelegate
extension ServersListVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		let serverData = servers[indexPath.row]
		let shinobuServers = serversManager.getServersList()
		let tmp = shinobuServers.filter { $0.name == serverData.name }
		if tmp.count > 0
		{
			showServerVC(with: tmp[0])
		}
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
	{
		let action = UIContextualAction(style: .normal, title: NYXLocalizedString("lbl_remove_from_playlist")) { [weak self] (action, view, completionHandler) in

			guard let strongSelf = self else { return }
			let serverData = strongSelf.servers[indexPath.row]
			if strongSelf.serversManager.removeServerByName(serverData.name)
			{
				strongSelf.refreshServers()
			}

			completionHandler(true)
		}
		action.image = #imageLiteral(resourceName: "btn-trash")
		action.backgroundColor = Colors.destructiveAction

		return UISwipeActionsConfiguration(actions: [action])
	}
}
