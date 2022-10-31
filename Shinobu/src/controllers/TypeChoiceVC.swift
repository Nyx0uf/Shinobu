import UIKit

protocol TypeChoiceVCDelegate: AnyObject {
	func didSelectDisplayType(_ type: MusicalEntityType)
}

final class TypeChoiceVC: NYXTableViewController {
	// MARK: - Public properties
	// Delegate
	weak var delegate: TypeChoiceVCDelegate?
	// Currently active type
	var selectedMusicalEntityType: MusicalEntityType = .albums

	// MARK: - Private properties
	private let musicalEntityTypes: [MusicalEntityType]

	// MARK: - Initializers
	init(musicalEntityTypes: [MusicalEntityType]) {
		self.musicalEntityTypes = musicalEntityTypes

		super.init(style: .plain)

		// TableView
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "fr.whine.shinobu.cell.type")
		self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		self.tableView.scrollsToTop = false
		self.tableView.isScrollEnabled = false
		self.tableView.tableFooterView = UIView()
		self.tableView.contentInset = UIEdgeInsets(top: 13, left: 0, bottom: 0, right: 0)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }
}

// MARK: - UITableViewDataSource
extension TypeChoiceVC {
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return musicalEntityTypes.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.shinobu.cell.type", for: indexPath)

		var title = ""
		let type = musicalEntityTypes[indexPath.row]

		switch type {
		case .albums:
			title = NYXLocalizedString("lbl_albums")
		case .artists:
			title = NYXLocalizedString("lbl_artists")
		case .albumsartists:
			title = NYXLocalizedString("lbl_albumartist")
		case .genres:
			title = NYXLocalizedString("lbl_genres")
		case .playlists:
			title = NYXLocalizedString("lbl_playlists")
		default:
			break
		}

		cell.textLabel?.text = title
		cell.textLabel?.highlightedTextColor = UIColor.shinobuTintColor
		cell.textLabel?.textAlignment = .center

		if type == selectedMusicalEntityType {
			cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
			cell.textLabel?.textColor = UIColor.shinobuTintColor
		} else {
			cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
			cell.textLabel?.textColor = .label
		}

		let view = UIView()
		view.backgroundColor = UIColor.shinobuTintColor.withAlphaComponent(0.2)
		cell.selectedBackgroundView = view

		return cell
	}
}

// MARK: - UITableViewDelegate
extension TypeChoiceVC {
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let type = musicalEntityTypes[indexPath.row]
		selectedMusicalEntityType = type
		delegate?.didSelectDisplayType(type)
		self.dismiss(animated: true, completion: nil)
	}
}
