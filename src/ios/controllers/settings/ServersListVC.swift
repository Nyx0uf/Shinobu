import UIKit

private struct ServerData {
	// Server name
	let name: String
	// Is this the active server?
	let isSelected: Bool
	// Index in tableView
	let index: Int
}

final class ServersListVC: NYXTableViewController {
	// MARK: - Private properties
	// List of servers
	private var servers = [ServerData]()
	// Tableview cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.server"
	// Add/Edit server VC
	private var addServerVC: ServerAddEditVC?
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

		// ServerData is like a DTO, index will map to the tableView indexPath.row
		servers.removeAll()
		var index = 0
		for server in serversList {
			servers.append(ServerData(name: server.name, isSelected: (server.name == enabledServerName), index: index))
			index += 1
		}
		tableView.reloadData()

		// Navigation bar title
		title = "\(servers.count) \(NYXLocalizedString(servers.count == 1 ? "lbl_header_server_list" : "lbl_header_servers_list"))"
	}

	private func showServerVC(with server: ShinobuServer?) {
		if addServerVC == nil {
			addServerVC = ServerAddEditVC(mpdBridge: mpdBridge)
		}

		if let avc = addServerVC {
			avc.selectedServer = server
			navigationController?.pushViewController(avc, animated: true)
		}
	}

	@objc private func toggleServer(_ sender: UISwitch!) {
		guard let swi = sender else { return }
		serversManager.setSelectedServerName(swi.isOn ? servers[swi.tag].name : "")

		if swi.isOn {
			createCacheDirectory(for: servers[swi.tag].name)
		}

		// Do not reload tableView and animate the switches
		// Mutating array in iteration is probably a bad idea though
		for serverData in servers {
			let cell = tableView.cellForRow(at: IndexPath(row: serverData.index, section: 0)) as! ShinobuServerTableViewCell
			guard let toggle = cell.toggle else { continue }
			if swi.tag != toggle.tag && toggle.isOn {
				let s = ServerData(name: serverData.name, isSelected: false, index: serverData.index)
				servers[serverData.index] = s
				toggle.setOn(false, animated: true)
			}
		}

		NotificationCenter.default.postOnMainThreadAsync(name: .audioServerConfigurationDidChange, object: serversManager.getSelectedServer()?.mpd, userInfo: nil)
	}

	private func createCacheDirectory(for name: String) {
		do {
			guard let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else { return }

			let coversDirectoryName = "covers_\(name)"
			AppDefaults.coversDirectory = coversDirectoryName

			let coverDirectoryURL = cachesDirectoryURL.appendingPathComponent(coversDirectoryName)
			if FileManager.default.fileExists(atPath: coverDirectoryURL.path) == false {
				try FileManager.default.createDirectory(at: coverDirectoryURL, withIntermediateDirectories: true, attributes: nil)
			}
		} catch {
			fatalError("Failed to create covers directory")
		}
	}

	private func handleEmptyView(tableView: UITableView, isEmpty: Bool) {
		if isEmpty {
			let emptyView = UIView(frame: tableView.bounds)
			emptyView.translatesAutoresizingMaskIntoConstraints = false
			tableView.backgroundView = emptyView

			let btn = AwesomeButton(text: NYXLocalizedString("lbl_add_one"), font: UIFont.systemFont(ofSize: 32, weight: .ultraLight), symbolName: "plus.circle", symbolConfiguration: UIImage.SymbolConfiguration(pointSize: 64, weight: .ultraLight), imagePosition: .top)
			btn.translatesAutoresizingMaskIntoConstraints = false
			btn.tintColor = .label
			btn.selectedTintColor = themeProvider.currentTheme.tintColor
			btn.addTarget(self, action: #selector(addMpdServerAction(_:)), for: .touchUpInside)
			emptyView.addSubview(btn)
			btn.x = ceil((emptyView.width - btn.width) / 2)
			btn.y = ceil((emptyView.height - btn.height) / 2)

			emptyView.backgroundColor = tableView.backgroundColor
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
		cell.toggle.tag = server.index
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

		if let server = shinobuServers.first(where: { $0.name == serverData.name }) {
			showServerVC(with: server)
		}
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let action = UIContextualAction(style: .destructive, title: NYXLocalizedString("lbl_remove_from_playlist")) { [weak self] (_, _, completionHandler) in

			guard let strongSelf = self else { return }
			let serverData = strongSelf.servers[indexPath.row]
			if strongSelf.serversManager.removeServerByName(serverData.name) {
				strongSelf.servers.remove(at: serverData.index)
				tableView.deleteRows(at: [indexPath], with: .automatic)
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
