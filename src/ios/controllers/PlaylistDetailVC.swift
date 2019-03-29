import UIKit


final class PlaylistDetailVC : NYXViewController
{
	// MARK: - Public properties
	// Selected album
	var playlist: Playlist

	// MARK: - Private properties
	// Header view (cover + album name, artist)
	private var headerView: UIImageView! = nil
	// Tableview for song list
	private var tableView: TracksListTableView! = nil
	// Underlaying color view
	private var colorView: UIView! = nil
	// Random button
	private var btnRandom: UIBarButtonItem! = nil
	// Repeat button
	private var btnRepeat: UIBarButtonItem! = nil

	// MARK: - Initializers
	init(playlist: Playlist)
	{
		self.playlist = playlist
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Color under navbar
		colorView = UIView(frame: CGRect(0, 0, self.view.width, navigationController?.navigationBar.frame.maxY ?? 88))
		self.view.addSubview(colorView)

		// Album header view
		let coverSize = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSValue.self], from: Settings.shared.data(forKey: .coversSize)!) as? NSValue
		headerView = UIImageView(frame: CGRect(0, navigationController?.navigationBar.frame.maxY ?? 88, self.view.width, coverSize?.cgSizeValue.height ?? 88))
		self.view.addSubview(headerView)

		// Tableview
		tableView = TracksListTableView(frame: CGRect(0, headerView.bottom, self.view.width, self.view.height - headerView.bottom), style: .plain)
		tableView.useDummy = true
		tableView.delegate = self
		tableView.tableFooterView = UIView()
		self.view.addSubview(tableView)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Add navbar shadow
		if let _ = navigationController?.navigationBar
		{
			let loop = Settings.shared.bool(forKey: .mpd_repeat)
			btnRepeat = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-repeat").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(toggleRepeatAction(_:)))
			btnRepeat.tintColor = loop ? Colors.mainEnabled : Colors.main
			btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

			let rand = Settings.shared.bool(forKey: .mpd_shuffle)
			btnRandom = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-random").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(toggleRandomAction(_:)))
			btnRandom.tintColor = rand ? Colors.mainEnabled : Colors.main
			btnRandom.accessibilityLabel = NYXLocalizedString(rand ? "lbl_random_disable" : "lbl_random_enable")

			navigationItem.rightBarButtonItems = [btnRandom, btnRepeat]
		}

		// Update header
		updateHeader()

		// Get songs list if needed
		if let tracks = playlist.tracks
		{
			updateNavigationTitle()
			tableView.tracks = tracks
		}
		else
		{
			MusicDataSource.shared.getTracksForPlaylist(playlist) {
				DispatchQueue.main.async {
					self.updateNavigationTitle()
					self.tableView.tracks = self.playlist.tracks!
				}
			}
		}
	}

	// MARK: - Private
	private func updateHeader()
	{
		// Update header view
		let backgroundColor = UIColor(rgb: playlist.name.djb2())
		headerView.backgroundColor = backgroundColor
		colorView.backgroundColor = backgroundColor

		if let img = generateCoverFromString(playlist.name, size: headerView.size)
		{
			headerView.image = img
		}
	}

	private func updateNavigationTitle()
	{
		if let tracks = playlist.tracks
		{
			let total = tracks.reduce(Duration(seconds: 0)){$0 + $1.duration}
			let minutes = total.seconds / 60
			titleView.setMainText("\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))", detailText: "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))")
		}
	}

	private func renamePlaylistAction()
	{
		let alertController = NYXAlertController(title: "\(NYXLocalizedString("lbl_rename_playlist")) \(playlist.name)", message: nil, preferredStyle: .alert)

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
				MusicDataSource.shared.rename(playlist: self.playlist, withNewName: textField.text!) { (result: Result<Bool, MPDConnectionError>) in
					switch result
					{
						case .failure(let error):
							DispatchQueue.main.async {
								MessageView.shared.showWithMessage(message: error.message)
							}
						case .success( _):
							MusicDataSource.shared.getListForMusicalEntityType(.playlists) {
								DispatchQueue.main.async {
									self.updateNavigationTitle()
								}
							}
					}
				}
			}
		}))
		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel, handler: nil))

		alertController.addTextField(configurationHandler: { (textField) -> Void in
			textField.placeholder = NYXLocalizedString("lbl_rename_playlist_placeholder")
			textField.textAlignment = .left
		})

		self.present(alertController, animated: true, completion: nil)
	}

	// MARK: - Buttons actions
	@objc func toggleRandomAction(_ sender: Any?)
	{
		let prefs = Settings.shared
		let random = !prefs.bool(forKey: .mpd_shuffle)

		btnRandom.tintColor = random ? Colors.mainEnabled : Colors.main
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		prefs.set(random, forKey: .mpd_shuffle)

		PlayerController.shared.setRandom(random)
	}

	@objc func toggleRepeatAction(_ sender: Any?)
	{
		let prefs = Settings.shared
		let loop = !prefs.bool(forKey: .mpd_repeat)

		btnRepeat.tintColor = loop ? Colors.mainEnabled : Colors.main
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		prefs.set(loop, forKey: .mpd_repeat)

		PlayerController.shared.setRepeat(loop)
	}
}

// MARK: - UITableViewDelegate
extension PlaylistDetailVC : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Dummy cell
		guard let tracks = playlist.tracks else {return}
		if indexPath.row >= tracks.count
		{
			return
		}

		// Toggle play / pause for the current track
		if let currentPlayingTrack = PlayerController.shared.currentTrack
		{
			let selectedTrack = tracks[indexPath.row]
			if selectedTrack == currentPlayingTrack
			{
				PlayerController.shared.togglePause()
				return
			}
		}

		PlayerController.shared.playPlaylist(playlist, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat), position: UInt32(indexPath.row))
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
	{
		// Dummy cell
		guard let tracks = playlist.tracks else { return nil }
		if indexPath.row >= tracks.count
		{
			return nil
		}

		let action = UIContextualAction(style: .normal, title: NYXLocalizedString("lbl_remove_from_playlist"), handler: { (action, view, completionHandler ) in
			MusicDataSource.shared.removeTrack(from: self.playlist, track: tracks[indexPath.row]) { (result: Result<Bool, MPDConnectionError>) in
				switch result
				{
					case .failure(let error):
						DispatchQueue.main.async {
							MessageView.shared.showWithMessage(message: error.message)
						}
					case .success( _):
						MusicDataSource.shared.getTracksForPlaylist(self.playlist) {
							DispatchQueue.main.async {
								self.updateNavigationTitle()
								self.tableView.tracks = self.playlist.tracks!
							}
						}
				}
			}

			completionHandler(true)
		})
		action.image = #imageLiteral(resourceName: "btn-trash")
		action.backgroundColor = Colors.main

		return UISwipeActionsConfiguration(actions: [action])
	}
}

// MARK: - Peek & Pop
extension PlaylistDetailVC
{
	override var previewActionItems: [UIPreviewActionItem]
	{
		let playAction = UIPreviewAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action, viewController) in
			PlayerController.shared.playPlaylist(self.playlist, shuffle: false, loop: false)
			MiniPlayerView.shared.stayHidden = false
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action, viewController) in
			PlayerController.shared.playPlaylist(self.playlist, shuffle: true, loop: false)
			MiniPlayerView.shared.stayHidden = false
		}

		let renameAction = UIPreviewAction(title: NYXLocalizedString("lbl_rename_playlisr"), style: .default) { (action, viewController) in
			self.renamePlaylistAction()
			MiniPlayerView.shared.stayHidden = false
		}

		let deleteAction = UIPreviewAction(title: NYXLocalizedString("lbl_delete_playlist"), style: .destructive) { (action, viewController) in
			MusicDataSource.shared.deletePlaylist(named: self.playlist.name) { (result: Result<Bool, MPDConnectionError>) in
				switch result
				{
					case .failure(let error):
						DispatchQueue.main.async {
							MessageView.shared.showWithMessage(message: error.message)
						}
					case .success( _):
						break
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, renameAction, deleteAction]
	}
}
