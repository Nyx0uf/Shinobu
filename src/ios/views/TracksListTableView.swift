import UIKit


final class TracksListTableView : UITableView
{
	// MARK: - Public properties
	// Tracks list
	var tracks = [Track]()
	{
		didSet
		{
			DispatchQueue.main.async {
				self.reloadData()
			}
		}
	}
	// Should add a dummy cell at the end
	var useDummy = false

	override init(frame: CGRect, style: UITableView.Style)
	{
		super.init(frame: frame, style: style)

		self.dataSource = self
		self.register(TrackTableViewCell.classForCoder(), forCellReuseIdentifier: "fr.whine.mpdremote.cell.track")
		self.separatorStyle = .none
		self.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		self.rowHeight = 44.0

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
	}

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)

		self.dataSource = self
		self.register(TrackTableViewCell.classForCoder(), forCellReuseIdentifier: "fr.whine.mpdremote.cell.track")
		self.separatorStyle = .none
		self.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		self.rowHeight = 44.0

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
	}

	deinit
	{
		NotificationCenter.default.removeObserver(self)
	}

	// MARK: - Private
	@objc func playingTrackChangedNotification(_ notification: Notification)
	{
		self.reloadData()
	}
}

// MARK: - UITableViewDataSource
extension TracksListTableView : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return useDummy ? tracks.count + 1 : tracks.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.mpdremote.cell.track", for: indexPath) as! TrackTableViewCell

		// Dummy to let some space for the mini player
		if useDummy && indexPath.row == tracks.count
		{
			cell.lblTitle.text = ""
			cell.lblTrack.text = ""
			cell.lblDuration.text = ""
			cell.separator.isHidden = true
			cell.selectionStyle = .none
			return cell
		}

		cell.separator.isHidden = false
		cell.lblTitle.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		cell.lblTrack.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		cell.lblDuration.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

		let track = tracks[indexPath.row]
		cell.lblTrack.text = String(track.trackNumber)
		cell.lblTitle.text = track.name
		let minutes = track.duration.minutesRepresentation().minutes
		let seconds = track.duration.minutesRepresentation().seconds
		cell.lblDuration.text = "\(minutes):\(seconds < 10 ? "0" : "")\(seconds)"

		if PlayerController.shared.currentTrack == track
		{
			cell.lblTrack.font = UIFont(name: "HelveticaNeue-Bold", size: 10)
			cell.lblTitle.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 14)
			cell.lblDuration.font = UIFont(name: "HelveticaNeue-Medium", size: 10)
		}
		else
		{
			cell.lblTrack.font = UIFont(name: "HelveticaNeue", size: 10)
			cell.lblTitle.font = UIFont(name: "HelveticaNeue-Medium", size: 14)
			cell.lblDuration.font = UIFont(name: "HelveticaNeue-Light", size: 10)
		}

		// Accessibility
		var stra = "\(NYXLocalizedString("lbl_track")) \(track.trackNumber), \(track.name)\n"
		if minutes > 0
		{
			stra += "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes")) "
		}
		if seconds > 0
		{
			stra += "\(seconds) \(seconds == 1 ? NYXLocalizedString("lbl_second") : NYXLocalizedString("lbl_seconds"))"
		}
		cell.accessibilityLabel = stra

		return cell
	}
}
