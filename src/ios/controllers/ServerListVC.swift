import UIKit


final class ServerListTVC : UITableViewController, CenterViewController
{
	// MARK: - Public properties
	// List of MPD servers
	var servers = [Server]()
	// Delegate
	var containerDelegate: ContainerVCDelegate? = nil

	// MARK: - Private properties
	// Tableview cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.mpdserver"
	// Navigation title
	private var titleView: UILabel!
	//
	private var addServerVC: ServerVC? = nil
	
	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		// Navigation bar title
		titleView = UILabel(frame: CGRect(0.0, 0.0, 100.0, 44.0))
		titleView.font = UIFont(name: "HelveticaNeue-Medium", size: 14.0)
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = Colors.main
		titleView.text = NYXLocalizedString("lbl_header_server_list")
		navigationItem.titleView = titleView

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-hamb"), style: .plain, target: self, action: #selector(showLeftViewAction(_:)))
		let add = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-add"), style: .plain, target: self, action: #selector(addMpdServerAction(_:)))
		self.navigationItem.rightBarButtonItem = add
		
		tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: cellIdentifier)
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.separatorColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		tableView.rowHeight = 64
	}
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		refreshServers()
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	// MARK: - Buttons actions
	@objc func showLeftViewAction(_ sender: Any?)
	{
		containerDelegate?.toggleMenu()
	}

	@objc func addMpdServerAction(_ sender: Any?)
	{
		if addServerVC == nil
		{
			addServerVC = ServerVC()
		}

		if let vc = addServerVC
		{
			navigationController?.pushViewController(vc, animated: true)
		}
	}
	
	// MARK: - Private
	private func refreshServers()
	{
		let decoder = JSONDecoder()
		if let serversAsData = Settings.shared.data(forKey: Settings.keys.servers)
		{
			do
			{
				let servers = try decoder.decode([Server].self, from: serversAsData)
				self.servers = servers
			}
			catch let error
			{
				Logger.shared.log(type: .debug, message: "Failed to decode servers: \(error.localizedDescription)")
			}
		}
		else
		{
			Logger.shared.log(type: .debug, message: "No servers registered yet")
		}
	}
}

// MARK: - UITableViewDataSource
extension ServerListTVC
{
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return servers.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
		
		let server = servers[indexPath.row]
		
		cell.textLabel?.text = server.mpd.name
		//cell.accessoryType = output.enabled ? .checkmark : .none
		cell.textLabel?.isAccessibilityElement = false
		//cell.accessibilityLabel = "\(server.name) \(NYXLocalizedString("lbl_is")) \(NYXLocalizedString(output.enabled ? "lbl_enabled" : "lbl_disabled"))"
		
		return cell
	}
}

// MARK: - UITableViewDelegate
extension ServerListTVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})
		
		//let server = servers[indexPath.row]
	}
}
