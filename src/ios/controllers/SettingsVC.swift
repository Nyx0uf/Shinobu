import UIKit
import MessageUI


private let headerSectionHeight: CGFloat = 32.0


final class SettingsVC : UITableViewController, CenterViewController
{
	// MARK: - Private properties
	// Version label
	@IBOutlet private var lblVersion: UILabel!
	// Shake to play label
	@IBOutlet private var lblShake: UILabel!
	// Shake to play switch
	@IBOutlet private var swShake: UISwitch!
	// Fuzzy search label
	@IBOutlet private var lblFuzzySearch: UILabel!
	// Fuzzy search switch
	@IBOutlet private var swFuzzySearch: UISwitch!
	// Send logs label
	@IBOutlet private var lblSendLogs: UILabel!
	// Label logging
	@IBOutlet private var lblEnableLogging: UILabel!
	// Logging switch
	@IBOutlet private var swLogging: UISwitch!
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
		titleView.text = NYXLocalizedString("lbl_section_settings")
		navigationItem.titleView = titleView

		lblShake.text = NYXLocalizedString("lbl_pref_shaketoplayrandom")
		lblFuzzySearch.text = NYXLocalizedString("lbl_fuzzysearch")
		lblEnableLogging.text = NYXLocalizedString("lbl_enable_logging")
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		swShake.isOn = Settings.shared.bool(forKey: kNYXPrefShakeToPlayRandomAlbum)
		swFuzzySearch.isOn = Settings.shared.bool(forKey: kNYXPrefFuzzySearch)

		let version = applicationVersionAndBuild()
		lblVersion.text = "\(version.version) (\(version.build))"
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .default
	}

	// MARK: - IBActions
	@IBAction func toggleShakeToPlay(_ sender: Any?)
	{
		let shake = Settings.shared.bool(forKey: kNYXPrefShakeToPlayRandomAlbum)
		Settings.shared.set(!shake, forKey: kNYXPrefShakeToPlayRandomAlbum)
		Settings.shared.synchronize()
	}

	@IBAction func toggleFuzzySearch(_ sender: Any?)
	{
		let fuzzySearch = Settings.shared.bool(forKey: kNYXPrefFuzzySearch)
		Settings.shared.set(!fuzzySearch, forKey: kNYXPrefFuzzySearch)
		Settings.shared.synchronize()
	}

	@IBAction func toggleLogging(_ sender: Any?)
	{
		let logging = Settings.shared.bool(forKey: kNYXPrefEnableLogging)
		Settings.shared.set(!logging, forKey: kNYXPrefEnableLogging)
		Settings.shared.synchronize()
	}

	@objc @IBAction func showLeftViewAction(_ sender: Any?)
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
				let alertController = UIAlertController(title: NYXLocalizedString("lbl_error"), message:NYXLocalizedString("lbl_alert_logsexport_fail_msg"), preferredStyle: .alert)
				let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive) { (action) in
				}
				alertController.addAction(okAction)
				present(alertController, animated: true, completion: nil)
				return
			}

			let mailComposerVC = MFMailComposeViewController()
			mailComposerVC.mailComposeDelegate = self
			mailComposerVC.setToRecipients(["contact.mpdremote@gmail.com"])
			mailComposerVC.setSubject("MPDRemote logs")
			mailComposerVC.addAttachmentData(data, mimeType: "text/plain" , fileName: "logs.txt")

			var message = "MPDRemote \(applicationVersionAndBuild().version) (\(applicationVersionAndBuild().build))\niOS \(UIDevice.current.systemVersion)\n\n"
			if let mpdServerAsData = Settings.shared.data(forKey: kNYXPrefMPDServer)
			{
				do
				{
					let server = try JSONDecoder().decode(MPDServer.self, from: mpdServerAsData)
					message += "MPD server:\n\(server.publicDescription())\n\n"
				}
				catch
				{
					Logger.shared.log(type: .error, message: "Failed to decode mpd server")
				}
			}

			if let webServerAsData = Settings.shared.data(forKey: kNYXPrefWEBServer)
			{
				do
				{
					let server = try JSONDecoder().decode(CoverWebServer.self, from: webServerAsData)
					message += "Cover server:\n\(server.publicDescription())\n\n"
				}
				catch
				{
					Logger.shared.log(type: .error, message: "Failed to decode web server")
				}
			}
			mailComposerVC.setMessageBody(message, isHTML: false)

			present(mailComposerVC, animated: true, completion: nil)

		}
		else
		{
			let alertController = UIAlertController(title: NYXLocalizedString("lbl_error"), message:NYXLocalizedString("lbl_alert_nomailaccount_msg"), preferredStyle: .alert)
			let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive) { (action) in
			}
			alertController.addAction(okAction)
			present(alertController, animated: true, completion: nil)
		}
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
		label.textColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		label.font = UIFont.systemFont(ofSize: 15.0)
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
