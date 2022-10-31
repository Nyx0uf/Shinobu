import UIKit

final class ServerVC: NYXTableViewController {
	// MARK: - Private properties
	// MPD Server hostname
	private var tfMPDHostname: UITextField!
	// MPD Server port
	private var tfMPDPort: UITextField!
	// MPD Server password
	private var tfMPDPassword: UITextField!
	// MPD Output
	private var lblMPDOutput: UILabel!
	// MPD Server
	public var selectedServer: MPDServer?
	// Indicate that the keyboard is visible, flag
	private var keyboardVisible = false
	// Zero conf VC
	private var zeroConfVC: ZeroConfBrowserVC?
	// MPD Data source
	private let mpdBridge: MPDBridge
	// Servers manager
	private let serverManager: ServerManager

	// MARK: - Initializers
	init(mpdBridge: MPDBridge) {
		self.mpdBridge = mpdBridge
		self.serverManager = ServerManager()
		self.selectedServer = self.serverManager.getServer()

		super.init(style: .grouped)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.titleView = nil
		title = NYXLocalizedString("lbl_header_server_cfg")

		// Remove back button label
		navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "btn-back")
		navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "btn-back")
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(browserZeroConfAction(_:)))
		searchButton.accessibilityLabel = NYXLocalizedString("lbl_search_zeroconf")
		navigationItem.rightBarButtonItem = searchButton

		let closeButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(closeAction(_:)))
		closeButton.accessibilityLabel = NYXLocalizedString("lbl_close")
		navigationItem.leftBarButtonItem = closeButton

		tfMPDHostname = UITextField()
		tfMPDHostname.translatesAutoresizingMaskIntoConstraints = false
		tfMPDHostname.textAlignment = .right
		tfMPDHostname.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfMPDHostname.tintColor = UIColor.shinobuTintColor
		tfMPDHostname.placeholder = "mpd.local"

		tfMPDPort = UITextField()
		tfMPDPort.translatesAutoresizingMaskIntoConstraints = false
		tfMPDPort.textAlignment = .right
		tfMPDPort.text = "6600"
		tfMPDPort.keyboardType = .decimalPad
		tfMPDPort.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfMPDPort.tintColor = UIColor.shinobuTintColor

		tfMPDPassword = UITextField()
		tfMPDPassword.translatesAutoresizingMaskIntoConstraints = false
		tfMPDPassword.textAlignment = .right
		tfMPDPassword.isSecureTextEntry = true
		tfMPDPassword.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
		tfMPDPassword.tintColor = UIColor.shinobuTintColor
		tfMPDPassword.placeholder = NYXLocalizedString("lbl_optional")

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
			_ = validateSettingsAction()
		}
	}

	// MARK: - Buttons actions
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

	@objc private func closeAction(_ sender: Any?) {
		if let alertController = validateSettingsAction() {
			let editAction = UIAlertAction(title: NYXLocalizedString("lbl_modify"), style: .cancel)
			alertController.addAction(editAction)
			alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_close"), style: .destructive, handler: { _ in
				if let pvc = self.navigationController?.presentationController {
					pvc.delegate?.presentationControllerWillDismiss?(pvc)
				}
				self.navigationController?.dismiss(animated: true, completion: nil)
			}))
			navigationController?.present(alertController, animated: true, completion: nil)
		} else {
			if let pvc = self.navigationController?.presentationController {
				pvc.delegate?.presentationControllerWillDismiss?(pvc)
			}
			self.navigationController?.dismiss(animated: true, completion: nil)
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
	private func validateSettingsAction() -> NYXAlertController? {
		view.endEditing(true)

		// Check MPD hostname / ip
		guard let ipa = tfMPDHostname.text, ipa.count > 0 else {
			let alertController = NYXAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message: NYXLocalizedString("lbl_alert_servercfg_error_host"), preferredStyle: .alert)
			return alertController
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
		if mpdServer != selectedServer { // Server changed
			let cnn = MPDConnection(mpdServer)
			let result = cnn.connect()
			switch result {
			case .failure:
				break
			case .success:
				if selectedServer == nil { // No server configured
					selectedServer = mpdServer
				} else { // Server changed, update
					selectedServer = mpdServer
				}
			}
			cnn.disconnect()

			updateOutputsLabel()
		}

		if selectedServer != nil {
			serverManager.handleServer(selectedServer!)
		}

		return nil
	}

	private func updateFields() {
		if let server = selectedServer {
			tfMPDHostname.text = server.hostname
			tfMPDPort.text = String(server.port)
			tfMPDPassword.text = server.password

			updateOutputsLabel()
		} else {
			tfMPDHostname.text = ""
			tfMPDPort.text = "6600"
			tfMPDPassword.text = ""
			lblMPDOutput.text = ""
		}
	}

	private func clearCache(confirm: Bool) {
		if confirm {
			let alertController = NYXAlertController(title: NYXLocalizedString("lbl_alert_purge_cache_title"), message: NYXLocalizedString("lbl_alert_purge_cache_msg"), preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel)
			alertController.addAction(cancelAction)
			let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive) { (_) in
				ImageCache.shared.clear { (_) in }
			}
			alertController.addAction(okAction)
			present(alertController, animated: true, completion: nil)
		} else {
			ImageCache.shared.clear { (_) in }
		}
	}

	private func updateOutputsLabel() {
		guard selectedServer != nil else { return }

		let cnn = MPDConnection(selectedServer!)
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
				let enabledOutputs = outputs.filter(\.isEnabled)
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
extension ServerVC: ZeroConfBrowserVCDelegate {
	func audioServerDidChange(with server: MPDServer) {
		clearCache(confirm: false)
		selectedServer = server
	}
}

// MARK: - UITableViewDataSource
extension ServerVC {
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 5
		default:
			return 0
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cellIdentifier = "\(indexPath.section):\(indexPath.row)"
		var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
		let width = UIDevice.current.isPad() ? self.view.width : UIScreen.main.bounds.width
		if cell == nil {
			cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)

			if indexPath.section == 0 {
				if indexPath.row == 0 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_host")
					cell?.selectionStyle = .none
					cell?.addSubview(tfMPDHostname)
					tfMPDHostname.frame = CGRect(width - 144 - 16, 0, 144, 44)
				} else if indexPath.row == 1 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_port")
					cell?.selectionStyle = .none
					cell?.addSubview(tfMPDPort)
					tfMPDPort.frame = CGRect(width - 144 - 16, 0, 144, 44)
				} else if indexPath.row == 2 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_password")
					cell?.selectionStyle = .none
					cell?.addSubview(tfMPDPassword)
					tfMPDPassword.frame = CGRect(width - 144 - 16, 0, 144, 44)
				} else if indexPath.row == 3 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_server_output")
					cell?.selectionStyle = .none
					cell?.addSubview(lblMPDOutput)
					lblMPDOutput.frame = CGRect(width - 144 - 16, 0, 144, 44)
				} else if indexPath.row == 4 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_update_db")
					cell?.textLabel?.textAlignment = .center
					cell?.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
					let view = UIView()
					view.backgroundColor = UIColor.shinobuTintColor.withAlphaComponent(0.2)
					cell?.selectedBackgroundView = view
				}
			}
		}

		cell?.backgroundColor = .secondarySystemGroupedBackground
		cell?.textLabel?.textColor = .secondaryLabel

		if indexPath.section == 0 {
			if indexPath.row == 0 {
				tfMPDHostname.frame = CGRect(width - 144 - 16, 0, 144, 44)
			} else if indexPath.row == 1 {
				tfMPDPort.frame = CGRect(width - 144 - 16, 0, 144, 44)
			} else if indexPath.row == 2 {
				tfMPDPassword.frame = CGRect(width - 144 - 16, 0, 144, 44)
			} else if indexPath.row == 3 {
				lblMPDOutput.frame = CGRect(width - 144 - 16, 0, 144, 44)
			} else if indexPath.row == 4 {
				cell?.textLabel?.textColor = UIColor.shinobuTintColor
			}
		}

		return cell!
	}
}

// MARK: - UITableViewDelegate
extension ServerVC {
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		if indexPath.section == 0 && indexPath.row == 3 {
			guard let cell = tableView.cellForRow(at: indexPath) else {
				return
			}

			guard let server = selectedServer else { return }

			let avc = OutputsListVC(mpdServer: server)
			avc.modalPresentationStyle = .popover
			if let popController = avc.popoverPresentationController {
				popController.permittedArrowDirections = .up
				popController.sourceRect = cell.bounds
				popController.sourceView = cell
				popController.delegate = self
				present(avc, animated: true, completion: nil)
			}
		} else if indexPath.section == 0 && indexPath.row == 4 {
			mpdBridge.updateDatabase { (succeeded) in
				DispatchQueue.main.async {
					if succeeded == false {
						MessageView.shared.showWithMessage(message: Message(content: NYXLocalizedString("lbl_alert_update_mpd_failed"), type: .error))
					} else {
						MessageView.shared.showWithMessage(message: Message(content: NYXLocalizedString("lbl_alert_update_mpd_succeeded"), type: .success))
					}
				}
			}
		}
	}
}

// MARK: - UITextFieldDelegate
extension ServerVC: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField === tfMPDHostname {
			tfMPDPort.becomeFirstResponder()
		} else if textField === tfMPDPort {
			tfMPDPassword.becomeFirstResponder()
		} else if textField === tfMPDPassword {
			textField.resignFirstResponder()
		} else {
			textField.resignFirstResponder()
		}
		return true
	}
}

// MARK: - UIPopoverPresentationControllerDelegate
extension ServerVC: UIPopoverPresentationControllerDelegate {
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		.none
	}
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ServerVC: UIAdaptivePresentationControllerDelegate {
	func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		updateFields()
	}
}