import UIKit
import MessageUI


private let headerSectionHeight: CGFloat = 32


final class SettingsVC: NYXTableViewController
{
	// MARK: - Private properties
	// Shake to play switch
	private var swPrettyDB: UISwitch!
	// Shake to play switch
	private var swShake: UISwitch!
	// Fuzzy search switch
	private var swFuzzySearch: UISwitch!
	// Logging switch
	private var swLogging: UISwitch!
	// Theme switch
	private var swTheme: UISwitch!
	// Columns control
	private var sColumns: UISegmentedControl!
	//
	private var colorsButton = [ColorButton]()

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

		swShake = UISwitch()
		swShake.addTarget(self, action: #selector(toggleShakeToPlay(_:)), for: .valueChanged)

		swPrettyDB = UISwitch()
		swPrettyDB.addTarget(self, action: #selector(toggleUsePrettyDB(_:)), for: .valueChanged)

		swFuzzySearch = UISwitch()
		swFuzzySearch.addTarget(self, action: #selector(toggleFuzzySearch(_:)), for: .valueChanged)

		swLogging = UISwitch()
		swLogging.addTarget(self, action: #selector(toggleLogging(_:)), for: .valueChanged)

		swTheme = UISwitch()
		swTheme.addTarget(self, action: #selector(toggleTheme(_:)), for: .valueChanged)

		sColumns = UISegmentedControl(items: ["2", "3"])
		sColumns.addTarget(self, action: #selector(toggleColumns(_:)), for: .valueChanged)
		sColumns.frame = CGRect(0, 0, 64, swLogging.height)

		let margin = CGFloat(4)
		var x = view.width - CGFloat(32 * TintColorType.allCases.count) - CGFloat(margin * CGFloat(TintColorType.allCases.count)) - 16
		for c in TintColorType.allCases
		{
			let btn = ColorButton(frame: CGRect(x, 6, 32, 32), tintColorType: c)
			btn.isSelected = c.rawValue == Settings.shared.integer(forKey: .pref_tintColor)
			btn.addTarget(self, action: #selector(toggleTintColor(_:)), for: .touchUpInside)
			colorsButton.append(btn)

			x += 32 + margin
		}

		initializeTheming()
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

	@objc func toggleUsePrettyDB(_ sender: Any?)
	{
		let pretty = Settings.shared.bool(forKey: .pref_usePrettyDB)
		Settings.shared.set(!pretty, forKey: .pref_usePrettyDB)
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

	@objc func toggleTheme(_ sender: Any?)
	{
		let dark = !Settings.shared.bool(forKey: .pref_themeDark)
		Settings.shared.set(dark, forKey: .pref_themeDark)
		var theme = dark ? Theme.dark : Theme.light
		theme.tintColor = colorForTintColorType(TintColorType(rawValue: Settings.shared.integer(forKey: .pref_tintColor))!)
		themeProvider.currentTheme = theme
	}

	@objc func toggleColumns(_ sender: Any?)
	{
		Settings.shared.set(sColumns.selectedSegmentIndex + 2, forKey: .pref_numberOfColumns)

		ImageCache.shared.clear(nil)

		NotificationCenter.default.postOnMainThreadAsync(name: .collectionViewLayoutShouldChange, object: nil)
	}

	@objc fileprivate func toggleTintColor(_ sender: ColorButton?)
	{
		guard let button = sender else { return }

		Settings.shared.set(button.tintColorType.rawValue, forKey: .pref_tintColor)

		themeProvider.currentTheme.tintColor = colorForTintColorType(button.tintColorType)
		themeProvider.currentTheme = themeProvider.currentTheme
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
				return 3
			case 1:
				return 2
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

			if indexPath.section == 0
			{
				if indexPath.row == 0
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_theme_dark")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swTheme)
				}
				else if indexPath.row == 1
				{
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_tint_color")
					cell?.selectionStyle = .none
					for btn in colorsButton
					{
						cell?.addSubview(btn)
					}
				}
				else if indexPath.row == 2
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
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_useprettydb")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swPrettyDB)
				}
				else if indexPath.row == 1
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
					cell?.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .black)
					let v = UIView()
					v.backgroundColor = themeProvider.currentTheme.tintColor.withAlphaComponent(0.2)
					cell?.selectedBackgroundView = v
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

		cell?.backgroundColor = themeProvider.currentTheme.tableCellColor
		cell?.textLabel?.textColor = themeProvider.currentTheme.tableCellMainLabelTextColor
		cell?.textLabel?.highlightedTextColor = themeProvider.currentTheme.tintColor

		if indexPath.section == 0
		{
			if indexPath.row == 0
			{
				swTheme.frame = CGRect(UIScreen.main.bounds.width - 16 - swTheme.width, (cell!.height - swTheme.height) / 2, swTheme.size)
				swTheme.isOn = Settings.shared.bool(forKey: .pref_themeDark)
			}
			else if indexPath.row == 1
			{
				let tintAsInt = Settings.shared.integer(forKey: .pref_tintColor)
				for btn in colorsButton
				{
					btn.isSelected = btn.tintColorType.rawValue == tintAsInt
				}
			}
			else if indexPath.row == 2
			{
				sColumns.frame = CGRect(UIScreen.main.bounds.width - 16 - sColumns.width, (cell!.height - sColumns.height) / 2, sColumns.size)
				sColumns.selectedSegmentIndex = Settings.shared.integer(forKey: .pref_numberOfColumns) - 2
			}
		}
		else if indexPath.section == 1
		{
			if indexPath.row == 0
			{
				swPrettyDB.frame = CGRect(UIScreen.main.bounds.width - 16 - swPrettyDB.width, (cell!.height - swPrettyDB.height) / 2, swPrettyDB.size)
				swPrettyDB.isOn = Settings.shared.bool(forKey: .pref_usePrettyDB)
			}
			else if indexPath.row == 1
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
		let dummy = UIView(frame: CGRect(.zero, tableView.width, headerSectionHeight))
		dummy.backgroundColor = tableView.backgroundColor

		let label = UILabel(frame: CGRect(10, 0, dummy.width - 20, dummy.height))
		label.backgroundColor = dummy.backgroundColor
		label.textColor = themeProvider.currentTheme.tableSectionHeaderTextColor
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
		let dummy = UIView(frame: CGRect(.zero, tableView.width, headerSectionHeight))
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

extension SettingsVC: Themed
{
	func applyTheme(_ theme: Theme)
	{
		view.backgroundColor = theme.backgroundColor
		tableView.backgroundColor = theme.backgroundColor
		tableView.separatorColor = theme.tableSeparatorColor
		swShake.onTintColor = theme.tintColor
		swShake.tintColor = theme.switchTintColor
		swPrettyDB.onTintColor = theme.tintColor
		swPrettyDB.tintColor = theme.switchTintColor
		swFuzzySearch.onTintColor = theme.tintColor
		swFuzzySearch.tintColor = theme.switchTintColor
		swLogging.onTintColor = theme.tintColor
		swLogging.tintColor = theme.switchTintColor
		swTheme.onTintColor = theme.tintColor
		swTheme.tintColor = theme.switchTintColor
		sColumns.tintColor = theme.tintColor

		tableView.reloadData()
	}
}


fileprivate final class ColorButton: UIButton, Themed
{
	//
	private(set) var tintColorType: TintColorType

	init(frame: CGRect, tintColorType: TintColorType)
	{
		self.tintColorType = tintColorType

		super.init(frame: frame)

		self.circleize()
		self.backgroundColor = colorForTintColorType(tintColorType)

		initializeTheming()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override var isSelected: Bool
	{
		willSet
		{
			self.layer.borderWidth = isSelected ? 2 : 0
		}

		didSet
		{
			self.layer.borderWidth = isSelected ? 2 : 0
		}
	}

	override var isHighlighted: Bool
	{
		willSet
		{
			self.layer.borderWidth = isHighlighted ? 2 : 0
		}

		didSet
		{
			self.layer.borderWidth = isHighlighted ? 2 : 0
		}
	}

	override var buttonType: UIButton.ButtonType
	{
		return .custom
	}

	func applyTheme(_ theme: Theme)
	{
		self.layer.borderColor = theme.tableTextFieldTextColor.cgColor
	}
}
