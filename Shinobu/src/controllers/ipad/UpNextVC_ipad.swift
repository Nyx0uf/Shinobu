import UIKit

final class UpNextVCIPAD: NYXViewController {
	// MARK: - Private properties
	// MPD Data source
	private let mpdBridge: MPDBridge
	// Tableview for song list
	private var tableView = TracksListTableViewIPAD(frame: .zero, style: .plain)

	// MARK: - Initializers
	init(mpdBridge: MPDBridge) {
		self.mpdBridge = mpdBridge

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		// Prevent swipe to dismiss
		 isModalInPresentation = true

		// Fully black navigation bar
		if let navigationBar = navigationController?.navigationBar {
			let opaqueAppearance = UINavigationBarAppearance()
			opaqueAppearance.configureWithOpaqueBackground()
			opaqueAppearance.shadowColor = .clear
			navigationBar.standardAppearance = opaqueAppearance
			navigationBar.scrollEdgeAppearance = opaqueAppearance
			navigationBar.isTranslucent = false
		}

		let closeButton = UIBarButtonItem(title: NYXLocalizedString("lbl_close"), style: .plain, target: self, action: #selector(doneAction(_:)))
		closeButton.accessibilityLabel = NYXLocalizedString("lbl_close")
		navigationItem.leftBarButtonItem = closeButton

		titleView.setMainText("Up Next", detailText: nil)
		titleView.isAccessibilityElement = false

		// Tableview
		tableView.delegate = self
		tableView.myDelegate = self
		tableView.tableFooterView = UIView()
		tableView.contentInsetAdjustmentBehavior = .never
		view.addSubview(tableView)

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		tableView.frame = view.bounds

		guard let track = mpdBridge.getCurrentTrack() else { return }

		getSongs(after: track.position)
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
				strongSelf.tableView.tracks = t
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

// MARK: - UITableViewDelegate
extension UpNextVCIPAD: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		if indexPath.row >= self.tableView.tracks.count {
			return
		}

		let b = self.tableView.tracks.filter { $0.position >= (indexPath.row + 1) }
		mpdBridge.playTracks(b, shuffle: false, loop: false)
	}
}

extension UpNextVCIPAD: TracksListTableViewIPADDelegate {
	func getCurrentTrack() -> Track? {
		mpdBridge.getCurrentTrack()
	}
}
