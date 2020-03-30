import UIKit

private struct ServerData {
	// Server name
	let name: String
	// Is this the active server?
	let isSelected: Bool
}

final class ServersListVC: NYXTableViewController {
	// MARK: - Private properties
	// List of servers
	private var servers = [ServerData]()
	// Tableview cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.server"
	// Add/Edit server VC
	private var addServerVC: ServerAddVC?
	// MPD Data source
	private let mpdBridge: MPDBridge
	// Servers manager
	private let serversManager: ServersManager

	// MARK: - Initializers
	init(mpdBridge: MPDBridge) {
		self.mpdBridge = mpdBridge
		self.serversManager = ServersManager()

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.titleView = nil
		title = NYXLocalizedString("lbl_header_servers_list")
		navigationController?.navigationBar.prefersLargeTitles = true

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
		tableView.rowHeight = 64
		tableView.tableFooterView = UIView()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		refreshServers()
	}

	// MARK: - Buttons actions
	@objc private func closeAction(_ sender: Any?) {
		dismiss(animated: true, completion: nil)
		// lol ugly
		if let p = navigationController?.presentationController {
			p.delegate?.presentationControllerDidDismiss?(p)
		}
	}

	@objc private func addMpdServerAction(_ sender: Any?) {
		showServerVC(with: nil)
	}

	// MARK: - Private
	private func refreshServers() {
		let serversList = serversManager.getServersList()

		let enabledServerName = serversManager.getSelectedServerName()
		servers = serversList.compactMap { ServerData(name: $0.name, isSelected: ($0.name == enabledServerName)) }
		tableView.reloadData()

		// Navigation bar title
		self.title = "\(servers.count) \(NYXLocalizedString(servers.count == 1 ? "lbl_header_server_list" : "lbl_header_servers_list"))"
	}

	private func showServerVC(with server: ShinobuServer?) {
		if addServerVC == nil {
			addServerVC = ServerAddVC(style: .grouped, mpdBridge: mpdBridge)
		}

		if let avc = addServerVC {
			avc.selectedServer = server
			navigationController?.pushViewController(avc, animated: true)
		}
	}

	@objc private func toggleServer(_ sender: UISwitch!) {
		guard let swi = sender else { return }
		serversManager.setSelectedServerName(swi.isOn ? servers[swi.tag].name : "")
		refreshServers()

		NotificationCenter.default.postOnMainThreadAsync(name: .audioServerConfigurationDidChange, object: serversManager.getSelectedServer()?.mpd, userInfo: nil)
	}

	private func handleEmptyView(tableView: UITableView, isEmpty: Bool) {
		if isEmpty {
			let emptyView = UIView(frame: CGRect(x: tableView.center.x, y: tableView.center.y, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
			emptyView.backgroundColor = tableView.backgroundColor

			let btn = AwesomeButton(text: NYXLocalizedString("lbl_add_one"), font: UIFont.systemFont(ofSize: 32, weight: .ultraLight), symbolName: "plus.circle", symbolConfiguration: UIImage.SymbolConfiguration(pointSize: 64, weight: .ultraLight), imagePosition: .top)
			btn.translatesAutoresizingMaskIntoConstraints = false
			btn.tintColor = .label
			btn.selectedTintColor = themeProvider.currentTheme.tintColor
			btn.addTarget(self, action: #selector(addMpdServerAction(_:)), for: .touchUpInside)
			emptyView.addSubview(btn)
			btn.x = (emptyView.width - btn.width) / 2
			btn.y = (emptyView.height - btn.height) / 2

			tableView.backgroundView = emptyView
			tableView.separatorStyle = .none
		} else {
			tableView.backgroundView = nil
			tableView.separatorStyle = .singleLine
		}
	}
}

// MARK: - UITableViewDataSource
extension ServersListVC {
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		handleEmptyView(tableView: tableView, isEmpty: servers.isEmpty)
		return servers.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ShinobuServerTableViewCell

		let server = servers[indexPath.row]

		cell.label.text = server.name
		cell.toggle.isOn = server.isSelected
		cell.toggle.tag = indexPath.row
		cell.toggle.addTarget(self, action: #selector(toggleServer(_:)), for: .valueChanged)
		cell.accessibilityLabel = "\(server.name) \(NYXLocalizedString("lbl_is")) \(NYXLocalizedString(server.isSelected ? "lbl_current_selected_server" : "lbl_current_selected_server_not"))"

		let view = UIView()
		view.backgroundColor = themeProvider.currentTheme.tintColor.withAlphaComponent(0.2)
		cell.selectedBackgroundView = view

		return cell
	}
}

// MARK: - UITableViewDelegate
extension ServersListVC {
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let serverData = servers[indexPath.row]
		let shinobuServers = serversManager.getServersList()
		let tmp = shinobuServers.filter { $0.name == serverData.name }
		if tmp.count > 0 {
			showServerVC(with: tmp[0])
		}
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let action = UIContextualAction(style: .destructive, title: NYXLocalizedString("lbl_remove_from_playlist")) { [weak self] (_, _, completionHandler) in

			guard let strongSelf = self else { return }
			let serverData = strongSelf.servers[indexPath.row]
			if strongSelf.serversManager.removeServerByName(serverData.name) {
				strongSelf.refreshServers()
			}

			completionHandler(true)
		}
		action.image = #imageLiteral(resourceName: "btn-trash").withRenderingMode(.alwaysTemplate)

		return UISwipeActionsConfiguration(actions: [action])
	}
}

extension ServersListVC: Themed {
	func applyTheme(_ theme: Theme) {
	}
}
