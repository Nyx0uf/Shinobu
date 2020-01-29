import UIKit

final class AlbumDetailVC: NYXViewController {
	// MARK: - Private properties
	// Selected album
	private let album: Album
	// Header view (cover + album name, artist)
	private var headerView: AlbumHeaderView! = nil
	// Tableview for song list
	private var tableView: TracksListTableView! = nil
	// Dummy view to color the nav bar
	private var colorView: UIView! = nil
	// MPD Data source
	private let mpdBridge: MPDBridge

	// MARK: - Initializers
	init(album: Album, mpdBridge: MPDBridge) {
		self.album = album
		self.mpdBridge = mpdBridge

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.frame = CGRect(.zero, view.width, view.height - heightForMiniPlayer())

		// Color under navbar
		var defaultHeight: CGFloat = UIDevice.current.isiPhoneX() ? 88 : 64
		if navigationController == nil {
			defaultHeight = 0
		} else {
			navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
		}
		colorView = UIView(frame: CGRect(0, 0, view.width, navigationController?.navigationBar.frame.maxY ?? defaultHeight))
		view.addSubview(colorView)

		// Album header view
		let coverSize = CGFloat(Settings.shared.integer(forKey: .coversSize))
		headerView = AlbumHeaderView(frame: CGRect(0, navigationController?.navigationBar.frame.maxY ?? defaultHeight, view.width, coverSize), coverSize: CGSize(coverSize, coverSize))
		view.addSubview(headerView)

		// Tableview
		tableView = TracksListTableView(frame: CGRect(0, headerView.maxY, view.width, view.height - headerView.maxY), style: .plain)
		tableView.delegate = self
		tableView.myDelegate = self
		tableView.tableFooterView = UIView()
		tableView.contentInsetAdjustmentBehavior = .never
		view.addSubview(tableView)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if let navigationBar = navigationController?.navigationBar {
			let appearance = UINavigationBarAppearance()
			appearance.configureWithDefaultBackground()
			appearance.shadowColor = .clear
			navigationBar.standardAppearance = appearance
		}

		// Update header
		updateHeader()

		// Get songs list if needed
		if let tracks = album.tracks {
			updateNavigationTitle()
			tableView.tracks = tracks
		} else {
			mpdBridge.getTracksForAlbums([album]) { [weak self] (tracks) in
				DispatchQueue.main.async {
					self?.updateNavigationTitle()
					self?.tableView.tracks = tracks ?? []
				}
			}
		}
	}

	// MARK: - Private
	private func updateHeader() {
		// Update header view
		headerView.updateHeaderWithAlbum(album)
		colorView.backgroundColor = headerView.backgroundColor

		// Don't have all the metadatas
		if album.artist.isEmpty {
			mpdBridge.getMetadatasForAlbum(album) { [weak self] in
				DispatchQueue.main.async {
					self?.updateHeader()
				}
			}
		}
	}

	override func updateNavigationTitle() {
		if let tracks = album.tracks {
			let total = tracks.reduce(Duration(seconds: 0)) { $0 + $1.duration }
			let minutes = total.seconds / 60
			titleView.setMainText("\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))", detailText: "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))")
		} else {
			titleView.setMainText("0 \(NYXLocalizedString("lbl_tracks"))", detailText: nil)
		}
	}
}

// MARK: - UITableViewDelegate
extension AlbumDetailVC: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Dummy cell
		guard let tracks = album.tracks else { return }
		if indexPath.row >= tracks.count {
			return
		}

		// Toggle play / pause for the current track
		if let currentPlayingTrack = mpdBridge.getCurrentTrack() {
			let selectedTrack = tracks[indexPath.row]
			if selectedTrack == currentPlayingTrack {
				mpdBridge.togglePause()
				return
			}
		}

		let b = tracks.filter { $0.trackNumber >= (indexPath.row + 1) }
		mpdBridge.playTracks(b, shuffle: false, loop: false)
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		// Dummy cell
		guard let tracks = album.tracks else { return nil }
		if indexPath.row >= tracks.count {
			return nil
		}

		let action = UIContextualAction(style: .normal, title: NYXLocalizedString("lbl_add_to_playlist")) { (_, _, completionHandler) in
			self.mpdBridge.entitiesForType(.playlists) { (_ ) in
				DispatchQueue.main.async {
					guard let cell = tableView.cellForRow(at: indexPath) else {
						return
					}

					let pvc = PlaylistsAddVC(mpdBridge: self.mpdBridge)
					let tvc = NYXNavigationController(rootViewController: pvc)
					pvc.trackToAdd = tracks[indexPath.row]
					tvc.modalPresentationStyle = .popover
					if let popController = tvc.popoverPresentationController {
						popController.permittedArrowDirections = [.up, .down]
						popController.sourceRect = cell.bounds
						popController.sourceView = cell
						popController.delegate = self
						tvc.preferredContentSize = CGSize(300, 200)
						self.present(tvc, animated: true, completion: nil)
					}
				}
			}
			completionHandler(true)
		}
		action.image = #imageLiteral(resourceName: "btn-playlist-add").withTintColor(.label)
		action.backgroundColor = self.themeProvider.currentTheme.tintColor

		return UISwipeActionsConfiguration(actions: [action])
	}
}

extension AlbumDetailVC: UIPopoverPresentationControllerDelegate {
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		.none
	}
}

extension AlbumDetailVC: TracksListTableViewDelegate {
	func getCurrentTrack() -> Track? {
		mpdBridge.getCurrentTrack()
	}
}

extension AlbumDetailVC: Themed {
	func applyTheme(_ theme: Theme) {
	}
}
