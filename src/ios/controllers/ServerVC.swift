import UIKit


private let headerSectionHeight: CGFloat = 32.0


final class ServerVC : NYXTableViewController
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
	private var _keyboardVisible = false
	// Zero conf VC
	private var zeroConfVC: ZeroConfBrowserTVC!
	// Cache size
	private var cacheSize: Int = 0

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Navigation bar title
		titleView.text = NYXLocalizedString("lbl_header_server_cfg")
		
		let search = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-search"), style: .plain, target: self, action: #selector(browserZeroConfAction(_:)))
		search.accessibilityLabel = NYXLocalizedString("lbl_search_zeroconf")
		let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(validateSettingsAction(_:)))
		self.navigationItem.rightBarButtonItems = [save, search]

		tfMPDName = UITextField()
		tfMPDName.translatesAutoresizingMaskIntoConstraints = false
		tfMPDName.textAlignment = .left
		tfMPDName.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		tfMPDName.backgroundColor = Colors.background
		tfMPDName.attributedPlaceholder = NSAttributedString(string: NYXLocalizedString("lbl_server_defaultname"), attributes: [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)])

		tfMPDHostname = UITextField()
		tfMPDHostname.translatesAutoresizingMaskIntoConstraints = false
		tfMPDHostname.textAlignment = .right
		tfMPDHostname.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		tfMPDHostname.backgroundColor = Colors.background
		tfMPDHostname.attributedPlaceholder = NSAttributedString(string: "mpd.local", attributes: [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)])

		tfMPDPort = UITextField()
		tfMPDPort.translatesAutoresizingMaskIntoConstraints = false
		tfMPDPort.textAlignment = .right
		tfMPDPort.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		tfMPDPort.backgroundColor = Colors.background
		tfMPDPort.text = "6600"
		tfMPDPort.keyboardType = .decimalPad

		tfMPDPassword = UITextField()
		tfMPDPassword.translatesAutoresizingMaskIntoConstraints = false
		tfMPDPassword.textAlignment = .right
		tfMPDPassword.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		tfMPDPassword.backgroundColor = Colors.background
		tfMPDPassword.isSecureTextEntry = true
		tfMPDPassword.attributedPlaceholder = NSAttributedString(string: NYXLocalizedString("lbl_optional"), attributes: [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)])

		tfWEBHostname = UITextField()
		tfWEBHostname.translatesAutoresizingMaskIntoConstraints = false
		tfWEBHostname.textAlignment = .right
		tfWEBHostname.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		tfWEBHostname.backgroundColor = Colors.background
		tfWEBHostname.autocapitalizationType = .none
		tfWEBHostname.attributedPlaceholder = NSAttributedString(string: "http://mpd.local", attributes: [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)])

		tfWEBPort = UITextField()
		tfWEBPort.translatesAutoresizingMaskIntoConstraints = false
		tfWEBPort.textAlignment = .right
		tfWEBPort.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		tfWEBPort.backgroundColor = Colors.background
		tfWEBPort.text = "80"
		tfWEBPort.keyboardType = .decimalPad

		tfWEBCoverName = UITextField()
		tfWEBCoverName.translatesAutoresizingMaskIntoConstraints = false
		tfWEBCoverName.textAlignment = .right
		tfWEBCoverName.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		tfWEBCoverName.backgroundColor = Colors.background
		tfWEBCoverName.autocapitalizationType = .none
		tfWEBCoverName.attributedPlaceholder = NSAttributedString(string: "cover.jpg", attributes: [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)])

		lblMPDOutput = UILabel()
		lblMPDOutput.translatesAutoresizingMaskIntoConstraints = false
		lblMPDOutput.textAlignment = .right
		lblMPDOutput.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		lblMPDOutput.backgroundColor = Colors.background

		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.separatorColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		tableView.tableFooterView = UIView()

		// Keyboard appearance notifications
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShowNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHideNotification(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
		//NotificationCenter.default.addObserver(self, selector: #selector(audioOutputConfigurationDidChangeNotification(_:)), name: .audioOutputConfigurationDidChange, object: nil)
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
		if cnn.connect().succeeded
		{
			if let _ = self.selectedServer
			{
				self.selectedServer?.mpd = mpdServer
				if self.selectedServer?.name != serverName
				{
					self.selectedServer?.name = serverName
				}
			}
			else
			{
				self.selectedServer = ShinobuServer(name: serverName, mpd: mpdServer)
			}

			ServersManager.shared.handleServer(self.selectedServer!)
		}
		cnn.disconnect()

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

			ServersManager.shared.handleServer(selectedServer!)
		}
		else
		{
			selectedServer?.covers = nil
			ServersManager.shared.handleServer(selectedServer!)
		}
	}

	@objc func browserZeroConfAction(_ sender: Any?)
	{
		if zeroConfVC == nil
		{
			zeroConfVC = ZeroConfBrowserTVC()
		}
		zeroConfVC.delegate = self
		zeroConfVC.selectedServer = selectedServer
		let nvc = NYXNavigationController(rootViewController: zeroConfVC)
		self.navigationController?.present(nvc, animated: true, completion: nil)
	}

	// MARK: - Notifications
	@objc func keyboardDidShowNotification(_ aNotification: Notification)
	{
		if _keyboardVisible
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
		_keyboardVisible = true
	}

	@objc func keyboardDidHideNotification(_ aNotification: Notification)
	{
		if _keyboardVisible == false
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
		_keyboardVisible = false
	}

	/*@objc func audioOutputConfigurationDidChangeNotification(_ aNotification: Notification)
	{
		updateOutputsLabel()
	}*/

	// MARK: - Private
	private func updateFields()
	{
		if let server = selectedServer
		{
			tfMPDName.text = server.name
			tfMPDHostname.text = server.mpd.hostname
			tfMPDPort.text = String(server.mpd.port)
			tfMPDPassword.text = server.mpd.password

			tfWEBHostname.text = server.covers?.hostname ?? ""
			tfWEBPort.text = String(server.covers?.port ?? 80)
			tfWEBCoverName.text = server.covers?.coverName ?? ""

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
			let coversDirectoryName = Settings.shared.string(forKey: kNYXPrefCoversDirectory)!
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
		guard let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else {return}
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
		PlayerController.shared.getAvailableOutputs {
			DispatchQueue.main.async {
				let outputs = PlayerController.shared.outputs
				if outputs.count == 0
				{
					self.lblMPDOutput.text = NYXLocalizedString("lbl_server_no_output_available")
					return
				}
				let enabledOutputs = outputs.filter({$0.enabled})
				if enabledOutputs.count == 0
				{
					self.lblMPDOutput.text = NYXLocalizedString("lbl_server_no_output_enabled")
					return
				}
				let text = enabledOutputs.reduce("", {$0 + $1.name + ", "})
				let x = text[..<text.index(text.endIndex, offsetBy: -2)]
				self.lblMPDOutput.text = String(x)
			}
		}
	}
}

// MARK: - 
extension ServerVC : ZeroConfBrowserTVCDelegate
{
	func audioServerDidChange(with server: ShinobuServer)
	{
		clearCache(confirm: false)
		self.selectedServer = server
	}
}

// MARK: - UITableViewDataSource
extension ServerVC
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
				return 2
			case 1:
				return 6
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
			cell?.textLabel?.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
			cell?.backgroundColor = Colors.background

			if indexPath.section == 0
			{
				if indexPath.row == 0
				{
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(tfMPDName)
					tfMPDName.frame = CGRect(16.0, 0, UIScreen.main.bounds.width - 32.0, 44.0)
				}
				else if indexPath.row == 1
				{
					// Dummy
					cell?.selectionStyle = .none
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
					cell?.textLabel?.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
					cell?.textLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
					let backgroundView = UIView()
					backgroundView.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
					cell?.selectedBackgroundView = backgroundView
				}
				else if indexPath.row == 5
				{
					// Dummy
					cell?.selectionStyle = .none
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
					cell?.textLabel?.text = "\(NYXLocalizedString("lbl_server_coverclearcache")) (\(String(format: "%.2f", Double(cacheSize) / 1048576.0))\(NYXLocalizedString("lbl_megabytes")))"
					cell?.textLabel?.textAlignment = .center
					cell?.textLabel?.textColor = #colorLiteral(red: 0.5807225108, green: 0.066734083, blue: 0, alpha: 1)
					cell?.textLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
					let backgroundView = UIView()
					backgroundView.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
					cell?.selectedBackgroundView = backgroundView
				}
			}
		}

		if indexPath.section == 0
		{
			if indexPath.row == 0
			{
				tfMPDName.frame = CGRect(16.0, 0, UIScreen.main.bounds.width - 32.0, 44.0)
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
extension ServerVC
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

			let vc = AudioOutputsTVC()
			vc.modalPresentationStyle = .popover
			if let popController = vc.popoverPresentationController
			{
				popController.permittedArrowDirections = .up
				popController.sourceRect = cell.bounds
				popController.sourceView = cell
				popController.delegate = self
				self.present(vc, animated: true, completion: {
				});
			}
		}
		else if indexPath.section == 1 && indexPath.row == 4
		{
			MusicDataSource.shared.updateDatabase() { succeeded in
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
		let dummy = UIView(frame: CGRect(0.0, 0.0, tableView.width, headerSectionHeight))
		dummy.backgroundColor = tableView.backgroundColor

		let label = UILabel(frame: CGRect(10.0, 0.0, dummy.width - 20.0, dummy.height))
		label.backgroundColor = dummy.backgroundColor
		label.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		label.font = UIFont.systemFont(ofSize: 18.0, weight: .black)
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
}

// MARK: - UITextFieldDelegate
extension ServerVC : UITextFieldDelegate
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

// MARK: - 
extension ServerVC : UIPopoverPresentationControllerDelegate
{
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
	{
		return .none
	}
}
