import UIKit


final class PlaylistsAddVC: NYXTableViewController
{
	// List of artists
	var playlists = [Playlist]()
	// Track to add
	var trackToAdd: Track? = nil
	// Cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.playlist"
	// MPD Data source
	private let mpdBridge: MPDBridge

	// MARK: - Initializers
	init(mpdBridge: MPDBridge)
	{
		self.mpdBridge = mpdBridge

		super.init(style: .plain)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return Settings.shared.bool(forKey: .pref_themeDark) ? .lightContent : .default
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		navigationController?.navigationBar.isTranslucent = false

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		tableView.tableFooterView = UIView()

		// Create playlist button
		let createButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-add"), style: .plain, target: self, action: #selector(createPlaylistAction(_:)))
		createButton.accessibilityLabel = NYXLocalizedString("lbl_create_playlist")
		navigationItem.rightBarButtonItems = [createButton]

		initializeTheming()
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

		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_save"), style: .default) { (alert) in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text)
			{
				let errorAlert = NYXAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel))
				self.present(errorAlert, animated: true, completion: nil)
			}
			else
			{
				self.mpdBridge.createPlaylist(named: textField.text!) { [weak self] (result) in
					guard let strongSelf = self else { return }
					switch result
					{
						case .failure(let error):
							DispatchQueue.main.async {
								MessageView.shared.showWithMessage(message: error.message)
							}
						case .success( _):
							strongSelf.mpdBridge.entitiesForType(.playlists) { (entities) in
								DispatchQueue.main.async {
									strongSelf.getPlaylists()
								}
							}
					}
				}
			}
		})
		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel))

		alertController.addTextField() { (textField) in
			textField.placeholder = NYXLocalizedString("lbl_create_playlist_placeholder")
			textField.textAlignment = .left
		}

		present(alertController, animated: true, completion: nil)
	}

	// MARK: - Private
	private func getPlaylists()
	{
		mpdBridge.entitiesForType(.playlists) { (entities) in
			DispatchQueue.main.async {
				self.playlists = entities as! [Playlist]
				self.titleView.setMainText(NYXLocalizedString("lbl_playlists"), detailText: "(\(entities.count))")
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
		cell.backgroundColor = themeProvider.currentTheme.backgroundColorAlt
		cell.contentView.backgroundColor = themeProvider.currentTheme.backgroundColorAlt

		let playlist = playlists[indexPath.row]

		cell.textLabel?.text = playlist.name
		cell.textLabel?.textColor = themeProvider.currentTheme.tableCellMainLabelTextColor
		cell.textLabel?.highlightedTextColor = themeProvider.currentTheme.tintColor
		cell.textLabel?.isAccessibilityElement = false
		cell.accessibilityLabel = playlist.name

		let v = UIView()
		v.backgroundColor = themeProvider.currentTheme.tintColor.withAlphaComponent(0.2)
		cell.selectedBackgroundView = v

		return cell
	}
}

// MARK: - UITableViewDelegate
extension PlaylistsAddVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		guard let track = trackToAdd else
		{
			return
		}

		let playlist = playlists[indexPath.row]

		mpdBridge.addTrack(to: playlist, track: track) { (result) in
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

extension PlaylistsAddVC: Themed
{
	func applyTheme(_ theme: Theme)
	{
		navigationController?.navigationBar.barTintColor = theme.backgroundColorAlt
		tableView.separatorColor = theme.backgroundColor
		tableView.backgroundColor = theme.backgroundColorAlt
	}
}
