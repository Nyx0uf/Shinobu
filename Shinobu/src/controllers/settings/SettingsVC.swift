import UIKit
import Defaults

private let tintButtonSize = CGFloat(32)
private let separatorMargin = CGFloat(16)

final class SettingsVC: NYXTableViewController {
	// MARK: - Private properties
	/// Section 0 - APPEARANCE
	// Number of columns control
	private var sColumns = UIDevice.current.isPad() ? UISegmentedControl(items: ["4", "5"]) :  UISegmentedControl(items: ["2", "3"])
	/// Section 1 - BEHAVIOUR
	// Browse by directory switch
	private var swDirectory = UISwitch()
	// Shake to play switch
	private var swShake = UISwitch()
	/// Section 2 - SEARCH
	// Contextual search switch
	private var swContextualSearch = UISwitch()
	// Fuzzy search switch
	private var swFuzzySearch = UISwitch()

	// MARK: - Initializers
	init() {
		super.init(style: .grouped)
	}

	required init?(coder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.titleView = nil
		title = NYXLocalizedString("lbl_section_settings")

		let closeButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(closeAction(_:)))
		closeButton.accessibilityLabel = NYXLocalizedString("lbl_close")
		navigationItem.leftBarButtonItem = closeButton

		tableView.separatorInset = UIEdgeInsets(top: 0, left: separatorMargin, bottom: 0, right: separatorMargin)
		tableView.rowHeight = 44 // Mandatory for positionning below

		// Set target/actions
		sColumns.addTarget(self, action: #selector(toggleColumnsAction(_:)), for: .valueChanged)
		swDirectory.addTarget(self, action: #selector(toggleBrowseDirAction(_:)), for: .valueChanged)
		swShake.addTarget(self, action: #selector(toggleShakeToPlayAction(_:)), for: .valueChanged)
		swContextualSearch.addTarget(self, action: #selector(toggleContextualSearchAction(_:)), for: .valueChanged)
		swFuzzySearch.addTarget(self, action: #selector(toggleFuzzySearchAction(_:)), for: .valueChanged)

		// Fully black navigation bar
		if let navigationBar = navigationController?.navigationBar {
			let opaqueAppearance = UINavigationBarAppearance()
			opaqueAppearance.configureWithOpaqueBackground()
			opaqueAppearance.shadowColor = .clear
			navigationBar.standardAppearance = opaqueAppearance
			navigationBar.scrollEdgeAppearance = opaqueAppearance
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		tableView.reloadData()
	}

	// MARK: - Actions
	@objc private func toggleColumnsAction(_ sender: Any?) {
		let diff = UIDevice.current.isPad() ? 4 : 2
		Defaults[.pref_numberOfColumns] = sColumns.selectedSegmentIndex + diff

		// Need to erase downloaded cover because the size will change
		ImageCache.shared.clear(nil)

		NotificationCenter.default.postOnMainThreadAsync(name: .collectionViewLayoutShouldChange, object: nil)
	}

	@objc private func toggleBrowseDirAction(_ sender: Any?) {
		Defaults[.pref_browseByDirectory].toggle()

		// Album doesn't meen a thing in directory mode, so disable shake
		if Defaults[.pref_browseByDirectory] {
			Defaults[.pref_shakeToPlayRandom] = false
			swShake.isOn = false
		}
		swShake.isEnabled = !swDirectory.isOn

		NotificationCenter.default.postOnMainThreadAsync(name: .changeBrowsingTypeNotification, object: nil)
	}

	@objc private func toggleShakeToPlayAction(_ sender: Any?) {
		Defaults[.pref_shakeToPlayRandom].toggle()
	}

	@objc private func toggleContextualSearchAction(_ sender: Any?) {
		Defaults[.pref_contextualSearch].toggle()
	}

	@objc private func toggleFuzzySearchAction(_ sender: Any?) {
		Defaults[.pref_fuzzySearch].toggle()
	}

	@objc private func closeAction(_ sender: Any?) {
		dismiss(animated: true, completion: nil)

		// lol ugly: force UIPresentationController delegate call, forgot why.
		if let p = navigationController?.presentationController {
			p.delegate?.presentationControllerDidDismiss?(p)
		}
	}

	// MARK: - Private
	private func applicationVersionAndBuild() -> (version: String, build: String) {
		guard let infoDictionnary = Bundle.main.infoDictionary else { return ("0", "0") }

		guard let version = infoDictionnary["CFBundleShortVersionString"] as? String else { return ("0", "0") }
		guard let build = infoDictionnary[kCFBundleVersionKey as String] as? String else { return (version, "0") }

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
			return 1 // Appearance
		case 1:
			return 2 // Behaviour
		case 2:
			return 2 // Search
		case 3:
			return 1 // Version
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
					// MARK: Columns
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_columns")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(sColumns)
					sColumns.translatesAutoresizingMaskIntoConstraints = false
					let yConstraint = NSLayoutConstraint(item: sColumns, attribute: .centerY, relatedBy: .equal, toItem: cell!.contentView, attribute: .centerY, multiplier: 1, constant: 0)
					let xConstraint = NSLayoutConstraint(item: sColumns, attribute: .trailing, relatedBy: .equal, toItem: cell!.contentView, attribute: .trailing, multiplier: 1, constant: -separatorMargin)
					NSLayoutConstraint.activate([xConstraint, yConstraint])
				}
			} else if indexPath.section == 1 {
				if indexPath.row == 0 {
					// MARK: Browse by directory
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_browse_by_dir")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swDirectory)
					swDirectory.translatesAutoresizingMaskIntoConstraints = false
					let yConstraint = NSLayoutConstraint(item: swDirectory, attribute: .centerY, relatedBy: .equal, toItem: cell!.contentView, attribute: .centerY, multiplier: 1, constant: 0)
					let xConstraint = NSLayoutConstraint(item: swDirectory, attribute: .trailing, relatedBy: .equal, toItem: cell!.contentView, attribute: .trailing, multiplier: 1, constant: -separatorMargin)
					NSLayoutConstraint.activate([xConstraint, yConstraint])
				} else if indexPath.row == 1 {
					// MARK: Shake to play
					cell?.textLabel?.text = NYXLocalizedString("lbl_pref_shaketoplayrandom")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swShake)
					swShake.translatesAutoresizingMaskIntoConstraints = false
					let yConstraint = NSLayoutConstraint(item: swShake, attribute: .centerY, relatedBy: .equal, toItem: cell!.contentView, attribute: .centerY, multiplier: 1, constant: 0)
					let xConstraint = NSLayoutConstraint(item: swShake, attribute: .trailing, relatedBy: .equal, toItem: cell!.contentView, attribute: .trailing, multiplier: 1, constant: -separatorMargin)
					NSLayoutConstraint.activate([xConstraint, yConstraint])
				}
			} else if indexPath.section == 2 {
				if indexPath.row == 0 {
					// MARK: Contextual search
					cell?.textLabel?.text = NYXLocalizedString("lbl_contextualsearch")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swContextualSearch)
					swContextualSearch.translatesAutoresizingMaskIntoConstraints = false
					let yConstraint = NSLayoutConstraint(item: swContextualSearch, attribute: .centerY, relatedBy: .equal, toItem: cell!.contentView, attribute: .centerY, multiplier: 1, constant: 0)
					let xConstraint = NSLayoutConstraint(item: swContextualSearch, attribute: .trailing, relatedBy: .equal, toItem: cell!.contentView, attribute: .trailing, multiplier: 1, constant: -separatorMargin)
					NSLayoutConstraint.activate([xConstraint, yConstraint])
				} else if indexPath.row == 1 {
					// MARK: Fuzzy search
					cell?.textLabel?.text = NYXLocalizedString("lbl_fuzzysearch")
					cell?.selectionStyle = .none
					cell?.contentView.addSubview(swFuzzySearch)
					swFuzzySearch.translatesAutoresizingMaskIntoConstraints = false
					let yConstraint = NSLayoutConstraint(item: swFuzzySearch, attribute: .centerY, relatedBy: .equal, toItem: cell!.contentView, attribute: .centerY, multiplier: 1, constant: 0)
					let xConstraint = NSLayoutConstraint(item: swFuzzySearch, attribute: .trailing, relatedBy: .equal, toItem: cell!.contentView, attribute: .trailing, multiplier: 1, constant: -separatorMargin)
					NSLayoutConstraint.activate([xConstraint, yConstraint])
				}
			} else {
				if indexPath.row == 0 {
					// MARK: Version
					let version = applicationVersionAndBuild()
					cell?.textLabel?.text = "Version \(version.version) (\(version.build))"
					cell?.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .ultraLight)
					cell?.textLabel?.backgroundColor = tableView.backgroundColor
					cell?.textLabel?.textAlignment = .center
					cell?.selectionStyle = .none
					cell?.backgroundColor = tableView.backgroundColor
					cell?.contentView.backgroundColor = tableView.backgroundColor
				}
			}
		}

		if indexPath.section == 0 {
			if indexPath.row == 0 {
				let diff = UIDevice.current.isPad() ? 4 : 2
				sColumns.selectedSegmentIndex = Defaults[.pref_numberOfColumns] - diff
			}
		} else if indexPath.section == 1 {
			if indexPath.row == 0 {
				swDirectory.isOn = Defaults[.pref_browseByDirectory]
			} else if indexPath.row == 1 {
				swShake.isOn = Defaults[.pref_shakeToPlayRandom]
				swShake.isEnabled = !swDirectory.isOn
			}
		} else if indexPath.section == 2 {
			if indexPath.row == 0 {
				swContextualSearch.isOn = Defaults[.pref_contextualSearch]
			} else if indexPath.row == 1 {
				swFuzzySearch.isOn = Defaults[.pref_fuzzySearch]
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
