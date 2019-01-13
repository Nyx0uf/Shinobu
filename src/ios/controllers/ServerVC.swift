// ServerVC.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit


private let headerSectionHeight: CGFloat = 32.0


final class ServerVC : UITableViewController, CenterViewController
{
	// MARK: - Private properties
	// MPD Server name
	@IBOutlet private var tfMPDName: UITextField!
	// MPD Server hostname
	@IBOutlet private var tfMPDHostname: UITextField!
	// MPD Server port
	@IBOutlet private var tfMPDPort: UITextField!
	// MPD Server password
	@IBOutlet private var tfMPDPassword: UITextField!
	// MPD Output
	@IBOutlet private var lblMPDOutput: UILabel!
	// WEB Server hostname
	@IBOutlet private var tfWEBHostname: UITextField!
	// WEB Server port
	@IBOutlet private var tfWEBPort: UITextField!
	// Cover name
	@IBOutlet private var tfWEBCoverName: UITextField!
	// Cell Labels
	@IBOutlet private var lblCellMPDName: UILabel! = nil
	@IBOutlet private var lblCellMPDHostname: UILabel! = nil
	@IBOutlet private var lblCellMPDPort: UILabel! = nil
	@IBOutlet private var lblCellMPDPassword: UILabel! = nil
	@IBOutlet private var lblCellMPDOutput: UILabel! = nil
	@IBOutlet private var lblCellWEBHostname: UILabel! = nil
	@IBOutlet private var lblCellWEBPort: UILabel! = nil
	@IBOutlet private var lblCellWEBCoverName: UILabel! = nil
	@IBOutlet private var lblClearCache: UILabel! = nil
	@IBOutlet private var lblUpdateDatabase: UILabel! = nil
	// MPD Server
	private var mpdServer: AudioServer?
	// WEB Server for covers
	private var webServer: CoverWebServer?
	// Indicate that the keyboard is visible, flag
	private var _keyboardVisible = false
	// Navigation title
	private var titleView: UILabel!
	// Delegate
	var containerDelegate: ContainerVCDelegate? = nil

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
		titleView.textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
		titleView.text = NYXLocalizedString("lbl_header_server_cfg")
		navigationItem.titleView = titleView

		if let buttons = self.navigationItem.rightBarButtonItems
		{
			if let search = buttons.filter({$0.tag == 10}).first
			{
				search.accessibilityLabel = NYXLocalizedString("lbl_search_zeroconf")
			}
		}

		lblCellMPDName.text = NYXLocalizedString("lbl_server_name")
		lblCellMPDHostname.text = NYXLocalizedString("lbl_server_host")
		lblCellMPDPort.text = NYXLocalizedString("lbl_server_port")
		lblCellMPDPassword.text = NYXLocalizedString("lbl_server_password")
		lblCellMPDOutput.text = NYXLocalizedString("lbl_server_output")
		lblCellWEBHostname.text = NYXLocalizedString("lbl_server_coverurl")
		lblCellWEBPort.text = NYXLocalizedString("lbl_server_port")
		lblCellWEBCoverName.text = NYXLocalizedString("lbl_server_covername")
		lblClearCache.text = NYXLocalizedString("lbl_server_coverclearcache")
		lblUpdateDatabase.text = NYXLocalizedString("lbl_update_db")
		tfMPDName.placeholder = NYXLocalizedString("lbl_server_defaultname")

		// Keyboard appearance notifications
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShowNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHideNotification(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(audioOutputConfigurationDidChangeNotification(_:)), name: .audioOutputConfigurationDidChange, object: nil)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		let decoder = JSONDecoder()

		if let mpdServerAsData = Settings.shared.data(forKey: kNYXPrefMPDServer)
		{
			do
			{
				let server = try decoder.decode(AudioServer.self, from: mpdServerAsData)
				mpdServer = server
			}
			catch let error
			{
				Logger.shared.log(type: .debug, message: "Failed to decode mpd server: \(error.localizedDescription)")
			}
		}
		else
		{
			Logger.shared.log(type: .debug, message: "No audio server registered yet")
		}

		if let webServerAsData = Settings.shared.data(forKey: kNYXPrefWEBServer)
		{
			do
			{
				let server = try decoder.decode(CoverWebServer.self, from: webServerAsData)
				webServer = server
			}
			catch let error
			{
				Logger.shared.log(type: .debug, message: "Failed to decode web server: \(error.localizedDescription)")
			}
		}
		else
		{
			Logger.shared.log(type: .debug, message: "No web server registered yet")
		}

		updateFields()
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .default
	}

	// MARK: - Buttons actions
	@IBAction func validateSettingsAction(_ sender: Any?)
	{
		view.endEditing(true)

		// Check MPD server name (optional)
		var serverName = NYXLocalizedString("lbl_server_defaultname")
		if let strName = tfMPDName.text , strName.count > 0
		{
			serverName = strName
		}

		// Check MPD hostname / ip
		guard let ip = tfMPDHostname.text , ip.count > 0 else
		{
			let alertController = UIAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_servercfg_error_host"), preferredStyle: .alert)
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

		let encoder = JSONEncoder()
		let mpdServer = AudioServer(name: serverName, hostname: ip, port: port, password: password)
		let cnn = MPDConnection(mpdServer)
		if cnn.connect().succeeded
		{
			self.mpdServer = mpdServer
			do
			{
				let serverAsData = try encoder.encode(mpdServer)
				Settings.shared.set(serverAsData, forKey: kNYXPrefMPDServer)
			}
			catch let error
			{
				Logger.shared.log(error: error)
			}

			NotificationCenter.default.post(name: .audioServerConfigurationDidChange, object: mpdServer)

			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
				self.updateOutputsLabel()
			})
		}
		else
		{
			Settings.shared.removeObject(forKey: kNYXPrefMPDServer)
			let alertController = UIAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_servercfg_error_msg"), preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			present(alertController, animated: true, completion: nil)
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
			let webServer = CoverWebServer(name: "CoverServer", hostname: strURL, port: port, coverName: coverName)
			self.webServer = webServer

			do
			{
				let serverAsData = try encoder.encode(webServer)
				Settings.shared.set(serverAsData, forKey: kNYXPrefWEBServer)
			}
			catch let error
			{
				Logger.shared.log(error: error)
			}
		}
		else
		{
			Settings.shared.removeObject(forKey: kNYXPrefWEBServer)
		}

		Settings.shared.synchronize()
	}

	@IBAction func browserZeroConfServers(_ sender: Any?)
	{
		let sb = UIStoryboard(name: "main-iphone", bundle: nil)
		let nvc = sb.instantiateViewController(withIdentifier: "ZeroConfBrowserNVC") as! NYXNavigationController
		let vc = nvc.topViewController as! ZeroConfBrowserTVC
		vc.delegate = self
		self.navigationController?.present(nvc, animated: true, completion: nil)
	}

	@objc @IBAction func showLeftViewAction(_ sender: Any?)
	{
		containerDelegate?.toggleMenu()
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

	@objc func audioOutputConfigurationDidChangeNotification(_ aNotification: Notification)
	{
		updateOutputsLabel()
	}

	// MARK: - Private
	private func updateFields()
	{
		if let server = mpdServer
		{
			tfMPDName.text = server.name
			tfMPDHostname.text = server.hostname
			tfMPDPort.text = String(server.port)
			tfMPDPassword.text = server.password
			updateOutputsLabel()
		}
		else
		{
			tfMPDName.text = ""
			tfMPDHostname.text = ""
			tfMPDPort.text = "6600"
			tfMPDPassword.text = ""
			lblMPDOutput.text = ""
		}

		if let server = webServer
		{
			tfWEBHostname.text = server.hostname
			tfWEBPort.text = String(server.port)
			tfWEBCoverName.text = server.coverName
		}
		else
		{
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
			let alertController = UIAlertController(title: NYXLocalizedString("lbl_alert_purge_cache_title"), message:NYXLocalizedString("lbl_alert_purge_cache_msg"), preferredStyle: .alert)
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
				self.lblClearCache.text = "\(NYXLocalizedString("lbl_server_coverclearcache")) (\(String(format: "%.2f", Double(size) / 1048576.0))\(NYXLocalizedString("lbl_megabytes")))"
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
	func audioServerDidChange()
	{
		clearCache(confirm: false)
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

		if indexPath.section == 0 && indexPath.row == 4
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
		else if indexPath.section == 0 && indexPath.row == 5
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
		else if indexPath.section == 1 && indexPath.row == 3
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
		label.textColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		label.font = UIFont.systemFont(ofSize: 15.0)
		dummy.addSubview(label)

		if section == 0
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
