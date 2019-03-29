import UIKit


final class PlaylistsAddVC : NYXTableViewController
{
	// List of artists
	var playlists = [Playlist]()
	// Track to add
	var trackToAdd: Track? = nil
	// Cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.playlist"

	// MARK: - Initializers
	init()
	{
		super.init(style: .plain)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		self.navigationController?.navigationBar.isTranslucent = false
		self.navigationController?.navigationBar.barTintColor = Colors.backgroundAlt

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.separatorColor = Colors.background
		tableView.backgroundColor = Colors.backgroundAlt

		titleView.setMainText(NYXLocalizedString("lbl_playlists"), detailText: nil)

		// Create playlist button
		let createButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-add"), style: .plain, target: self, action: #selector(createPlaylistAction(_:)))
		createButton.accessibilityLabel = NYXLocalizedString("lbl_create_playlist")
		navigationItem.rightBarButtonItems = [createButton]
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		getPlaylists()
	}

	// MARK: - Actions
	@objc func createPlaylistAction(_ sender: Any?)
	{
		let alertController = NYXAlertController(title: NYXLocalizedString("lbl_create_playlist_name"), message: nil, preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_save"), style: .default, handler: { alert -> Void in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text)
			{
				let errorAlert = NYXAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel, handler: { alert -> Void in
				}))
				self.present(errorAlert, animated: true, completion: nil)
			}
			else
			{
				MusicDataSource.shared.createPlaylist(named: textField.text!) { (result: Result<Bool, MPDConnectionError>) in
					switch result
					{
						case .failure(let error):
							DispatchQueue.main.async {
								MessageView.shared.showWithMessage(message: error.message)
							}
						case .success( _):
							MusicDataSource.shared.getListForMusicalEntityType(.playlists) {
								DispatchQueue.main.async {
									self.getPlaylists()
								}
							}
					}
				}
			}
		}))
		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel, handler: nil))

		alertController.addTextField(configurationHandler: { (textField) -> Void in
			textField.placeholder = NYXLocalizedString("lbl_create_playlist_placeholder")
			textField.textAlignment = .left
		})

		self.present(alertController, animated: true, completion: nil)
	}

	// MARK: - Private
	private func getPlaylists()
	{
		MusicDataSource.shared.getListForMusicalEntityType(.playlists) {
			DispatchQueue.main.async {
				self.playlists = MusicDataSource.shared.playlists
				self.tableView.reloadData()
			}
		}
	}
}

// MARK: - UITableViewDataSource
extension PlaylistsAddVC
{
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return playlists.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
		cell.backgroundColor = Colors.backgroundAlt
		cell.contentView.backgroundColor = Colors.backgroundAlt

		let playlist = playlists[indexPath.row]

		cell.textLabel?.text = playlist.name
		cell.textLabel?.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		cell.textLabel?.isAccessibilityElement = false
		cell.accessibilityLabel = playlist.name

		return cell
	}
}

// MARK: - UITableViewDelegate
extension PlaylistsAddVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		guard let track = trackToAdd else
		{
			return
		}

		let playlist = playlists[indexPath.row]

		MusicDataSource.shared.addTrack(to: playlist, track: track) { (result: Result<Bool, MPDConnectionError>) in
			DispatchQueue.main.async {
				switch result
				{
					case .failure(let error):
						MessageView.shared.showWithMessage(message: error.message)
					case .success( _):
						let str = "\(track.name) \(NYXLocalizedString("lbl_playlist_track_added")) \(playlist.name)"
						MessageView.shared.showWithMessage(message: Message(content: str, type: .success))
				}
			}
		}
	}
}
