import UIKit


protocol ZeroConfBrowserTVCDelegate : class
{
	func audioServerDidChange()
}


final class ZeroConfBrowserTVC : UITableViewController
{
	// MARK: - Public properties
	// Delegate
	weak var delegate: ZeroConfBrowserTVCDelegate? = nil

	// MARK: - Private properties
	// Zeroconf explorer
	private var _explorer: ZeroConfExplorer! = nil
	// List of servers found
	private var _servers = [MPDServer]()
	//
	private let cellIdentifier = "fr.whine.shinobu.cell.zeroconf"

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		let save = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(done(_:)))
		self.navigationItem.leftBarButtonItem = save

		// Navigation bar title
		let titleView = UILabel(frame: CGRect(0.0, 0.0, 100.0, 44.0))
		titleView.font = UIFont(name: "HelveticaNeue-Medium", size: 14.0)
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = Colors.main
		titleView.text = NYXLocalizedString("lbl_header_server_zeroconf")
		navigationItem.titleView = titleView

		tableView.register(ZeroConfServerTableViewCell.classForCoder(), forCellReuseIdentifier: cellIdentifier)
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.separatorColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

		self._explorer = ZeroConfExplorer()
		self._explorer.delegate = self
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		self._explorer.searchForServices(type: "_mpd._tcp.")
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)
		self._explorer.stopSearch()
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	// MARK: - IBActions
	@objc private func done(_ sender: Any?)
	{
		self.dismiss(animated: true, completion: nil)
	}

	// MARK: - Private
	private func currentAudioServer() -> MPDServer?
	{
		if let serverAsData = Settings.shared.data(forKey: kNYXPrefMPDServer)
		{
			var server: MPDServer? = nil
			do
			{
				server = try JSONDecoder().decode(MPDServer.self, from: serverAsData)
			}
			catch
			{
				Logger.shared.log(type: .error, message: "Failed to decode mpd server")
			}
			return server
		}
		return nil
	}
}

// MARK: - UITableViewDataSource
extension ZeroConfBrowserTVC
{
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return _servers.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ZeroConfServerTableViewCell

		let server = _servers[indexPath.row]
		cell.lblName.text = server.name
		cell.lblHostname.text = server.hostname + ":" + String(server.port)
		if let currentServer = currentAudioServer()
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
		tableView.deselectRow(at: indexPath, animated: true)
		let selectedServer = _servers[indexPath.row]
		if let currentServer = currentAudioServer()
		{
			if selectedServer == currentServer
			{
				return
			}
		}

		// Different server, update
		do
		{
			let encoder = JSONEncoder()
			let mpdServer = MPDServer(name: selectedServer.name, hostname: selectedServer.hostname, port: selectedServer.port, password: "")
			let serverAsData = try encoder.encode(mpdServer)
			Settings.shared.set(serverAsData, forKey: kNYXPrefMPDServer)
			Settings.shared.synchronize()
		}
		catch let error
		{
			Logger.shared.log(type: .error, message: "Failed to encode mpd server: \(error.localizedDescription)")
			return
		}

		self.tableView.reloadData()
		delegate?.audioServerDidChange()
	}
}

extension ZeroConfBrowserTVC : ZeroConfExplorerDelegate
{
	internal func didFindServer(_ server: MPDServer)
	{
		_servers = _explorer.services.map({$0.value})
		self.tableView.reloadData()
	}
}
