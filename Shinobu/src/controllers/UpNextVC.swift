import UIKit

final class UpNextVC: NYXTableViewController {
	// MARK: - Private properties
	// MPD Data source
	private let mpdBridge: MPDBridge
	// Tracks list
	private var tracks = [Track]()

	// MARK: - Initializers
	init(mpdBridge: MPDBridge) {
		self.mpdBridge = mpdBridge

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		let closeButton = UIBarButtonItem(title: NYXLocalizedString("lbl_close"), style: .plain, target: self, action: #selector(doneAction(_:)))
		closeButton.accessibilityLabel = NYXLocalizedString("lbl_close")
		navigationItem.leftBarButtonItem = closeButton

		titleView.setMainText("Up Next", detailText: nil)
		titleView.isAccessibilityElement = false

		tableView.register(UpNextTableViewCell.self, forCellReuseIdentifier: UpNextTableViewCell.reuseIdentifier)

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		guard let track = mpdBridge.getCurrentTrack() else { return }

		getSongs(after: track.position)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}

	// MARK: - Buttons actions
	@objc private func doneAction(_ sender: Any?) {
		dismiss(animated: true, completion: nil)
	}

	// MARK: - Private
	private func getSongs(after: UInt32) {
		mpdBridge.getSongsOfCurrentQueue { [weak self] (tracks) in
			guard let strongSelf = self else { return }
			DispatchQueue.main.async {
				let t = tracks.filter {$0.position > after}.sorted(by: { $0.position < $1.position })
				strongSelf.tracks = t
				strongSelf.tableView.reloadData()
			}
		}
	}

	// MARK: - Notifications
	@objc func playingTrackChangedNotification(_ aNotification: Notification?) {
		guard let notif = aNotification, let userInfos = notif.userInfo else { return }

		guard let track = userInfos[PLAYER_TRACK_KEY] as? Track else { return }

		getSongs(after: track.position)
	}
}

// MARK: - UITableViewDataSource
extension UpNextVC {
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tracks.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: UpNextTableViewCell.reuseIdentifier, for: indexPath) as! UpNextTableViewCell
		cell.backgroundColor = .systemBackground
		cell.contentView.backgroundColor = cell.backgroundColor

		let track = tracks[indexPath.row]
		cell.lblTrack.text = track.name
		cell.lblArtistAlbum.text = "\(track.artist)"
		let minutes = track.duration.minutes
		let seconds = track.duration.seconds
		cell.lblDuration.text = "\(minutes):\(seconds < 10 ? "0" : "")\(seconds)"

		let v = UIView()
		v.backgroundColor = UIColor.shinobuTintColor.withAlphaComponent(0.2)
		cell.selectedBackgroundView = v

		// Accessibility
		var stra = "\(NYXLocalizedString("lbl_track")) \(track.trackNumber), \(track.name)\n"
		if track.duration.minutes > 0 {
			stra += "\(track.duration.minutes) \(track.duration.minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes")) "
		}
		if track.duration.seconds > 0 {
			stra += "\(track.duration.seconds) \(track.duration.seconds == 1 ? NYXLocalizedString("lbl_second") : NYXLocalizedString("lbl_seconds"))"
		}
		cell.accessibilityLabel = stra

		return cell
	}
}

// MARK: - UITableViewDelegate
extension UpNextVC {
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		if indexPath.row >= tracks.count {
			return
		}

		let b = tracks.filter { $0.position >= (indexPath.row + 1) }
		mpdBridge.playTracks(b, shuffle: false, loop: false)
	}
}
