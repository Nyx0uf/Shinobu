import UIKit


protocol TypeChoiceViewDelegate: class
{
	func didSelectDisplayType(_ typeAsInt: Int)
}


final class TypeChoiceView: UIView
{
	// MARK: - Public properties
	// Delegate
	weak var delegate: TypeChoiceViewDelegate? = nil
	// TableView
	private(set) var tableView: UITableView! = nil
	// Currently active type
	var selectedMusicalEntityType: MusicalEntityType = .albums

	// MARK: - Private properties
	private let musicalEntityTypes: [MusicalEntityType]

	// MARK: - Initializers
	init(frame: CGRect, musicalEntityTypes: [MusicalEntityType])
	{
		self.musicalEntityTypes = musicalEntityTypes

		super.init(frame: frame)
		self.backgroundColor = .black

		// TableView
		self.tableView = UITableView(frame: CGRect(.zero, frame.size), style: .plain)
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "fr.whine.shinobu.cell.type")
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.backgroundColor = self.backgroundColor
		self.tableView.showsVerticalScrollIndicator = false
		self.tableView.scrollsToTop = false
		self.tableView.isScrollEnabled = false
		self.tableView.separatorStyle = .none
		self.tableView.rowHeight = 44
		self.addSubview(self.tableView)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }
}

// MARK: - UITableViewDelegate
extension TypeChoiceView: UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return musicalEntityTypes.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.shinobu.cell.type", for: indexPath)
		cell.selectionStyle = .none
		cell.backgroundColor = .black
		cell.textLabel?.textAlignment = .center
		var title = ""
		let type = musicalEntityTypes[indexPath.row]

		switch type
		{
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
		if type == selectedMusicalEntityType
		{
			cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
			cell.textLabel?.textColor = Colors.main
			//cell.textLabel?.layer.cornerRadius = 5
			//cell.textLabel?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
			//cell.textLabel?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4)
		}
		else
		{
			cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
			cell.textLabel?.textColor = Colors.mainText
			cell.textLabel?.layer.cornerRadius = 0
			cell.textLabel?.backgroundColor = cell.backgroundColor
		}
		return cell
	}
}

// MARK: - UITableViewDelegate
extension TypeChoiceView: UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		let type = musicalEntityTypes[indexPath.row]
		selectedMusicalEntityType = type
		delegate?.didSelectDisplayType(type.rawValue)
		tableView.deselectRow(at: indexPath, animated: false)
	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
	{
		// lil bounce animation
		let cellRect = tableView.rectForRow(at: indexPath)

		cell.y = cell.y + tableView.height

		UIView.animate(withDuration: 0.5, delay: 0.1 * Double(indexPath.row), usingSpringWithDamping: 0.8, initialSpringVelocity: 10, options: UIView.AnimationOptions(), animations: {
			cell.frame = cellRect
		}, completion: nil)
	}
}
