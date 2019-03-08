import UIKit
import MessageUI


private let headerSectionHeight: CGFloat = 32.0


final class SettingsVC : NYXTableViewController, CenterViewController
{
	// MARK: - Private properties
	// Shake to play switch
	private var swShake: UISwitch!
	// Fuzzy search switch
	private var swFuzzySearch: UISwitch!
	// Logging switch
	private var swLogging: UISwitch!
	// Delegate
	var containerDelegate: ContainerVCDelegate? = nil

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-hamb"), style: .plain, target: self, action: #selector(showLeftViewAction(_:)))

		// Navigation bar title
		titleView.text = NYXLocalizedString("lbl_section_settings")

		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.separatorColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		tableView.tableFooterView = UIView()

		swShake = UISwitch()
		swShake.addTarget(self, action: #selector(toggleShakeToPlay(_:)), for: .valueChanged)
		swFuzzySearch = UISwitch()
		swFuzzySearch.addTarget(self, action: #selector(toggleFuzzySearch(_:)), for: .valueChanged)
		swLogging = UISwitch()
		swLogging.addTarget(self, action: #selector(toggleLogging(_:)), for: .valueChanged)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		tableView.reloadData()
	}

	// MARK: - IBActions
	@objc func toggleShakeToPlay(_ sender: Any?)
	{
		let shake = Settings.shared.bool(forKey: .pref_shakeToPlayRandom)
		Settings.shared.set(!shake, forKey: .pref_shakeToPlayRandom)
	}

	@objc func toggleFuzzySearch(_ sender: Any?)
	{
		let fuzzySearch = Settings.shared.bool(forKey: .pref_fuzzySearch)
		Settings.shared.set(!fuzzySearch, forKey: .pref_fuzzySearch)
	}

	@objc func toggleLogging(_ sender: Any?)
	{
		let logging = Settings.shared.bool(forKey: .pref_enableLogging)
		Settings.shared.set(!logging, forKey: .pref_enableLogging)
	}

	@objc func showLeftViewAction(_ sender: Any?)
	{
		containerDelegate?.toggleMenu()
	}

	// MARK: - Private
	private func applicationVersionAndBuild() -> (version: String, build: String)
	{
		let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
		let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String

		return (version, build)
	}

	private func sendLogs()
	{
		if MFMailComposeViewController.canSendMail()
		{
			guard let data = Logger.shared.export() else
			{
				let alertController = NYXAlertController(title: NYXLocalizedString("lbl_error"), message:NYXLocalizedString("lbl_alert_logsexport_fail_msg"), preferredStyle: .alert)
				let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive) { (action) in
				}
				alertController.addAction(okAction)
				present(alertController, animated: true, completion: nil)
				return
			}

			let mailComposerVC = MFMailComposeViewController()
			mailComposerVC.mailComposeDelegate = self
			mailComposerVC.setToRecipients(["blabla@gmail.com"])
			mailComposerVC.setSubject("Shinobu logs")
			mailComposerVC.addAttachmentData(data, mimeType: "text/plain" , fileName: "logs.txt")

			var message = "Shinobu \(applicationVersionAndBuild().version) (\(applicationVersionAndBuild().build))\niOS \(UIDevice.current.systemVersion)\n\n"
			let server = ServersManager.shared.getSelectedServer()
			if let s = server
			{
				message += "MPD server:\n\(s.mpd.publicDescription())\n\n"
				Logger.shared.log(type: .error, message: "Failed to decode mpd server")
			}

			if let s = server, let w = s.covers
			{
				message += "Cover server:\n\(w.publicDescription())\n\n"
				Logger.shared.log(type: .error, message: "Failed to decode web server")
			}
			mailComposerVC.setMessageBody(message, isHTML: false)

			present(mailComposerVC, animated: true, completion: nil)

		}
		else
		{
			let alertController = NYXAlertController(title: NYXLocalizedString("lbl_error"), message:NYXLocalizedString("lbl_alert_nomailaccount_msg"), preferredStyle: .alert)
			let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive) { (action) in
			}
			alertController.addAction(okAction)
			present(alertController, animated: true, completion: nil)
		}
	}
}

// MARK: - UITableViewDataSource
extension SettingsVC
{
	override func numberOfSections(in tableView: UITableView) -> Int
	{
		return 4
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		switch section
		{
			case 0:
				return 2
			case 1:
				return 2
			case 2:
				return 3
			case 3:
				return 1
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
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_shaketoplayrandom")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swShake)
				}
				if indexPath.row == 1
				{
					cell?.selectionStyle = .none
				}
			}
			else if indexPath.section == 1
			{
				if indexPath.row == 0
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_fuzzysearch")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swFuzzySearch)
				}
				if indexPath.row == 1
				{
					cell?.selectionStyle = .none
				}
			}
			else if indexPath.section == 2
			{
				if indexPath.row == 0
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_enable_logging")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swLogging)
				}
				else if indexPath.row == 1
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_send_logs")
					cell?.textLabel?.textAlignment = .center
					cell?.textLabel?.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
					cell?.textLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
					let backgroundView = UIView()
					backgroundView.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
					cell?.selectedBackgroundView = backgroundView
				}
			}
			else
			{
				if indexPath.row == 0
				{
					let version = applicationVersionAndBuild()
					cell?.textLabel?.text = "\(version.version) (\(version.build))"
					cell?.textLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .ultraLight)
					cell?.textLabel?.textAlignment = .center
					cell?.selectionStyle = .none
				}
			}
		}

		if indexPath.section == 0
		{
			if indexPath.row == 0
			{
				swShake.frame = CGRect(UIScreen.main.bounds.width - 16.0 - swShake.width, (cell!.height - swShake.height) / 2, swShake.size)
			}
		}
		else if indexPath.section == 1
		{
			if indexPath.row == 0
			{
				swFuzzySearch.frame = CGRect(UIScreen.main.bounds.width - 16.0 - swFuzzySearch.width, (cell!.height - swFuzzySearch.height) / 2, swFuzzySearch.size)
			}
		}
		else if indexPath.section == 2
		{
			if indexPath.row == 0
			{
				swLogging.frame = CGRect(UIScreen.main.bounds.width - 16.0 - swLogging.width, (cell!.height - swLogging.height) / 2, swLogging.size)
			}
		}

		return cell!
	}
}

// MARK: - UITableViewDelegate
extension SettingsVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		if indexPath.section == 2 && indexPath.row == 1
		{
			sendLogs()
		}

		tableView.deselectRow(at: indexPath, animated: true)
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

		switch section
		{
			case 0:
				label.text = NYXLocalizedString("lbl_behaviour").uppercased()
			case 1:
				label.text = NYXLocalizedString("lbl_search").uppercased()
			case 2:
				label.text = NYXLocalizedString("lbl_troubleshoot").uppercased()
			case 3:
				label.text = NYXLocalizedString("lbl_version").uppercased()
			default:
				break
		}

		return dummy
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	{
		return headerSectionHeight
	}
}

extension SettingsVC : MFMailComposeViewControllerDelegate
{
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
	{
		controller.dismiss(animated: true, completion: nil)
	}
}
