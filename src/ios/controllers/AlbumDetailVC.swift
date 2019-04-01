import UIKit


final class AlbumDetailVC : NYXViewController
{
	// MARK: - Public properties
	// Selected album
	let album: Album

	// MARK: - Private properties
	// Header view (cover + album name, artist)
	private var headerView: AlbumHeaderView! = nil
	// Tableview for song list
	private var tableView: TracksListTableView! = nil
	// Dummy view to color the nav bar
	private var colorView: UIView! = nil
	// Random button
	private var btnRandom: UIBarButtonItem! = nil
	// Repeat button
	private var btnRepeat: UIBarButtonItem! = nil
	// MPD Data source
	private let mpdDataSource: MPDDataSource

	// MARK: - Initializers
	init(album: Album, mpdDataSource: MPDDataSource)
	{
		self.album = album
		self.mpdDataSource = mpdDataSource
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
		headerView = AlbumHeaderView(frame: CGRect(0, navigationController?.navigationBar.frame.maxY ?? 88, self.view.width, coverSize?.cgSizeValue.height ?? 88), coverSize: (coverSize?.cgSizeValue)!)
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
		if let tracks = album.tracks
		{
			updateNavigationTitle()
			tableView.tracks = tracks
		}
		else
		{
			mpdDataSource.getTracksForAlbums([album]) {
				DispatchQueue.main.async {
					self.updateNavigationTitle()
					self.tableView.tracks = self.album.tracks!
				}
			}
		}
	}

	// MARK: - Private
	private func updateHeader()
	{
		// Update header view
		headerView.updateHeaderWithAlbum(album)
		colorView.backgroundColor = headerView.backgroundColor

		// Don't have all the metadatas
		if album.artist.count == 0
		{
			mpdDataSource.getMetadatasForAlbum(album) {
				DispatchQueue.main.async {
					self.updateHeader()
				}
			}
		}
	}

	override func updateNavigationTitle()
	{
		if let tracks = album.tracks
		{
			let total = tracks.reduce(Duration(seconds: 0)){$0 + $1.duration}
			let minutes = total.seconds / 60
			titleView.setMainText("\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))", detailText: "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))")
		}
		else
		{
			titleView.setMainText("0 \(NYXLocalizedString("lbl_tracks"))", detailText: nil)
		}
	}

	// MARK: - Buttons actions
	@objc func toggleRandomAction(_ sender: Any?)
	{
		let random = !Settings.shared.bool(forKey: .mpd_shuffle)

		btnRandom.tintColor = random ? Colors.mainEnabled : Colors.main
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		Settings.shared.set(random, forKey: .mpd_shuffle)

		PlayerController.shared.setRandom(random)
	}

	@objc func toggleRepeatAction(_ sender: Any?)
	{
		let loop = !Settings.shared.bool(forKey: .mpd_repeat)

		btnRepeat.tintColor = loop ? Colors.mainEnabled : Colors.main
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		Settings.shared.set(loop, forKey: .mpd_repeat)

		PlayerController.shared.setRepeat(loop)
	}
}

// MARK: - UITableViewDelegate
extension AlbumDetailVC : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Dummy cell
		guard let tracks = album.tracks else { return }
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

		let b = tracks.filter({$0.trackNumber >= (indexPath.row + 1)})
		PlayerController.shared.playTracks(b, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
	{
		// Dummy cell
		guard let tracks = album.tracks else { return nil }
		if indexPath.row >= tracks.count
		{
			return nil
		}

		let action = UIContextualAction(style: .normal, title: NYXLocalizedString("lbl_add_to_playlist"), handler: { (action, view, completionHandler ) in
			self.mpdDataSource.getListForMusicalEntityType(.playlists) {
				if self.mpdDataSource.playlists.count == 0
				{
					return
				}

				DispatchQueue.main.async {
					guard let cell = tableView.cellForRow(at: indexPath) else
					{
						return
					}

					let vc = PlaylistsAddVC(mpdDataSource: self.mpdDataSource)
					let tvc = NYXNavigationController(rootViewController: vc)
					vc.trackToAdd = tracks[indexPath.row]
					tvc.modalPresentationStyle = .popover
					if let popController = tvc.popoverPresentationController
					{
						popController.permittedArrowDirections = [.up, .down]
						popController.sourceRect = cell.bounds
						popController.sourceView = cell
						popController.delegate = self
						popController.backgroundColor = Colors.backgroundAlt
						tvc.preferredContentSize = CGSize(300, 200)
						self.present(tvc, animated: true, completion: {
						});
					}
				}
			}
			completionHandler(true)
		})
		action.image = #imageLiteral(resourceName: "btn-playlist-add")
		action.backgroundColor = Colors.main

		return UISwipeActionsConfiguration(actions: [action])
	}
}

extension AlbumDetailVC : UIPopoverPresentationControllerDelegate
{
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
	{
		return .none
	}
}

// MARK: - Peek & Pop
extension AlbumDetailVC
{
	override var previewActionItems: [UIPreviewActionItem]
	{
		let playAction = UIPreviewAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action, viewController) in
			PlayerController.shared.playAlbum(self.album, shuffle: false, loop: false)
			MiniPlayerView.shared.stayHidden = false
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action, viewController) in
			PlayerController.shared.playAlbum(self.album, shuffle: true, loop: false)
			MiniPlayerView.shared.stayHidden = false
		}

		let addQueueAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action, viewController) in
			PlayerController.shared.addAlbumToQueue(self.album)
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, addQueueAction]
	}
}
