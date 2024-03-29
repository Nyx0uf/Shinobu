import UIKit

protocol TracksListTableViewDelegate: AnyObject {
	func getCurrentTrack() -> Track?
}

final class TracksListTableView: UITableView {
	// MARK: - Public properties
	// Tracks list
	var tracks = [Track]() {
		didSet {
			DispatchQueue.main.async {
				self.reloadData()
			}
		}
	}
	//
	weak var myDelegate: TracksListTableViewDelegate?

	override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)

		self.dataSource = self
		self.register(TrackTableViewCell.self, forCellReuseIdentifier: TrackTableViewCell.reuseIdentifier)
		self.separatorStyle = .none
		self.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
		self.rowHeight = 44

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Private
	@objc func playingTrackChangedNotification(_ notification: Notification) {
		reloadData()
	}
}

// MARK: - UITableViewDataSource
extension TracksListTableView: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		tracks.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.reuseIdentifier, for: indexPath) as! TrackTableViewCell

		cell.isEvenCell = indexPath.row.isMultiple(of: 2)
		cell.lblTitle.textColor = .label
		cell.lblTrack.textColor = .label
		cell.lblDuration.textColor = .label
		cell.lblTitle.highlightedTextColor = UIColor.shinobuTintColor
		cell.lblTrack.highlightedTextColor = UIColor.shinobuTintColor
		cell.lblDuration.highlightedTextColor = UIColor.shinobuTintColor

		let track = tracks[indexPath.row]
		cell.lblTrack.text = String(track.trackNumber)
		cell.lblTitle.text = track.name
		cell.lblDuration.text = track.duration.minutesDescription

		let currentTrack = myDelegate?.getCurrentTrack()
		if currentTrack != nil && currentTrack == track {
			cell.lblTrack.font = UIFont.systemFont(ofSize: 10, weight: .bold)
			cell.lblTitle.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
			cell.lblDuration.font = UIFont.systemFont(ofSize: 10, weight: .regular)
		} else {
			cell.lblTrack.font = UIFont.systemFont(ofSize: 10, weight: .regular)
			cell.lblTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
			cell.lblDuration.font = UIFont.systemFont(ofSize: 10, weight: .light)
		}

		// Accessibility
		var stra = "\(NYXLocalizedString("lbl_track")) \(track.trackNumber), \(track.name)\n"
		if track.duration.minutes > 0 {
			stra += "\(track.duration.minutes) \(track.duration.minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes")) "
		}
		if track.duration.seconds > 0 {
			stra += "\(track.duration.seconds) \(track.duration.seconds == 1 ? NYXLocalizedString("lbl_second") : NYXLocalizedString("lbl_seconds"))"
		}
		cell.accessibilityLabel = stra

		// Selection highlight
		let v = UIView()
		v.backgroundColor = UIColor.shinobuTintColor.withAlphaComponent(0.2)
		cell.selectedBackgroundView = v

		return cell
	}
}
