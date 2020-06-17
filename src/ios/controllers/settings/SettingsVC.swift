import UIKit

final class SettingsVC: NYXTableViewController {
	// MARK: - Private properties
	// Use mpd_pretty_db switch
	private var swPrettyDB = UISwitch()
	// Shake to play switch
	private var swShake = UISwitch()
	// Fuzzy search switch
	private var swFuzzySearch = UISwitch()
	// Contextual search switch
	private var swContextualSearch = UISwitch()
	// Browse by directory switch
	private var swDirectory = UISwitch()
	// Number of columns control
	private var sColumns = UISegmentedControl(items: ["2", "3"])
	// Buttons for the tint color
	private var colorsButton = [ColorButton]()

	// MARK: - Initializers
	init() {
		super.init(style: .insetGrouped)
	}

	required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.titleView = nil
		title = NYXLocalizedString("lbl_section_settings")

		let closeButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-close"), style: .plain, target: self, action: #selector(closeAction(_:)))
		closeButton.accessibilityLabel = NYXLocalizedString("lbl_close")
		navigationItem.leftBarButtonItem = closeButton

		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.rowHeight = 44

		swShake.addTarget(self, action: #selector(toggleShakeToPlay(_:)), for: .valueChanged)
		swPrettyDB.addTarget(self, action: #selector(toggleUsePrettyDB(_:)), for: .valueChanged)
		swFuzzySearch.addTarget(self, action: #selector(toggleFuzzySearch(_:)), for: .valueChanged)
		swContextualSearch.addTarget(self, action: #selector(toggleContextualSearch(_:)), for: .valueChanged)
		swDirectory.addTarget(self, action: #selector(toggleBrowseDir(_:)), for: .valueChanged)
		sColumns.addTarget(self, action: #selector(toggleColumns(_:)), for: .valueChanged)

		let margin = CGFloat(4)
		var x = view.width - CGFloat(32 * TintColorType.allCases.count) - CGFloat(margin * CGFloat(TintColorType.allCases.count)) - 16
		for c in TintColorType.allCases {
			let btn = ColorButton(frame: CGRect(x, 6, 32, 32), tintColorType: c)
			btn.isSelected = c == AppDefaults.pref_tintColor
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
	@objc private func toggleShakeToPlay(_ sender: Any?) {
		AppDefaults.pref_shakeToPlayRandom.toggle()
	}

	@objc private func toggleUsePrettyDB(_ sender: Any?) {
		AppDefaults.pref_usePrettyDB.toggle()
	}

	@objc private func toggleFuzzySearch(_ sender: Any?) {
		AppDefaults.pref_fuzzySearch.toggle()
	}

	@objc private func toggleContextualSearch(_ sender: Any?) {
		AppDefaults.pref_contextualSearch.toggle()
	}

	@objc private func toggleBrowseDir(_ sender: Any?) {
		let browseByDir = AppDefaults.pref_browseByDirectory
		AppDefaults.pref_browseByDirectory = !browseByDir
		if browseByDir {
			AppDefaults.pref_shakeToPlayRandom = false
		}
		swShake.isEnabled = !swDirectory.isOn
		NotificationCenter.default.postOnMainThreadAsync(name: .changeBrowsingTypeNotification, object: nil)
	}

	@objc private func toggleColumns(_ sender: Any?) {
		AppDefaults.pref_numberOfColumns = sColumns.selectedSegmentIndex + 2

		ImageCache.shared.clear(nil)

		NotificationCenter.default.postOnMainThreadAsync(name: .collectionViewLayoutShouldChange, object: nil)
	}

	@objc private func toggleTintColor(_ sender: ColorButton?) {
		guard let button = sender else { return }

		AppDefaults.pref_tintColor = button.tintColorType

		themeProvider.currentTheme.tintColor = colorForTintColorType(button.tintColorType)
		themeProvider.currentTheme = themeProvider.currentTheme

		UIImpactFeedbackGenerator().impactOccurred()
	}

	@objc private func closeAction(_ sender: Any?) {
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
			return 2
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
					sColumns.translatesAutoresizingMaskIntoConstraints = false
					let yConstraint = NSLayoutConstraint(item: sColumns, attribute: .centerY, relatedBy: .equal, toItem: cell!.contentView, attribute: .centerY, multiplier: 1, constant: 0)
					let xConstraint = NSLayoutConstraint(item: sColumns, attribute: .trailing, relatedBy: .equal, toItem: cell!.contentView, attribute: .trailing, multiplier: 1, constant: -16)
					NSLayoutConstraint.activate([xConstraint, yConstraint])
				}
			} else if indexPath.section == 1 {
				if indexPath.row == 0 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_useprettydb")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swPrettyDB)
					swPrettyDB.translatesAutoresizingMaskIntoConstraints = false
					let yConstraint = NSLayoutConstraint(item: swPrettyDB, attribute: .centerY, relatedBy: .equal, toItem: cell!.contentView, attribute: .centerY, multiplier: 1, constant: 0)
					let xConstraint = NSLayoutConstraint(item: swPrettyDB, attribute: .trailing, relatedBy: .equal, toItem: cell!.contentView, attribute: .trailing, multiplier: 1, constant: -16)
					NSLayoutConstraint.activate([xConstraint, yConstraint])
				} else if indexPath.row == 1 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_browse_by_dir")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swDirectory)
					swDirectory.translatesAutoresizingMaskIntoConstraints = false
					let yConstraint = NSLayoutConstraint(item: swDirectory, attribute: .centerY, relatedBy: .equal, toItem: cell!.contentView, attribute: .centerY, multiplier: 1, constant: 0)
					let xConstraint = NSLayoutConstraint(item: swDirectory, attribute: .trailing, relatedBy: .equal, toItem: cell!.contentView, attribute: .trailing, multiplier: 1, constant: -16)
					NSLayoutConstraint.activate([xConstraint, yConstraint])
				} else if indexPath.row == 2 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_shaketoplayrandom")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swShake)
					swShake.translatesAutoresizingMaskIntoConstraints = false
					let yConstraint = NSLayoutConstraint(item: swShake, attribute: .centerY, relatedBy: .equal, toItem: cell!.contentView, attribute: .centerY, multiplier: 1, constant: 0)
					let xConstraint = NSLayoutConstraint(item: swShake, attribute: .trailing, relatedBy: .equal, toItem: cell!.contentView, attribute: .trailing, multiplier: 1, constant: -16)
					NSLayoutConstraint.activate([xConstraint, yConstraint])
				}
			} else if indexPath.section == 2 {
				if indexPath.row == 0 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_contextualsearch")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swContextualSearch)
					swContextualSearch.translatesAutoresizingMaskIntoConstraints = false
					let yConstraint = NSLayoutConstraint(item: swContextualSearch, attribute: .centerY, relatedBy: .equal, toItem: cell!.contentView, attribute: .centerY, multiplier: 1, constant: 0)
					let xConstraint = NSLayoutConstraint(item: swContextualSearch, attribute: .trailing, relatedBy: .equal, toItem: cell!.contentView, attribute: .trailing, multiplier: 1, constant: -16)
					NSLayoutConstraint.activate([xConstraint, yConstraint])
				} else if indexPath.row == 1 {
					cell?.textLabel?.text = NYXLocalizedString("lbl_fuzzysearch")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swFuzzySearch)
					swFuzzySearch.translatesAutoresizingMaskIntoConstraints = false
					let yConstraint = NSLayoutConstraint(item: swFuzzySearch, attribute: .centerY, relatedBy: .equal, toItem: cell!.contentView, attribute: .centerY, multiplier: 1, constant: 0)
					let xConstraint = NSLayoutConstraint(item: swFuzzySearch, attribute: .trailing, relatedBy: .equal, toItem: cell!.contentView, attribute: .trailing, multiplier: 1, constant: -16)
					NSLayoutConstraint.activate([xConstraint, yConstraint])
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

		if indexPath.section == 0 {
			if indexPath.row == 0 {
				for btn in colorsButton {
					btn.isSelected = btn.tintColorType == AppDefaults.pref_tintColor
				}
			} else if indexPath.row == 1 {
				sColumns.selectedSegmentIndex = AppDefaults.pref_numberOfColumns - 2
			}
		} else if indexPath.section == 1 {
			if indexPath.row == 0 {
				swPrettyDB.isOn = AppDefaults.pref_usePrettyDB
			} else if indexPath.row == 1 {
				swDirectory.isOn = AppDefaults.pref_browseByDirectory
			} else if indexPath.row == 2 {
				swShake.isOn = AppDefaults.pref_shakeToPlayRandom
				swShake.isEnabled = !swDirectory.isOn
			}
		} else if indexPath.section == 2 {
			if indexPath.row == 0 {
				swContextualSearch.isOn = AppDefaults.pref_contextualSearch
			} else if indexPath.row == 1 {
				swFuzzySearch.isOn = AppDefaults.pref_fuzzySearch
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

	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			if indexPath.row == 0 {
				let margin = CGFloat(4)
				var x = cell.width - CGFloat(32 * TintColorType.allCases.count) - CGFloat(margin * CGFloat(TintColorType.allCases.count)) - 16
				for btn in colorsButton {
					btn.frame = CGRect(x, 6, 32, 32)
					x += 32 + margin
				}
			}
		}
	}
}

extension SettingsVC: Themed {
	func applyTheme(_ theme: Theme) {
		swShake.onTintColor = theme.tintColor
		swPrettyDB.onTintColor = theme.tintColor
		swFuzzySearch.onTintColor = theme.tintColor
		swContextualSearch.onTintColor = theme.tintColor
		swDirectory.onTintColor = theme.tintColor

		for btn in self.colorsButton {
			btn.layer.borderColor = UIColor.label.cgColor
		}

		tableView.reloadData()
	}
}

fileprivate final class ColorButton: UIButton {
	// Tint color
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
