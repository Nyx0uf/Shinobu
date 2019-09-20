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
	private var mpdBridge = MPDBridge(usePrettyDB: false)

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		Settings.shared.initialize()
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
		guard let coverURL = album.localCoverURL else {
			return
		}

		if let cover = UIImage.loadFromFileURL(coverURL) {
			imageView.image = cover
		} else {
			let imgWidth = CGFloat(Settings.shared.integer(forKey: .coversSize))
			let cropSize = CGSize(imgWidth, imgWidth)
			if album.path != nil {
				downloadCoverForAlbum(album, cropSize: cropSize) { (_: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						self.imageView.image = thumbnail
					}
				}
			} else {
				mpdBridge.getPathForAlbum(album) {
					self.downloadCoverForAlbum(album, cropSize: cropSize) { (_: UIImage, thumbnail: UIImage) in
						DispatchQueue.main.async {
							self.imageView.image = thumbnail
						}
					}
				}
			}
		}
	}

	private func downloadCoverForAlbum(_ album: Album, cropSize: CGSize, callback: ((_ cover: UIImage, _ thumbnail: UIImage) -> Void)?) {
		var cop = CoverOperations(album: album, cropSize: cropSize, saveProcessed: true)
		cop.processCallback = { (cover: UIImage, thumbnail: UIImage) in
			if let block = callback {
				block(cover, thumbnail)
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
