import UIKit
import MessageUI

final class SettingsVC: NYXTableViewController {
	// MARK: - Private properties
	// Shake to play switch
	private var swPrettyDB: UISwitch!
	// Shake to play switch
	private var swShake: UISwitch!
	// Fuzzy search switch
	private var swFuzzySearch: UISwitch!
	// Browse by directory switch
	private var swDirectory: UISwitch!
	// Columns control
	private var sColumns: UISegmentedControl!
	// Buttons for the tint color
	private var colorsButton = [ColorButton]()

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.titleView = nil
		self.title = NYXLocalizedString("lbl_section_settings")
		self.navigationController?.navigationBar.prefersLargeTitles = true

		let closeButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-close"), style: .plain, target: self, action: #selector(closeAction(_:)))
		closeButton.accessibilityLabel = NYXLocalizedString("lbl_close")
		navigationItem.leftBarButtonItem = closeButton

		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

		swShake = UISwitch()
		swShake.addTarget(self, action: #selector(toggleShakeToPlay(_:)), for: .valueChanged)

		swPrettyDB = UISwitch()
		swPrettyDB.addTarget(self, action: #selector(toggleUsePrettyDB(_:)), for: .valueChanged)

		swFuzzySearch = UISwitch()
		swFuzzySearch.addTarget(self, action: #selector(toggleFuzzySearch(_:)), for: .valueChanged)

		swDirectory = UISwitch()
		swDirectory.addTarget(self, action: #selector(toggleBrowseDir(_:)), for: .valueChanged)

		sColumns = UISegmentedControl(items: ["2", "3"])
		sColumns.addTarget(self, action: #selector(toggleColumns(_:)), for: .valueChanged)
		sColumns.frame = CGRect(0, 0, 64, swFuzzySearch.height)

		let margin = CGFloat(4)
		var x = view.width - CGFloat(32 * TintColorType.allCases.count) - CGFloat(margin * CGFloat(TintColorType.allCases.count)) - 16
		for c in TintColorType.allCases {
			let btn = ColorButton(frame: CGRect(x, 6, 32, 32), tintColorType: c)
			btn.isSelected = c.rawValue == Settings.shared.integer(forKey: .pref_tintColor)
			btn.addTarget(self, action: #selector(toggleTintColor(_:)), for: .touchUpInside)
			colorsButton.append(btn)

			x += 32 + margin
		}

		initializeTheming()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		tableView.reloadData()
	}

	// MARK: - IBActions
	@objc func toggleShakeToPlay(_ sender: Any?) {
		let shake = Settings.shared.bool(forKey: .pref_shakeToPlayRandom)
		Settings.shared.set(!shake, forKey: .pref_shakeToPlayRandom)
	}

	@objc func toggleUsePrettyDB(_ sender: Any?) {
		let pretty = Settings.shared.bool(forKey: .pref_usePrettyDB)
		Settings.shared.set(!pretty, forKey: .pref_usePrettyDB)
	}

	@objc func toggleFuzzySearch(_ sender: Any?) {
		let fuzzySearch = Settings.shared.bool(forKey: .pref_fuzzySearch)
		Settings.shared.set(!fuzzySearch, forKey: .pref_fuzzySearch)
	}

	@objc func toggleBrowseDir(_ sender: Any?) {
		let browseByDir = Settings.shared.bool(forKey: .pref_browseByDirectory)
		Settings.shared.set(!browseByDir, forKey: .pref_browseByDirectory)
		NotificationCenter.default.postOnMainThreadAsync(name: .changeBrowsingTypeNotification, object: nil)
	}

	@objc func toggleColumns(_ sender: Any?) {
		Settings.shared.set(sColumns.selectedSegmentIndex + 2, forKey: .pref_numberOfColumns)

		ImageCache.shared.clear(nil)

		NotificationCenter.default.postOnMainThreadAsync(name: .collectionViewLayoutShouldChange, object: nil)
	}

	@objc fileprivate func toggleTintColor(_ sender: ColorButton?) {
		guard let button = sender else { return }

		Settings.shared.set(button.tintColorType.rawValue, forKey: .pref_tintColor)

		themeProvider.currentTheme.tintColor = colorForTintColorType(button.tintColorType)
		themeProvider.currentTheme = themeProvider.currentTheme
	}

	@objc func closeAction(_ sender: Any?) {
		dismiss(animated: true, completion: nil)
		// lol ugly
		if let p = navigationController?.presentationController {
			p.delegate?.presentationControllerDidDismiss?(p)
		}
	}

	// MARK: - Private
	private func applicationVersionAndBuild() -> (version: String, build: String) {
		let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
		let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String

		return (version, build)
	}
}

// MARK: - UITableViewDataSource
extension SettingsVC {
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 4
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 2
		case 1:
			return 3
		case 2:
			return 1
		case 3:
			return 1
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
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_tint_color")
					cell?.selectionStyle = .none
					for btn in colorsButton {
						cell?.addSubview(btn)
					}
				} else if indexPath.row == 1 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_columns")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(sColumns)
				}
			} else if indexPath.section == 1 {
				if indexPath.row == 0 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_useprettydb")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swPrettyDB)
				} else if indexPath.row == 1 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_shaketoplayrandom")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swShake)
				} else if indexPath.row == 2 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_browse_by_dir")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swDirectory)
				}
			} else if indexPath.section == 2 {
				if indexPath.row == 0 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_fuzzysearch")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swFuzzySearch)
				}
			} else {
				if indexPath.row == 0 {
					let version = applicationVersionAndBuild()
					cell?.textLabel?.text = "Version \(version.version) (\(version.build))"
					cell?.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .ultraLight)
					cell?.textLabel?.textAlignment = .center
					cell?.selectionStyle = .none
				}
			}
		}

		cell?.backgroundColor = .secondarySystemGroupedBackground
		cell?.textLabel?.textColor = .secondaryLabel

		if indexPath.section == 0 {
			if indexPath.row == 0 {
				let tintAsInt = Settings.shared.integer(forKey: .pref_tintColor)
				for btn in colorsButton {
					btn.isSelected = btn.tintColorType.rawValue == tintAsInt
				}
			} else if indexPath.row == 1 {
				sColumns.frame = CGRect(UIScreen.main.bounds.width - 16 - sColumns.width, (cell!.height - sColumns.height) / 2, sColumns.size)
				sColumns.selectedSegmentIndex = Settings.shared.integer(forKey: .pref_numberOfColumns) - 2
			}
		} else if indexPath.section == 1 {
			if indexPath.row == 0 {
				swPrettyDB.frame = CGRect(UIScreen.main.bounds.width - 16 - swPrettyDB.width, (cell!.height - swPrettyDB.height) / 2, swPrettyDB.size)
				swPrettyDB.isOn = Settings.shared.bool(forKey: .pref_usePrettyDB)
			} else if indexPath.row == 1 {
				swShake.frame = CGRect(UIScreen.main.bounds.width - 16 - swShake.width, (cell!.height - swShake.height) / 2, swShake.size)
				swShake.isOn = Settings.shared.bool(forKey: .pref_shakeToPlayRandom)
			} else if indexPath.row == 2 {
				swDirectory.frame = CGRect(UIScreen.main.bounds.width - 16 - swDirectory.width, (cell!.height - swDirectory.height) / 2, swDirectory.size)
				swDirectory.isOn = Settings.shared.bool(forKey: .pref_browseByDirectory)
			}
		} else if indexPath.section == 2 {
			if indexPath.row == 0 {
				swFuzzySearch.frame = CGRect(UIScreen.main.bounds.width - 16 - swFuzzySearch.width, (cell!.height - swFuzzySearch.height) / 2, swFuzzySearch.size)
				swFuzzySearch.isOn = Settings.shared.bool(forKey: .pref_fuzzySearch)
			}
		} else {
			if indexPath.row == 0 {
				cell?.textLabel?.textColor = .label
			}
		}

		return cell!
	}
}

// MARK: - UITableViewDelegate
extension SettingsVC {
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return NYXLocalizedString("lbl_pref_appearance").uppercased()
		case 1:
			return NYXLocalizedString("lbl_behaviour").uppercased()
		case 2:
			return NYXLocalizedString("lbl_search").uppercased()
		default:
			return ""
		}
	}
}

extension SettingsVC: Themed {
	func applyTheme(_ theme: Theme) {
		swShake.onTintColor = theme.tintColor
		swPrettyDB.onTintColor = theme.tintColor
		swFuzzySearch.onTintColor = theme.tintColor
		swDirectory.onTintColor = theme.tintColor

		for btn in self.colorsButton {
			btn.layer.borderColor = UIColor.label.cgColor
		}

		tableView.reloadData()
	}
}

fileprivate final class ColorButton: UIButton {
	//
	private(set) var tintColorType: TintColorType

	init(frame: CGRect, tintColorType: TintColorType) {
		self.tintColorType = tintColorType

		super.init(frame: frame)

		self.circleize()
		self.backgroundColor = colorForTintColorType(tintColorType)
		self.layer.borderColor = UIColor.label.cgColor
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override var isSelected: Bool {
		willSet {
			self.layer.borderWidth = isSelected ? 2 : 0
		}

		didSet {
			self.layer.borderWidth = isSelected ? 2 : 0
		}
	}

	override var isHighlighted: Bool {
		willSet {
			self.layer.borderWidth = isHighlighted ? 2 : 0
		}

		didSet {
			self.layer.borderWidth = isHighlighted ? 2 : 0
		}
	}

	override var buttonType: UIButton.ButtonType {
		.custom
	}
}
