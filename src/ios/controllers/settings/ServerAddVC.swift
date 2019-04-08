import UIKit


private let headerSectionHeight: CGFloat = 32


final class ServerAddVC: NYXTableViewController
{
	// MARK: - Private properties
	// MPD Server name
	private var tfMPDName: UITextField!
	// MPD Server hostname
	private var tfMPDHostname: UITextField!
	// MPD Server port
	private var tfMPDPort: UITextField!
	// MPD Server password
	private var tfMPDPassword: UITextField!
	// MPD Output
	private var lblMPDOutput: UILabel!
	// WEB Server hostname
	private var tfWEBHostname: UITextField!
	// WEB Server port
	private var tfWEBPort: UITextField!
	// Cover name
	private var tfWEBCoverName: UITextField!
	// MPD Server
	public var selectedServer: ShinobuServer?
	// Indicate that the keyboard is visible, flag
	private var keyboardVisible = false
	// Zero conf VC
	private var zeroConfVC: ZeroConfBrowserVC?
	// Cache size
	private var cacheSize: Int = 0
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

		// Navigation bar title
		titleView.setMainText(NYXLocalizedString("lbl_header_server_cfg"), detailText: nil)

		let search = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-search"), style: .plain, target: self, action: #selector(browserZeroConfAction(_:)))
		search.accessibilityLabel = NYXLocalizedString("lbl_search_zeroconf")
		let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(validateSettingsAction(_:)))
		navigationItem.rightBarButtonItems = [save, search]

		tfMPDName = UITextField()
		tfMPDName.translatesAutoresizingMaskIntoConstraints = false
		tfMPDName.textAlignment = .left
		tfMPDName.textColor = UITableView.colorActionItem
		tfMPDName.backgroundColor = UITableView.colorCellBackground
		tfMPDName.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfMPDName.attributedPlaceholder = NSAttributedString(string: NYXLocalizedString("lbl_server_defaultname"), attributes: [NSAttributedString.Key.foregroundColor: Colors.placeholderText])

		tfMPDHostname = UITextField()
		tfMPDHostname.translatesAutoresizingMaskIntoConstraints = false
		tfMPDHostname.textAlignment = .right
		tfMPDHostname.textColor = UITableView.colorActionItem
		tfMPDHostname.backgroundColor = UITableView.colorCellBackground
		tfMPDHostname.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfMPDHostname.attributedPlaceholder = NSAttributedString(string: "mpd.local", attributes: [NSAttributedString.Key.foregroundColor: Colors.placeholderText])

		tfMPDPort = UITextField()
		tfMPDPort.translatesAutoresizingMaskIntoConstraints = false
		tfMPDPort.textAlignment = .right
		tfMPDPort.textColor = UITableView.colorActionItem
		tfMPDPort.backgroundColor = UITableView.colorCellBackground
		tfMPDPort.text = "6600"
		tfMPDPort.keyboardType = .decimalPad
		tfMPDPort.font = UIFont.systemFont(ofSize: 17, weight: .semibold)

		tfMPDPassword = UITextField()
		tfMPDPassword.translatesAutoresizingMaskIntoConstraints = false
		tfMPDPassword.textAlignment = .right
		tfMPDPassword.textColor = UITableView.colorActionItem
		tfMPDPassword.backgroundColor = UITableView.colorCellBackground
		tfMPDPassword.isSecureTextEntry = true
		tfMPDPassword.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfMPDPassword.attributedPlaceholder = NSAttributedString(string: NYXLocalizedString("lbl_optional"), attributes: [NSAttributedString.Key.foregroundColor: Colors.placeholderText])

		tfWEBHostname = UITextField()
		tfWEBHostname.translatesAutoresizingMaskIntoConstraints = false
		tfWEBHostname.textAlignment = .right
		tfWEBHostname.textColor = UITableView.colorActionItem
		tfWEBHostname.backgroundColor = UITableView.colorCellBackground
		tfWEBHostname.autocapitalizationType = .none
		tfWEBHostname.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfWEBHostname.attributedPlaceholder = NSAttributedString(string: "http://mpd.local", attributes: [NSAttributedString.Key.foregroundColor: Colors.placeholderText])

		tfWEBPort = UITextField()
		tfWEBPort.translatesAutoresizingMaskIntoConstraints = false
		tfWEBPort.textAlignment = .right
		tfWEBPort.textColor = UITableView.colorActionItem
		tfWEBPort.backgroundColor = UITableView.colorCellBackground
		tfWEBPort.text = "80"
		tfWEBPort.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfWEBPort.keyboardType = .decimalPad

		tfWEBCoverName = UITextField()
		tfWEBCoverName.translatesAutoresizingMaskIntoConstraints = false
		tfWEBCoverName.textAlignment = .right
		tfWEBCoverName.textColor = UITableView.colorActionItem
		tfWEBCoverName.backgroundColor = UITableView.colorCellBackground
		tfWEBCoverName.autocapitalizationType = .none
		tfWEBCoverName.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfWEBCoverName.text = "cover.jpg"

		lblMPDOutput = UILabel()
		lblMPDOutput.translatesAutoresizingMaskIntoConstraints = false
		lblMPDOutput.textAlignment = .right
		lblMPDOutput.textColor = UITableView.colorActionItem
		lblMPDOutput.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		lblMPDOutput.backgroundColor = UITableView.colorCellBackground

		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.separatorColor = UITableView.colorSeparator
		tableView.backgroundColor = UITableView.colorBackground

		// Keyboard appearance notifications
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShowNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHideNotification(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(audioOutputConfigurationDidChangeNotification(_:)), name: .audioOutputConfigurationDidChange, object: nil)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		updateFields()
	}

	// MARK: - Buttons actions
	@objc func validateSettingsAction(_ sender: Any?)
	{
		view.endEditing(true)

		// Check server name
		guard let serverName = tfMPDName.text , serverName.count > 0 else
		{
			let alertController = NYXAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_servercfg_error_host"), preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			present(alertController, animated: true, completion: nil)
			return
		}

		// Check MPD hostname / ip
		guard let ip = tfMPDHostname.text , ip.count > 0 else
		{
			let alertController = NYXAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_servercfg_error_host"), preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			present(alertController, animated: true, completion: nil)
			return
		}

		// Check MPD port
		var port = UInt16(6600)
		if let strPort = tfMPDPort.text, let p = UInt16(strPort)
		{
			port = p
		}

		// Check MPD password (optional)
		var password = ""
		if let strPassword = tfMPDPassword.text , strPassword.count > 0
		{
			password = strPassword
		}

		let mpdServer = MPDServer(hostname: ip, port: port, password: password)
		let cnn = MPDConnection(mpdServer)
		let result = cnn.connect()
		switch result
		{
		case .failure( _):
			break
		case .success( _):
			if let _ = selectedServer
			{
				selectedServer?.mpd = mpdServer
				if selectedServer?.name != serverName
				{
					selectedServer?.name = serverName
				}
			}
			else
			{
				selectedServer = ShinobuServer(name: serverName, mpd: mpdServer)
			}

			serversManager.handleServer(selectedServer!)
			cnn.disconnect()

			updateOutputsLabel()
		}

		// Check web URL (optional)
		if let strURL = tfWEBHostname.text , String.isNullOrWhiteSpace(strURL) == false
		{
			var port = UInt16(80)
			if let strPort = tfWEBPort.text, let p = UInt16(strPort)
			{
				port = p
			}

			var coverName = "cover.jpg"
			if let cn = tfWEBCoverName.text , String.isNullOrWhiteSpace(cn) == false
			{
				if String.isNullOrWhiteSpace(URL(fileURLWithPath: cn).pathExtension) == false
				{
					coverName = cn
				}
			}
			let webServer = CoverServer(hostname: strURL, port: port, coverName: coverName)
			selectedServer?.covers = webServer

			if selectedServer != nil
			{
				serversManager.handleServer(selectedServer!)
			}
			else
			{
				let alertController = NYXAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_servercfg_error_host"), preferredStyle: .alert)
				let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel) { (action) in
				}
				alertController.addAction(cancelAction)
				present(alertController, animated: true, completion: nil)
				return
			}
		}
		else
		{
			if selectedServer != nil
			{
				selectedServer?.covers = nil
				serversManager.handleServer(selectedServer!)
			}
		}
	}

	@objc func browserZeroConfAction(_ sender: Any?)
	{
		if zeroConfVC == nil
		{
			zeroConfVC = ZeroConfBrowserVC()
		}
		zeroConfVC?.delegate = self
		zeroConfVC?.selectedServer = selectedServer
		let nvc = NYXNavigationController(rootViewController: zeroConfVC!)
		navigationController?.present(nvc, animated: true, completion: nil)
	}

	// MARK: - Notifications
	@objc func keyboardDidShowNotification(_ aNotification: Notification)
	{
		if keyboardVisible
		{
			return
		}

		guard let info = aNotification.userInfo else
		{
			return
		}

		guard let value = info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue? else
		{
			return
		}

		let keyboardFrame = view.convert(value.cgRectValue, from: nil)
		tableView.frame = CGRect(tableView.frame.origin, tableView.frame.width, tableView.frame.height - keyboardFrame.height)
		keyboardVisible = true
	}

	@objc func keyboardDidHideNotification(_ aNotification: Notification)
	{
		if keyboardVisible == false
		{
			return
		}

		guard let info = aNotification.userInfo else
		{
			return
		}

		guard let value = info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue? else
		{
			return
		}

		let keyboardFrame = view.convert(value.cgRectValue, from: nil)
		tableView.frame = CGRect(tableView.frame.origin, tableView.frame.width, tableView.frame.height + keyboardFrame.height)
		keyboardVisible = false
	}

	@objc func audioOutputConfigurationDidChangeNotification(_ aNotification: Notification)
	{
		updateOutputsLabel()
	}

	// MARK: - Private
	private func updateFields()
	{
		if let server = selectedServer
		{
			tfMPDName.text = server.name
			tfMPDHostname.text = server.mpd.hostname
			tfMPDPort.text = String(server.mpd.port)
			tfMPDPassword.text = server.mpd.password

			tfWEBHostname.text = server.covers?.hostname ?? server.mpd.hostname
			tfWEBPort.text = String(server.covers?.port ?? 80)
			tfWEBCoverName.text = server.covers?.coverName ?? "cover.jpg"

			updateOutputsLabel()
		}
		else
		{
			tfMPDName.text = ""
			tfMPDHostname.text = ""
			tfMPDPort.text = "6600"
			tfMPDPassword.text = ""
			lblMPDOutput.text = ""

			tfWEBHostname.text = ""
			tfWEBPort.text = "80"
			tfWEBCoverName.text = "cover.jpg"
		}

		updateCacheLabel()
	}

	private func clearCache(confirm: Bool)
	{
		let clearBlock = { () -> Void in
			let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
			let coversDirectoryName = Settings.shared.string(forKey: .coversDirectory)!
			let coversDirectoryURL = cachesDirectoryURL.appendingPathComponent(coversDirectoryName)

			do
			{
				try FileManager.default.removeItem(at: coversDirectoryURL)
				try FileManager.default.createDirectory(at: coversDirectoryURL, withIntermediateDirectories: true, attributes: nil)
				URLCache.shared.removeAllCachedResponses()
			}
			catch _
			{
				Logger.shared.log(type: .error, message: "Can't delete cover cache")
			}
			self.updateCacheLabel()
		}

		if confirm
		{
			let alertController = NYXAlertController(title: NYXLocalizedString("lbl_alert_purge_cache_title"), message:NYXLocalizedString("lbl_alert_purge_cache_msg"), preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive) { (action) in
				clearBlock()
			}
			alertController.addAction(okAction)
			present(alertController, animated: true, completion: nil)
		}
		else
		{
			clearBlock()
		}
	}

	private func updateCacheLabel()
	{
		guard let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else { return }
		DispatchQueue.global().async {
			let size = FileManager.default.sizeOfDirectoryAtURL(cachesDirectoryURL)
			DispatchQueue.main.async {
				self.cacheSize = size
				self.tableView.reloadRows(at: [IndexPath(row: 3, section: 2)], with: .none)
			}
		}
	}

	private func updateOutputsLabel()
	{
		guard let _ = selectedServer else { return }

		let cnn = MPDConnection(selectedServer!.mpd)
		let result = cnn.connect()
		switch result
		{
			case .failure( _):
				break
			case .success( _):
				let r = cnn.getAvailableOutputs()
				switch r
				{
					case .failure( _):
						break
					case .success(let outputs):
						if outputs.count == 0
						{
							lblMPDOutput.text = NYXLocalizedString("lbl_server_no_output_available")
							return
						}
						let enabledOutputs = outputs.filter { $0.enabled }
						if enabledOutputs.count == 0
						{
							lblMPDOutput.text = NYXLocalizedString("lbl_server_no_output_enabled")
							return
						}
						let text = enabledOutputs.reduce("", { $0 + $1.name + ", " })
						let x = text[..<text.index(text.endIndex, offsetBy: -2)]
						lblMPDOutput.text = String(x)
				}
				cnn.disconnect()
		}
	}
}

// MARK: - ZeroConfBrowserVCDelegate
extension ServerAddVC: ZeroConfBrowserVCDelegate
{
	func audioServerDidChange(with server: ShinobuServer)
	{
		clearCache(confirm: false)
		selectedServer = server
	}
}

// MARK: - UITableViewDataSource
extension ServerAddVC
{
	override func numberOfSections(in tableView: UITableView) -> Int
	{
		return 3
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		switch section
		{
			case 0:
				return 1
			case 1:
				return 5
			case 2:
				return 4
			default:
				return 0
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cellIdentifier = "\(indexPath.section):\(indexPath.row)"
		var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
		if cell == nil
		{
			cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
			cell?.textLabel?.textColor = UITableView.colorMainText
			cell?.backgroundColor = UITableView.colorCellBackground

			if indexPath.section == 0
			{
				if indexPath.row == 0
				{
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(tfMPDName)
					tfMPDName.frame = CGRect(16, 0, UIScreen.main.bounds.width - 32, 44)
				}
			}
			else if indexPath.section == 1
			{
				if indexPath.row == 0
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_host")
					cell?.selectionStyle = .none
					cell?.addSubview(tfMPDHostname)
					tfMPDHostname.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				}
				else if indexPath.row == 1
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_port")
					cell?.selectionStyle = .none
					cell?.addSubview(tfMPDPort)
					tfMPDPort.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				}
				else if indexPath.row == 2
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_password")
					cell?.selectionStyle = .none
					cell?.addSubview(tfMPDPassword)
					tfMPDPassword.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				}
				else if indexPath.row == 3
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_output")
					cell?.selectionStyle = .none
					cell?.addSubview(lblMPDOutput)
					lblMPDOutput.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				}
				else if indexPath.row == 4
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_update_db")
					cell?.textLabel?.textAlignment = .center
					cell?.textLabel?.textColor = UITableView.colorActionItem
					cell?.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .black)
					let backgroundView = UIView()
					backgroundView.backgroundColor = Colors.backgroundSelected
					cell?.selectedBackgroundView = backgroundView
				}
			}
			else
			{
				if indexPath.row == 0
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_host")
					cell?.selectionStyle = .none
					cell?.addSubview(tfWEBHostname)
					tfWEBHostname.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				}
				else if indexPath.row == 1
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_port")
					cell?.selectionStyle = .none
					cell?.addSubview(tfWEBPort)
					tfWEBPort.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				}
				else if indexPath.row == 2
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_covername")
					cell?.selectionStyle = .none
					cell?.addSubview(tfWEBCoverName)
					tfWEBCoverName.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				}
				else if indexPath.row == 3
				{
					cell?.textLabel?.text = "\(NYXLocalizedString("lbl_server_coverclearcache")) (\(String(format: "%.2f", Double(cacheSize) / 1048576))\(NYXLocalizedString("lbl_megabytes")))"
					cell?.textLabel?.textAlignment = .center
					cell?.textLabel?.textColor = UITableView.colorActionItem
					cell?.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .black)
					let backgroundView = UIView()
					backgroundView.backgroundColor = Colors.backgroundSelected
					cell?.selectedBackgroundView = backgroundView
				}
			}
		}

		if indexPath.section == 0
		{
			if indexPath.row == 0
			{
				tfMPDName.frame = CGRect(16, 0, UIScreen.main.bounds.width - 32, 44)
			}
		}
		else if indexPath.section == 1
		{
			if indexPath.row == 0
			{
				tfMPDHostname.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			}
			else if indexPath.row == 1
			{
				tfMPDPort.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			}
			else if indexPath.row == 2
			{
				tfMPDPassword.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			}
			else if indexPath.row == 3
			{
				lblMPDOutput.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			}
		}
		else
		{
			if indexPath.row == 0
			{
				tfWEBHostname.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			}
			else if indexPath.row == 1
			{
				tfWEBPort.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			}
			else if indexPath.row == 2
			{
				tfWEBCoverName.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			}
		}

		return cell!
	}
}

// MARK: - UITableViewDelegate
extension ServerAddVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		if indexPath.section == 1 && indexPath.row == 3
		{
			guard let cell = tableView.cellForRow(at: indexPath) else
			{
				return
			}

			guard let server = selectedServer else { return }

			let vc = AudioOutputsListVC(mpdServer: server.mpd)
			vc.modalPresentationStyle = .popover
			if let popController = vc.popoverPresentationController
			{
				popController.permittedArrowDirections = .up
				popController.sourceRect = cell.bounds
				popController.sourceView = cell
				popController.delegate = self
				popController.backgroundColor = Colors.backgroundAlt
				present(vc, animated: true, completion: nil)
			}
		}
		else if indexPath.section == 1 && indexPath.row == 4
		{
			mpdBridge.updateDatabase() { succeeded in
				DispatchQueue.main.async {
					if succeeded == false
					{
						MessageView.shared.showWithMessage(message: Message(content: NYXLocalizedString("lbl_alert_update_mpd_failed"), type: .error))
					}
					else
					{
						MessageView.shared.showWithMessage(message: Message(content: NYXLocalizedString("lbl_alert_update_mpd_succeeded"), type: .success))
					}
				}
			}
		}
		else if indexPath.section == 2 && indexPath.row == 3
		{
			clearCache(confirm: true)
		}
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
	{
		let dummy = UIView(frame: CGRect(0, 0, tableView.width, headerSectionHeight))
		dummy.backgroundColor = tableView.backgroundColor

		let label = UILabel(frame: CGRect(10, 0, dummy.width - 20, dummy.height))
		label.backgroundColor = dummy.backgroundColor
		label.textColor = UITableView.colorHeaderTitle
		label.font = UIFont.systemFont(ofSize: 18, weight: .light)
		label.textAlignment = .center
		dummy.addSubview(label)

		if section == 0
		{
			label.text = NYXLocalizedString("lbl_server_name").uppercased()
		}
		else if section == 1
		{
			label.text = NYXLocalizedString("lbl_server_section_server").uppercased()
		}
		else
		{
			label.text = NYXLocalizedString("lbl_server_section_cover").uppercased()
		}

		return dummy
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	{
		return headerSectionHeight
	}

	override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
	{
		let dummy = UIView(frame: CGRect(0, 0, tableView.width, headerSectionHeight))
		dummy.backgroundColor = tableView.backgroundColor
		return dummy
	}

	override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
	{
		return headerSectionHeight
	}
}

// MARK: - UITextFieldDelegate
extension ServerAddVC: UITextFieldDelegate
{
	func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		if textField === tfMPDName
		{
			tfMPDHostname.becomeFirstResponder()
		}
		else if textField === tfMPDHostname
		{
			tfMPDPort.becomeFirstResponder()
		}
		else if textField === tfMPDPort
		{
			tfMPDPassword.becomeFirstResponder()
		}
		else if textField === tfMPDPassword
		{
			textField.resignFirstResponder()
		}
		else if textField === tfWEBHostname
		{
			tfWEBPort.becomeFirstResponder()
		}
		else if textField === tfWEBPort
		{
			tfWEBCoverName.becomeFirstResponder()
		}
		else
		{
			textField.resignFirstResponder()
		}
		return true
	}
}

// MARK: - UIPopoverPresentationControllerDelegate
extension ServerAddVC: UIPopoverPresentationControllerDelegate
{
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
	{
		return .none
	}
}
