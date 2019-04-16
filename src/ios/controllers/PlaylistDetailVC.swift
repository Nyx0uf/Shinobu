import UIKit


final class PlaylistDetailVC: NYXViewController
{
	// MARK: - Private properties
	// Selected playlist
	private let playlist: Playlist
	// Header view (cover + album name, artist)
	private var headerView: UIImageView! = nil
	// Tableview for song list
	private var tableView: TracksListTableView! = nil
	// Underlaying color view
	private var colorView: UIView! = nil
	// MPD Data source
	private let mpdBridge: MPDBridge

	// MARK: - Initializers
	init(playlist: Playlist, mpdBridge: MPDBridge)
	{
		self.playlist = playlist
		self.mpdBridge = mpdBridge

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Color under navbar
		var defaultHeight: CGFloat = UIDevice.current.isiPhoneX() ? 88 : 64
		if navigationController == nil
		{
			defaultHeight = 0
		}
		colorView = UIView(frame: CGRect(0, 0, view.width, navigationController?.navigationBar.frame.maxY ?? defaultHeight))
		view.addSubview(colorView)

		// Album header view
		let coverSize = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSValue.self], from: Settings.shared.data(forKey: .coversSize)!) as? NSValue
		headerView = UIImageView(frame: CGRect(0, navigationController?.navigationBar.frame.maxY ?? defaultHeight, view.width, coverSize?.cgSizeValue.height ?? defaultHeight))
		view.addSubview(headerView)

		// Tableview
		tableView = TracksListTableView(frame: CGRect(0, headerView.maxY, view.width, view.height - headerView.maxY), style: .plain)
		tableView.useDummy = true
		tableView.delegate = self
		tableView.myDelegate = self
		tableView.tableFooterView = UIView()
		view.addSubview(tableView)

		initializeTheming()
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

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
			mpdBridge.getTracksForPlaylist(playlist) { (tracks) in
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

		let string = playlist.name
		let bgColor = UIColor(rgb: string.djb2())
		if let img = UIImage.fromString(string, font: UIFont(name: "Chalkduster", size: headerView.size.width / 4)!, fontColor: bgColor.inverted(), backgroundColor: bgColor, maxSize: headerView.size)
		{
			headerView.image = img
		}
	}

	override func updateNavigationTitle()
	{
		if let tracks = playlist.tracks
		{
			let total = tracks.reduce(Duration(seconds: 0)) { $0 + $1.duration }
			let minutes = total.seconds / 60
			titleView.setMainText("\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))", detailText: "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))")
		}
		else
		{
			titleView.setMainText("0 \(NYXLocalizedString("lbl_tracks"))", detailText: nil)
		}
	}

	private func renamePlaylistAction()
	{
		let alertController = NYXAlertController(title: "\(NYXLocalizedString("lbl_rename_playlist")) \(playlist.name)", message: nil, preferredStyle: .alert)

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
				self.mpdBridge.rename(playlist: self.playlist, withNewName: textField.text!) { [weak self] (result) in
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
									strongSelf.updateNavigationTitle()
								}
							}
					}
				}
			}
		})
		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel))

		alertController.addTextField() { (textField) in
			textField.placeholder = NYXLocalizedString("lbl_rename_playlist_placeholder")
			textField.textAlignment = .left
		}

		present(alertController, animated: true, completion: nil)
	}
}

// MARK: - UITableViewDelegate
extension PlaylistDetailVC: UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Dummy cell
		guard let tracks = playlist.tracks else { return }
		if indexPath.row >= tracks.count
		{
			return
		}

		// Toggle play / pause for the current track
		if let currentPlayingTrack = mpdBridge.getCurrentTrack()
		{
			let selectedTrack = tracks[indexPath.row]
			if selectedTrack == currentPlayingTrack
			{
				mpdBridge.togglePause()
				return
			}
		}

		mpdBridge.playPlaylist(playlist, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat), position: UInt32(indexPath.row))
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
	{
		// Dummy cell
		guard let tracks = playlist.tracks else { return nil }
		if indexPath.row >= tracks.count
		{
			return nil
		}

		let action = UIContextualAction(style: .normal, title: NYXLocalizedString("lbl_remove_from_playlist")) { (action, view, completionHandler ) in
			self.mpdBridge.removeTrack(from: self.playlist, track: tracks[indexPath.row]) { [weak self] (result) in
				guard let strongSelf = self else { return }
				switch result
				{
					case .failure(let error):
						DispatchQueue.main.async {
							MessageView.shared.showWithMessage(message: error.message)
						}
					case .success( _):
						strongSelf.mpdBridge.getTracksForPlaylist(strongSelf.playlist) { (tracks) in
							DispatchQueue.main.async {
								strongSelf.updateNavigationTitle()
								strongSelf.tableView.tracks = strongSelf.playlist.tracks!
							}
						}
				}
			}

			completionHandler(true)
		}
		action.image = #imageLiteral(resourceName: "btn-trash")
		action.backgroundColor = self.themeProvider.currentTheme.tintColor

		return UISwipeActionsConfiguration(actions: [action])
	}
}

// MARK: - Peek & Pop
extension PlaylistDetailVC
{
	override var previewActionItems: [UIPreviewActionItem]
	{
		let playAction = UIPreviewAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action, viewController) in
			self.mpdBridge.playPlaylist(self.playlist, shuffle: false, loop: false)
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action, viewController) in
			self.mpdBridge.playPlaylist(self.playlist, shuffle: true, loop: false)
		}

		let renameAction = UIPreviewAction(title: NYXLocalizedString("lbl_rename_playlisr"), style: .default) { (action, viewController) in
			self.renamePlaylistAction()
		}

		let deleteAction = UIPreviewAction(title: NYXLocalizedString("lbl_delete_playlist"), style: .destructive) { (action, viewController) in
			self.mpdBridge.deletePlaylist(named: self.playlist.name) { (result) in
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
		}

		return [playAction, shuffleAction, renameAction, deleteAction]
	}
}

extension PlaylistDetailVC: TracksListTableViewDelegate
{
	func getCurrentTrack() -> Track?
	{
		return mpdBridge.getCurrentTrack()
	}
}

extension PlaylistDetailVC: Themed
{
	func applyTheme(_ theme: Theme)
	{

	}
}
