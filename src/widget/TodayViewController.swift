import UIKit
import NotificationCenter


final class TodayViewController: UIViewController, NCWidgetProviding
{
	// MARK: - Properties
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
	// Can work flag
	private var canWork = true
	//
	private var mpdDataSource = MPDDataSource()

	override func viewDidLoad()
	{
		super.viewDidLoad()

		btnNext.accessibilityLabel = NYXLocalizedString("lbl_next_track")
		btnPrevious.accessibilityLabel = NYXLocalizedString("lbl_previous_track")

		guard let server = ServersManager().getSelectedServer() else
		{
			self.disableAllBecauseCantWork()
			canWork = false
			return
		}

		// Data source

		mpdDataSource.server = server.mpd
		let resultDataSource = mpdDataSource.initialize()
		switch resultDataSource
		{
			case .failure( _):
				self.disableAllBecauseCantWork()
				canWork = false
			case .success(_):
				mpdDataSource.getListForMusicalEntityType(.albums) {
				}
		}

		// Player
		PlayerController.shared.server = server.mpd
		let resultPlayer = PlayerController.shared.initialize()
		switch resultPlayer
		{
			case .failure( _):
				self.disableAllBecauseCantWork()
				canWork = false
			case .success(_):
				break
		}

		if canWork
		{
			NotificationCenter.default.addObserver(self, selector: #selector(playingTRackNotification(_:)), name: .currentPlayingTrack, object: nil)
		}
	}

	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void))
	{
		let ret = updateFields()
		completionHandler(ret == false ? NCUpdateResult.failed : NCUpdateResult.newData)
	}

	// MARK: - Actions
	@IBAction func togglePauseAction(_ sender: Any?)
	{
		PlayerController.shared.togglePause()
	}

	@IBAction func nextTrackAction(_ sender: Any?)
	{
		PlayerController.shared.requestNextTrack()
	}

	@IBAction func previousTrackAction(_ sender: Any?)
	{
		PlayerController.shared.requestPreviousTrack()
	}

	// MARK: - Private
	private func updateFields() -> Bool
	{
		var ret = true
		if let track = PlayerController.shared.currentTrack
		{
			lblTrackTitle.text = track.name
			lblTrackArtist.text = track.artist
		}
		else
		{
			ret = false
		}

		if let album = PlayerController.shared.currentAlbum
		{
			lblAlbumName.text = album.name
		}
		else
		{
			ret = false
		}

		if PlayerController.shared.currentStatus == .paused
		{
			let imgPlay = #imageLiteral(resourceName: "btn-play")
			btnPlay.setImage(imgPlay, for: .normal)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			let imgPause = #imageLiteral(resourceName: "btn-pause")
			btnPlay.setImage(imgPause, for: .normal)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}

		return ret
	}

	private func disableAllBecauseCantWork()
	{
		btnPlay.isEnabled = false
		btnNext.isEnabled = false
		btnPrevious.isEnabled = false
		lblTrackTitle.text = "Error."
		lblTrackArtist.text = ""
		lblAlbumName.text = ""
	}

	// MARK: - Notification
	@objc private func playingTRackNotification(_ notification: Notification)
	{
		_ = self.updateFields()
	}
}
