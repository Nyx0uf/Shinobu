import UIKit

private let headerSectionHeight: CGFloat = 32

final class ServerAddEditVC: NYXTableViewController {
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
	init(mpdBridge: MPDBridge) {
		self.mpdBridge = mpdBridge
		self.serversManager = ServersManager()

		super.init(style: .grouped)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.titleView = nil
		title = NYXLocalizedString("lbl_header_server_cfg")

		// Remove back button label
		navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "btn-back")
		navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "btn-back")
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		let search = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-search"), style: .plain, target: self, action: #selector(browserZeroConfAction(_:)))
		search.accessibilityLabel = NYXLocalizedString("lbl_search_zeroconf")
		navigationItem.rightBarButtonItem = search

		tfMPDName = UITextField()
		tfMPDName.translatesAutoresizingMaskIntoConstraints = false
		tfMPDName.textAlignment = .left
		tfMPDName.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfMPDName.tintColor = themeProvider.currentTheme.tintColor
		tfMPDName.placeholder = NYXLocalizedString("lbl_server_defaultname")

		tfMPDHostname = UITextField()
		tfMPDHostname.translatesAutoresizingMaskIntoConstraints = false
		tfMPDHostname.textAlignment = .right
		tfMPDHostname.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfMPDHostname.tintColor = themeProvider.currentTheme.tintColor
		tfMPDHostname.placeholder = "mpd.local"

		tfMPDPort = UITextField()
		tfMPDPort.translatesAutoresizingMaskIntoConstraints = false
		tfMPDPort.textAlignment = .right
		tfMPDPort.text = "6600"
		tfMPDPort.keyboardType = .decimalPad
		tfMPDPort.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfMPDPort.tintColor = themeProvider.currentTheme.tintColor

		tfMPDPassword = UITextField()
		tfMPDPassword.translatesAutoresizingMaskIntoConstraints = false
		tfMPDPassword.textAlignment = .right
		tfMPDPassword.isSecureTextEntry = true
		tfMPDPassword.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfMPDPassword.tintColor = themeProvider.currentTheme.tintColor
		tfMPDPassword.placeholder = NYXLocalizedString("lbl_optional")

		tfWEBHostname = UITextField()
		tfWEBHostname.translatesAutoresizingMaskIntoConstraints = false
		tfWEBHostname.textAlignment = .right
		tfWEBHostname.autocapitalizationType = .none
		tfWEBHostname.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfWEBHostname.tintColor = themeProvider.currentTheme.tintColor
		tfWEBHostname.placeholder = "http://mpd.local"

		tfWEBPort = UITextField()
		tfWEBPort.translatesAutoresizingMaskIntoConstraints = false
		tfWEBPort.textAlignment = .right
		tfWEBPort.text = "80"
		tfWEBPort.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfWEBPort.keyboardType = .decimalPad
		tfWEBPort.tintColor = themeProvider.currentTheme.tintColor

		tfWEBCoverName = UITextField()
		tfWEBCoverName.translatesAutoresizingMaskIntoConstraints = false
		tfWEBCoverName.textAlignment = .right
		tfWEBCoverName.autocapitalizationType = .none
		tfWEBCoverName.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfWEBCoverName.text = "cover.jpg"
		tfWEBCoverName.tintColor = themeProvider.currentTheme.tintColor

		lblMPDOutput = UILabel()
		lblMPDOutput.translatesAutoresizingMaskIntoConstraints = false
		lblMPDOutput.textAlignment = .right
		lblMPDOutput.font = UIFont.systemFont(ofSize: 17, weight: .semibold)

		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

		// Keyboard appearance notifications
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShowNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHideNotification(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(audioOutputConfigurationDidChangeNotification(_:)), name: .audioOutputConfigurationDidChange, object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		updateFields()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if isMovingFromParent {
			validateSettingsAction(nil)
		}
	}

	// MARK: - Buttons actions
	@objc private func validateSettingsAction(_ sender: Any?) {
		view.endEditing(true)

		// Check server name
		guard let serverName = tfMPDName.text, serverName.count > 0 else {
			let alertController = NYXAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message: NYXLocalizedString("lbl_alert_servercfg_error_name"), preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel)
			alertController.addAction(cancelAction)
			navigationController?.present(alertController, animated: true, completion: nil)
			return
		}

		// Check MPD hostname / ip
		guard let ipa = tfMPDHostname.text, ipa.count > 0 else {
			let alertController = NYXAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message: NYXLocalizedString("lbl_alert_servercfg_error_host"), preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel)
			alertController.addAction(cancelAction)
			navigationController?.present(alertController, animated: true, completion: nil)
			return
		}

		// Check MPD port
		var port = UInt16(6600)
		if let strPort = tfMPDPort.text, let uiport = UInt16(strPort) {
			port = uiport
		}

		// Check MPD password (optional)
		var password = ""
		if let strPassword = tfMPDPassword.text, strPassword.count > 0 {
			password = strPassword
		}

		let mpdServer = MPDServer(hostname: ipa, port: port, password: password)
		let cnn = MPDConnection(mpdServer)
		let result = cnn.connect()
		switch result {
		case .failure:
			break
		case .success:
			if selectedServer != nil {
				selectedServer?.mpd = mpdServer
				if selectedServer?.name != serverName {
					selectedServer?.name = serverName
				}
			} else {
				selectedServer = ShinobuServer(name: serverName, mpd: mpdServer)
			}

			serversManager.handleServer(selectedServer!)
			cnn.disconnect()

			updateOutputsLabel()
		}

		// Check web URL (optional)
		if let strURL = tfWEBHostname.text, String.isNullOrWhiteSpace(strURL) == false {
			var port = UInt16(80)
			if let strPort = tfWEBPort.text, let uiport = UInt16(strPort) {
				port = uiport
			}

			var coverName = "cover.jpg"
			if let covn = tfWEBCoverName.text, String.isNullOrWhiteSpace(covn) == false {
				if String.isNullOrWhiteSpace(URL(fileURLWithPath: covn).pathExtension) == false {
					coverName = covn
				}
			}
			let webServer = CoverServer(hostname: strURL, port: port, coverName: coverName)
			selectedServer?.covers = webServer

			if selectedServer != nil {
				serversManager.handleServer(selectedServer!)
			} else {
				let alertController = NYXAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message: NYXLocalizedString("lbl_alert_servercfg_error_msg"), preferredStyle: .alert)
				let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel)
				alertController.addAction(cancelAction)
				navigationController?.present(alertController, animated: true, completion: nil)
				return
			}
		} else {
			if selectedServer != nil {
				selectedServer?.covers = nil
				serversManager.handleServer(selectedServer!)
			}
		}
	}

	@objc private func browserZeroConfAction(_ sender: Any?) {
		if zeroConfVC == nil {
			zeroConfVC = ZeroConfBrowserVC()
		}

		if let zvc = zeroConfVC {
			zvc.delegate = self
			zvc.selectedServer = selectedServer
			navigationController?.pushViewController(zvc, animated: true)
		}
	}

	// MARK: - Notifications
	@objc private func keyboardDidShowNotification(_ aNotification: Notification) {
		if keyboardVisible {
			return
		}

		guard let info = aNotification.userInfo else {
			return
		}

		guard let value = info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue? else {
			return
		}

		let keyboardFrame = view.convert(value.cgRectValue, from: nil)
		tableView.frame = CGRect(tableView.frame.origin, tableView.frame.width, tableView.frame.height - keyboardFrame.height)
		keyboardVisible = true
	}

	@objc private func keyboardDidHideNotification(_ aNotification: Notification) {
		if keyboardVisible == false {
			return
		}

		guard let info = aNotification.userInfo else {
			return
		}

		guard let value = info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue? else {
			return
		}

		let keyboardFrame = view.convert(value.cgRectValue, from: nil)
		tableView.frame = CGRect(tableView.frame.origin, tableView.frame.width, tableView.frame.height + keyboardFrame.height)
		keyboardVisible = false
	}

	@objc private func audioOutputConfigurationDidChangeNotification(_ aNotification: Notification) {
		updateOutputsLabel()
	}

	// MARK: - Private
	private func updateFields() {
		if let server = selectedServer {
			tfMPDName.text = server.name
			tfMPDHostname.text = server.mpd.hostname
			tfMPDPort.text = String(server.mpd.port)
			tfMPDPassword.text = server.mpd.password

			tfWEBHostname.text = server.covers?.hostname ?? server.mpd.hostname
			tfWEBPort.text = String(server.covers?.port ?? 80)
			tfWEBCoverName.text = server.covers?.coverName ?? "cover.jpg"

			updateOutputsLabel()
		} else {
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

	private func clearCache(confirm: Bool) {
		if confirm {
			let alertController = NYXAlertController(title: NYXLocalizedString("lbl_alert_purge_cache_title"), message: NYXLocalizedString("lbl_alert_purge_cache_msg"), preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel)
			alertController.addAction(cancelAction)
			let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive) { (_) in
				ImageCache.shared.clear { (_) in
					self.updateCacheLabel()
				}
			}
			alertController.addAction(okAction)
			present(alertController, animated: true, completion: nil)
		} else {
			ImageCache.shared.clear { (_) in
				self.updateCacheLabel()
			}
		}
	}

	private func updateCacheLabel() {
		guard let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else { return }
		DispatchQueue.global().async {
			let size = FileManager.default.sizeOfDirectoryAtURL(cachesDirectoryURL)
			DispatchQueue.main.async {
				self.cacheSize = size
				if self.navigationController?.visibleViewController === self {
					self.tableView.reloadRows(at: [IndexPath(row: 3, section: 2)], with: .none)
				}
			}
		}
	}

	private func updateOutputsLabel() {
		guard selectedServer != nil else { return }

		let cnn = MPDConnection(selectedServer!.mpd)
		let result = cnn.connect()
		switch result {
		case .failure:
			break
		case .success:
			let res = cnn.getAvailableOutputs()
			switch res {
			case .failure:
				break
			case .success(let outputs):
				if outputs.isEmpty {
					lblMPDOutput.text = NYXLocalizedString("lbl_server_no_output_available")
					return
				}
				let enabledOutputs = outputs.filter { $0.enabled }
				if enabledOutputs.isEmpty {
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
extension ServerAddEditVC: ZeroConfBrowserVCDelegate {
	func audioServerDidChange(with server: ShinobuServer) {
		clearCache(confirm: false)
		selectedServer = server
	}
}

// MARK: - UITableViewDataSource
extension ServerAddEditVC {
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 3
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
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

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cellIdentifier = "\(indexPath.section):\(indexPath.row)"
		var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
		if cell == nil {
			cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)

			if indexPath.section == 0 {
				if indexPath.row == 0 {
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(tfMPDName)
					tfMPDName.frame = CGRect(16, 0, UIScreen.main.bounds.width - 32, 44)
				}
			} else if indexPath.section == 1 {
				if indexPath.row == 0 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_host")
					cell?.selectionStyle = .none
					cell?.addSubview(tfMPDHostname)
					tfMPDHostname.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				} else if indexPath.row == 1 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_port")
					cell?.selectionStyle = .none
					cell?.addSubview(tfMPDPort)
					tfMPDPort.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				} else if indexPath.row == 2 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_password")
					cell?.selectionStyle = .none
					cell?.addSubview(tfMPDPassword)
					tfMPDPassword.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				} else if indexPath.row == 3 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_output")
					cell?.selectionStyle = .none
					cell?.addSubview(lblMPDOutput)
					lblMPDOutput.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				} else if indexPath.row == 4 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_update_db")
					cell?.textLabel?.textAlignment = .center
					cell?.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
					let view = UIView()
					view.backgroundColor = themeProvider.currentTheme.tintColor.withAlphaComponent(0.2)
					cell?.selectedBackgroundView = view
				}
			} else {
				if indexPath.row == 0 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_host")
					cell?.selectionStyle = .none
					cell?.addSubview(tfWEBHostname)
					tfWEBHostname.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				} else if indexPath.row == 1 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_port")
					cell?.selectionStyle = .none
					cell?.addSubview(tfWEBPort)
					tfWEBPort.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				} else if indexPath.row == 2 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_covername")
					cell?.selectionStyle = .none
					cell?.addSubview(tfWEBCoverName)
					tfWEBCoverName.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
				} else if indexPath.row == 3 {
					cell?.textLabel?.text = "\(NYXLocalizedString("lbl_server_coverclearcache")) (\(String(format: "%.2f", Double(cacheSize) / 1048576))\(NYXLocalizedString("lbl_megabytes")))"
					cell?.textLabel?.textAlignment = .center
					cell?.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
					let view = UIView()
					view.backgroundColor = themeProvider.currentTheme.tintColor.withAlphaComponent(0.2)
					cell?.selectedBackgroundView = view
				}
			}
		}

		cell?.backgroundColor = .secondarySystemGroupedBackground
		cell?.textLabel?.textColor = .secondaryLabel

		if indexPath.section == 0 {
			if indexPath.row == 0 {
				tfMPDName.frame = CGRect(16, 0, UIScreen.main.bounds.width - 32, 44)
			}
		} else if indexPath.section == 1 {
			if indexPath.row == 0 {
				tfMPDHostname.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			} else if indexPath.row == 1 {
				tfMPDPort.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			} else if indexPath.row == 2 {
				tfMPDPassword.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			} else if indexPath.row == 3 {
				lblMPDOutput.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			} else if indexPath.row == 4 {
				cell?.textLabel?.textColor = themeProvider.currentTheme.tintColor
			}
		} else {
			if indexPath.row == 0 {
				tfWEBHostname.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			} else if indexPath.row == 1 {
				tfWEBPort.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			} else if indexPath.row == 2 {
				tfWEBCoverName.frame = CGRect(UIScreen.main.bounds.width - 144 - 16, 0, 144, 44)
			} else if indexPath.row == 3 {
				cell?.textLabel?.textColor = themeProvider.currentTheme.tintColor
			}
		}

		return cell!
	}
}

// MARK: - UITableViewDelegate
extension ServerAddEditVC {
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		if indexPath.section == 1 && indexPath.row == 3 {
			guard let cell = tableView.cellForRow(at: indexPath) else {
				return
			}

			guard let server = selectedServer else { return }

			let avc = OutputsListVC(mpdServer: server.mpd)
			avc.modalPresentationStyle = .popover
			if let popController = avc.popoverPresentationController {
				popController.permittedArrowDirections = .up
				popController.sourceRect = cell.bounds
				popController.sourceView = cell
				popController.delegate = self
				present(avc, animated: true, completion: nil)
			}
		} else if indexPath.section == 1 && indexPath.row == 4 {
			mpdBridge.updateDatabase { (succeeded) in
				DispatchQueue.main.async {
					if succeeded == false {
						MessageView.shared.showWithMessage(message: Message(content: NYXLocalizedString("lbl_alert_update_mpd_failed"), type: .error))
					} else {
						MessageView.shared.showWithMessage(message: Message(content: NYXLocalizedString("lbl_alert_update_mpd_succeeded"), type: .success))
					}
				}
			}
		} else if indexPath.section == 2 && indexPath.row == 3 {
			clearCache(confirm: true)
		}
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return NYXLocalizedString("lbl_server_name").uppercased()
		} else if section == 1 {
			return NYXLocalizedString("lbl_server_section_server").uppercased()
		} else {
			return NYXLocalizedString("lbl_server_section_cover").uppercased()
		}
	}
}

// MARK: - UITextFieldDelegate
extension ServerAddEditVC: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField === tfMPDName {
			tfMPDHostname.becomeFirstResponder()
		} else if textField === tfMPDHostname {
			tfMPDPort.becomeFirstResponder()
		} else if textField === tfMPDPort {
			tfMPDPassword.becomeFirstResponder()
		} else if textField === tfMPDPassword {
			textField.resignFirstResponder()
		} else if textField === tfWEBHostname {
			tfWEBPort.becomeFirstResponder()
		} else if textField === tfWEBPort {
			tfWEBCoverName.becomeFirstResponder()
		} else {
			textField.resignFirstResponder()
		}
		return true
	}
}

// MARK: - UIPopoverPresentationControllerDelegate
extension ServerAddEditVC: UIPopoverPresentationControllerDelegate {
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		.none
	}
}

extension ServerAddEditVC: Themed {
	func applyTheme(_ theme: Theme) {
	}
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ServerAddEditVC: UIAdaptivePresentationControllerDelegate {
	func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		updateFields()
	}
}
