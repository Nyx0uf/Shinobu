import UIKit


final class PlaylistDetailVC : UIViewController
{
	// MARK: - Public properties
	// Selected album
	var playlist: Playlist

	// MARK: - Private properties
	// Header view (cover + album name, artist)
	@IBOutlet private var headerView: UIImageView! = nil
	// Header height constraint
	@IBOutlet private var headerHeightConstraint: NSLayoutConstraint! = nil
	// Dummy view for shadow
	@IBOutlet private var dummyView: UIView! = nil
	// Tableview for song list
	@IBOutlet private var tableView: TracksListTableView! = nil
	// Underlaying color view
	@IBOutlet private var colorView: UIView! = nil
	// Label in the navigationbar
	private var titleView: UILabel! = nil
	// Random button
	private var btnRandom: UIBarButtonItem! = nil
	// Repeat button
	private var btnRepeat: UIBarButtonItem! = nil

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		// Dummy
		self.playlist = Playlist(name: "")

		super.init(coder: aDecoder)
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Navigation bar title
		titleView = UILabel(frame: CGRect(.zero, 100.0, 44.0))
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
		navigationItem.titleView = titleView

		// Album header view
		//let coverSize = NSKeyedUnarchiver.unarchiveObject(with: Settings.shared.data(forKey: kNYXPrefCoversSize)!) as! NSValue
		let coverSize = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSValue.classForCoder()], from: Settings.shared.data(forKey: Settings.keys.coversSize)!) as? NSValue
		headerHeightConstraint.constant = (coverSize?.cgSizeValue)!.height

		// Dummy tableview host, to create a nice shadow effect
		dummyView.layer.shadowPath = UIBezierPath(rect: CGRect(-2.0, 5.0, view.width + 4.0, 4.0)).cgPath
		dummyView.layer.shadowRadius = 3.0
		dummyView.layer.shadowOpacity = 1.0
		dummyView.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
		dummyView.layer.masksToBounds = false

		// Tableview
		tableView.useDummy = true
		tableView.tableFooterView = UIView()
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Add navbar shadow
		if let navigationBar = navigationController?.navigationBar
		{
			navigationBar.layer.shadowPath = UIBezierPath(rect: CGRect(-2.0, navigationBar.frame.height - 2.0, navigationBar.frame.width + 4.0, 4.0)).cgPath
			navigationBar.layer.shadowRadius = 3.0
			navigationBar.layer.shadowOpacity = 1.0
			navigationBar.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
			navigationBar.layer.masksToBounds = false

			let loop = Settings.shared.bool(forKey: Settings.keys.mpd_repeat)
			btnRepeat = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-repeat").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(toggleRepeatAction(_:)))
			btnRepeat.tintColor = loop ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
			btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

			let rand = Settings.shared.bool(forKey: Settings.keys.mpd_shuffle)
			btnRandom = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-random").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(toggleRandomAction(_:)))
			btnRandom.tintColor = rand ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
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

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		// Remove navbar shadow
		if let navigationBar = navigationController?.navigationBar
		{
			navigationBar.layer.shadowPath = nil
			navigationBar.layer.shadowRadius = 0.0
			navigationBar.layer.shadowOpacity = 0.0
		}
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
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
			let attrs = NSMutableAttributedString(string: "\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))\n", attributes:[NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Medium", size: 14.0)!])
			attrs.append(NSAttributedString(string: "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))", attributes: [NSAttributedString.Key.font : UIFont(name: "HelveticaNeue", size: 13.0)!]))
			titleView.attributedText = attrs
		}
	}

	private func renamePlaylistAction()
	{
		let alertController = UIAlertController(title: "\(NYXLocalizedString("lbl_rename_playlist")) \(playlist.name)", message: nil, preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_save"), style: .default, handler: { alert -> Void in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text)
			{
				let errorAlert = UIAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel, handler: { alert -> Void in
				}))
				self.present(errorAlert, animated: true, completion: nil)
			}
			else
			{
				MusicDataSource.shared.renamePlaylist(playlist: self.playlist, newName: textField.text!) { (result: ActionResult<Void>) in
					if result.succeeded
					{
						MusicDataSource.shared.getListForDisplayType(.playlists) {
							DispatchQueue.main.async {
								self.updateNavigationTitle()
							}
						}
					}
					else
					{
						DispatchQueue.main.async {
							MessageView.shared.showWithMessage(message: result.messages.first!)
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
		let random = !prefs.bool(forKey: Settings.keys.mpd_shuffle)

		btnRandom.tintColor = random ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		prefs.set(random, forKey: Settings.keys.mpd_shuffle)
		prefs.synchronize()

		PlayerController.shared.setRandom(random)
	}

	@objc func toggleRepeatAction(_ sender: Any?)
	{
		let prefs = Settings.shared
		let loop = !prefs.bool(forKey: Settings.keys.mpd_repeat)

		btnRepeat.tintColor = loop ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		prefs.set(loop, forKey: Settings.keys.mpd_repeat)
		prefs.synchronize()

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

		PlayerController.shared.playPlaylist(playlist, shuffle: Settings.shared.bool(forKey: Settings.keys.mpd_shuffle), loop: Settings.shared.bool(forKey: Settings.keys.mpd_repeat), position: UInt32(indexPath.row))
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
			MusicDataSource.shared.removeTrackFromPlaylist(playlist: self.playlist, track: tracks[indexPath.row]) { (result: ActionResult<Void>) in
				if result.succeeded == false
				{
					DispatchQueue.main.async {
						MessageView.shared.showWithMessage(message: result.messages.first!)
					}
				}
				else
				{
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
		action.backgroundColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)

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
			MusicDataSource.shared.deletePlaylist(name: self.playlist.name) { (result: ActionResult<Void>) in
				if result.succeeded == false
				{
					MessageView.shared.showWithMessage(message: result.messages.first!)
				}
			}
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, renameAction, deleteAction]
	}
}
