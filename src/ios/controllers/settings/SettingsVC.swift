import UIKit
import MessageUI


private let headerSectionHeight: CGFloat = 32


final class SettingsVC: NYXTableViewController
{
	// MARK: - Private properties
	// Shake to play switch
	private var swShake: UISwitch!
	// Fuzzy search switch
	private var swFuzzySearch: UISwitch!
	// Logging switch
	private var swLogging: UISwitch!
	// Columns control
	private var sColumns: UISegmentedControl!

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		let libraryButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-library"), style: .plain, target: self, action: #selector(closeAction(_:)))
		libraryButton.accessibilityLabel = NYXLocalizedString("lbl_section_home")
		navigationItem.leftBarButtonItem = libraryButton

		// Navigation bar title
		titleView.setMainText(NYXLocalizedString("lbl_section_settings"), detailText: nil)

		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.separatorColor = UITableView.colorSeparator

		swShake = UISwitch()
		swShake.tintColor = UITableView.colorActionItem
		swShake.addTarget(self, action: #selector(toggleShakeToPlay(_:)), for: .valueChanged)
		swFuzzySearch = UISwitch()
		swFuzzySearch.tintColor = UITableView.colorActionItem
		swFuzzySearch.addTarget(self, action: #selector(toggleFuzzySearch(_:)), for: .valueChanged)
		swLogging = UISwitch()
		swLogging.tintColor = UITableView.colorActionItem
		swLogging.addTarget(self, action: #selector(toggleLogging(_:)), for: .valueChanged)
		sColumns = UISegmentedControl(items: ["2", "3"])
		sColumns.tintColor = Colors.main
		sColumns.addTarget(self, action: #selector(toggleColumns(_:)), for: .valueChanged)
		sColumns.frame = CGRect(0, 0, 64, swLogging.height)
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

	@objc func toggleColumns(_ sender: Any?)
	{
		Settings.shared.set(sColumns.selectedSegmentIndex + 2, forKey: .pref_numberOfColumns)

		ImageCache.shared.clear(nil)

		NotificationCenter.default.postOnMainThreadAsync(name: .collectionViewLayoutShouldChange, object: nil)
	}

	@objc func closeAction(_ sender: Any?)
	{
		dismiss(animated: true, completion: nil)
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
				let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive)
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
			let server = ServersManager().getSelectedServer()
			if let s = server
			{
				message += "MPD server:\n\(s.mpd)\n\n"
				Logger.shared.log(type: .error, message: "Failed to decode mpd server")
			}

			if let s = server, let w = s.covers
			{
				message += "Cover server:\n\(w)\n\n"
				Logger.shared.log(type: .error, message: "Failed to decode web server")
			}
			mailComposerVC.setMessageBody(message, isHTML: false)

			present(mailComposerVC, animated: true, completion: nil)

		}
		else
		{
			let alertController = NYXAlertController(title: NYXLocalizedString("lbl_error"), message:NYXLocalizedString("lbl_alert_nomailaccount_msg"), preferredStyle: .alert)
			let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive)
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
		return 5
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		switch section
		{
			case 0:
				return 1
			case 1:
				return 1
			case 2:
				return 1
			case 3:
				return 2
			case 4:
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
			cell?.textLabel?.textColor = UITableView.colorMainText
			cell?.backgroundColor = UITableView.colorCellBackground

			if indexPath.section == 0
			{
				if indexPath.row == 0
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_columns")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(sColumns)
				}
			}
			else if indexPath.section == 1
			{
				if indexPath.row == 0
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_shaketoplayrandom")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swShake)
				}
			}
			else if indexPath.section == 2
			{
				if indexPath.row == 0
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_fuzzysearch")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swFuzzySearch)
				}
			}
			else if indexPath.section == 3
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
					let version = applicationVersionAndBuild()
					cell?.textLabel?.text = "\(version.version) (\(version.build))"
					cell?.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .ultraLight)
					cell?.textLabel?.textAlignment = .center
					cell?.selectionStyle = .none
				}
			}
		}

		if indexPath.section == 0
		{
			if indexPath.row == 0
			{
				sColumns.frame = CGRect(UIScreen.main.bounds.width - 16 - sColumns.width, (cell!.height - sColumns.height) / 2, sColumns.size)
				sColumns.selectedSegmentIndex = Settings.shared.integer(forKey: .pref_numberOfColumns) - 2
			}
		}
		else if indexPath.section == 1
		{
			if indexPath.row == 0
			{
				swShake.frame = CGRect(UIScreen.main.bounds.width - 16 - swShake.width, (cell!.height - swShake.height) / 2, swShake.size)
				swShake.isOn = Settings.shared.bool(forKey: .pref_shakeToPlayRandom)
			}
		}
		else if indexPath.section == 2
		{
			if indexPath.row == 0
			{
				swFuzzySearch.frame = CGRect(UIScreen.main.bounds.width - 16 - swFuzzySearch.width, (cell!.height - swFuzzySearch.height) / 2, swFuzzySearch.size)
				swFuzzySearch.isOn = Settings.shared.bool(forKey: .pref_fuzzySearch)
			}
		}
		else if indexPath.section == 3
		{
			if indexPath.row == 0
			{
				swLogging.frame = CGRect(UIScreen.main.bounds.width - 16 - swLogging.width, (cell!.height - swLogging.height) / 2, swLogging.size)
				swLogging.isOn = Settings.shared.bool(forKey: .pref_enableLogging)
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
		if indexPath.section == 3 && indexPath.row == 1
		{
			sendLogs()
		}

		tableView.deselectRow(at: indexPath, animated: true)
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

		switch section
		{
			case 0:
				label.text = NYXLocalizedString("lbl_pref_appearance").uppercased()
			case 1:
				label.text = NYXLocalizedString("lbl_behaviour").uppercased()
			case 2:
				label.text = NYXLocalizedString("lbl_search").uppercased()
			case 3:
				label.text = NYXLocalizedString("lbl_troubleshoot").uppercased()
			case 4:
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

extension SettingsVC: MFMailComposeViewControllerDelegate
{
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
	{
		controller.dismiss(animated: true, completion: nil)
	}
}
