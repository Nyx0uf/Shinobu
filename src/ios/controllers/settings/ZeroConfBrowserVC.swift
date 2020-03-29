import UIKit

protocol ZeroConfBrowserVCDelegate: class {
	func audioServerDidChange(with server: ShinobuServer)
}

final class ZeroConfBrowserVC: NYXTableViewController {
	// MARK: - Public properties
	// Delegate
	weak var delegate: ZeroConfBrowserVCDelegate?
	// Currently selected server on the ServerAddVC
	var selectedServer: ShinobuServer?

	// MARK: - Private properties
	// Zeroconf explorer
	private var zeroConfExplorer = ZeroConfExplorer()
	// List of servers found
	private var servers = [ShinobuServer]()

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.titleView = nil
		title = NYXLocalizedString("lbl_header_servers_zeroconf")
		navigationController?.navigationBar.prefersLargeTitles = true

		tableView.tintColor = themeProvider.currentTheme.tintColor
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.separatorColor = .separator
		tableView.rowHeight = 64
		tableView.tableFooterView = UIView()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		zeroConfExplorer.delegate = self
		zeroConfExplorer.searchForServices(type: "_mpd._tcp.")
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		zeroConfExplorer.delegate = nil
		zeroConfExplorer.stopSearch()
	}

	// MARK: - Private
	private func handleEmptyView(tableView: UITableView, isEmpty: Bool) {
		if isEmpty {
			let emptyView = UIView(frame: CGRect(x: tableView.center.x, y: tableView.center.y, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
			emptyView.backgroundColor = tableView.backgroundColor

			let lbl = UILabel(frame: .zero)
			lbl.text = NYXLocalizedString("lbl_no_zc_servers")
			lbl.font = UIFont.systemFont(ofSize: 32, weight: .ultraLight)
			lbl.translatesAutoresizingMaskIntoConstraints = false
			lbl.tintColor = .label
			lbl.sizeToFit()
			emptyView.addSubview(lbl)
			lbl.x = (emptyView.width - lbl.width) / 2
			lbl.y = (emptyView.height - lbl.height) / 2

			tableView.backgroundView = emptyView
			tableView.separatorStyle = .none
		} else {
			tableView.backgroundView = nil
			tableView.separatorStyle = .singleLine
		}
	}
}

// MARK: - UITableViewDataSource
extension ZeroConfBrowserVC {
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		handleEmptyView(tableView: tableView, isEmpty: servers.isEmpty)
		return servers.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "fr.whine.shinobu.cell.zeroconf")

		let server = servers[indexPath.row]
		cell.textLabel?.text = server.name
		cell.textLabel?.textColor = .label
		cell.textLabel?.highlightedTextColor = themeProvider.currentTheme.tintColor
		cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
		cell.detailTextLabel?.text = server.mpd.hostname + ":" + String(server.mpd.port)
		cell.detailTextLabel?.textColor = .secondaryLabel
		cell.detailTextLabel?.highlightedTextColor = themeProvider.currentTheme.tintColor.withAlphaComponent(0.5)

		if let currentServer = selectedServer {
			if currentServer == server {
				cell.accessoryType = .checkmark
			} else {
				cell.accessoryType = .none
			}
		} else {
			cell.accessoryType = .none
		}

		let v = UIView()
		v.backgroundColor = themeProvider.currentTheme.tintColor.withAlphaComponent(0.2)
		cell.selectedBackgroundView = v

		return cell
	}
}

// MARK: - UITableViewDelegate
extension ZeroConfBrowserVC {
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Check if same server
		let selected = servers[indexPath.row]
		if let currentServer = selectedServer {
			if selected == currentServer {
				return
			}
		}

		// Different server, update
		selectedServer = selected

		delegate?.audioServerDidChange(with: selected)
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
			tableView.reloadData()
		})
	}
}

extension ZeroConfBrowserVC: ZeroConfExplorerDelegate {
	internal func didFindServer(_ server: ShinobuServer) {
		servers = zeroConfExplorer.services.map { $0.value }
		tableView.reloadData()
		// Navigation bar title
		self.title = "\(servers.count) \(NYXLocalizedString(servers.count == 1 ? "lbl_header_server_zeroconf" : "lbl_header_servers_zeroconf"))"
	}
}

extension ZeroConfBrowserVC: Themed {
	func applyTheme(_ theme: Theme) {
	}
}
