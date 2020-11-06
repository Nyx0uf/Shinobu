import UIKit
import NotificationCenter

final class TodayViewController: UIViewController, NCWidgetProviding {
	// MARK: - Private properties
	// Track title
	@IBOutlet private var lblTrackTitle: UILabel!
	// Track artist name
	@IBOutlet private var lblTrackArtist: UILabel!
	// Album name
	@IBOutlet private var lblAlbumName: UILabel!
	// Play / pause button
	@IBOutlet private var btnPlay: UIButton!
	// Previous track button
	@IBOutlet private var btnPrevious: UIButton!
	// Next track button
	@IBOutlet private var btnNext: UIButton!
	// Cover view
	@IBOutlet private var imageView: UIImageView!
	// MPD data source
	private var mpdBridge = MPDBridge(usePrettyDB: false, isDirectoryBased: false)

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		AppDefaults.registerDefaults()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		btnNext.accessibilityLabel = NYXLocalizedString("lbl_next_track")
		btnPrevious.accessibilityLabel = NYXLocalizedString("lbl_previous_track")

		guard let server = ServersManager().getSelectedServer() else {
			disableAllBecauseCantWork()
			return
		}

		// Data source
		mpdBridge.server = server.mpd
		let resultDataSource = mpdBridge.initialize()
		switch resultDataSource {
		case .failure:
			disableAllBecauseCantWork()
		case .success:
			mpdBridge.entitiesForType(.albums) { (_) in }
			NotificationCenter.default.addObserver(self, selector: #selector(playingTrackNotification(_:)), name: .currentPlayingTrack, object: nil)
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		btnNext.setImage(#imageLiteral(resourceName: "btn-next").withTintColor(.label), for: .normal)
		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous").withTintColor(.label), for: .normal)
	}

	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		let ret = updateFields()
		completionHandler(ret ? NCUpdateResult.newData : NCUpdateResult.failed)
	}

	// MARK: - Actions
	@IBAction func togglePauseAction(_ sender: Any?) {
		mpdBridge.togglePause()
	}

	@IBAction func nextTrackAction(_ sender: Any?) {
		mpdBridge.requestNextTrack()
	}

	@IBAction func previousTrackAction(_ sender: Any?) {
		mpdBridge.requestPreviousTrack()
	}

	// MARK: - Private
	private func updateFields() -> Bool {
		var ret = true
		if let track = mpdBridge.getCurrentTrack() {
			lblTrackTitle.text = track.name
			lblTrackArtist.text = track.artist
		} else {
			ret = false
		}

		if let album = mpdBridge.getCurrentAlbum() {
			lblAlbumName.text = album.name
			handleCoverForAlbum(album)
		} else {
			ret = false
		}

		if mpdBridge.getCurrentState().status == .paused {
			let imgPlay = #imageLiteral(resourceName: "btn-play").withTintColor(.label)
			btnPlay.setImage(imgPlay, for: .normal)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		} else {
			let imgPause = #imageLiteral(resourceName: "btn-pause").withTintColor(.label)
			btnPlay.setImage(imgPause, for: .normal)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}

		return ret
	}

	private func handleCoverForAlbum(_ album: Album) {
		if let cover = album.asset(ofSize: .large) {
			imageView.image = imageView.frame.size == .zero ? cover : cover.smartCropped(toSize: imageView.frame.size)
		} else {
			mpdBridge.getPathForAlbum(album) {
				self.downloadCoverForAlbum(album) { (large: UIImage?, _: UIImage?, _: UIImage?) in
					let tmp = large?.smartCropped(toSize: self.imageView.frame.size)
					DispatchQueue.main.async {
						self.imageView.image = tmp
					}
				}
			}
		}
	}

	private func downloadCoverForAlbum(_ album: Album, callback: ((_ large: UIImage?, _ medium: UIImage?, _ small: UIImage?) -> Void)?) {
		var cop = CoverOperations(album: album)
		cop.processCallback = { (large: UIImage?, medium: UIImage?, small: UIImage?) in
			if let block = callback {
				block(large, medium, small)
			}
		}

		cop.submit()
	}

	private func disableAllBecauseCantWork() {
		btnPlay.isEnabled = false
		btnNext.isEnabled = false
		btnPrevious.isEnabled = false
		lblTrackTitle.text = "Error."
		lblTrackArtist.text = ""
		lblAlbumName.text = ""
	}

	// MARK: - Notification
	@objc private func playingTrackNotification(_ notification: Notification) {
		_ = updateFields()
	}
}
