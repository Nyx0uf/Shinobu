import UIKit

protocol TracksListTableViewIPADDelegate: AnyObject {
	func getCurrentTrack() -> Track?
}

final class TracksListTableViewIPAD: UITableView {
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
	weak var myDelegate: TracksListTableViewIPADDelegate?

	override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)

		self.dataSource = self
		self.register(TrackTableViewCellIPAD.self, forCellReuseIdentifier: TrackTableViewCellIPAD.reuseIdentifier)
		self.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
		self.rowHeight = 54

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - Private
	@objc func playingTrackChangedNotification(_ notification: Notification) {
		reloadData()
	}
}

// MARK: - UITableViewDataSource
extension TracksListTableViewIPAD: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		tracks.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCellIPAD.reuseIdentifier, for: indexPath) as! TrackTableViewCellIPAD

		//cell.isEvenCell = indexPath.row.isMultiple(of: 2)
		cell.lblTrack.textColor = .secondaryLabel
		cell.lblTitle.textColor = .label
		cell.lblArtist.textColor = .secondaryLabel
		cell.lblDuration.textColor = .tertiaryLabel
		cell.lblTitle.highlightedTextColor = UIColor.shinobuTintColor
		cell.lblTrack.highlightedTextColor = UIColor.shinobuTintColor
		cell.lblArtist.highlightedTextColor = UIColor.shinobuTintColor
		cell.lblDuration.highlightedTextColor = UIColor.shinobuTintColor

		let track = tracks[indexPath.row]
		cell.lblTrack.text = String(track.trackNumber)
		cell.lblTitle.text = track.name
		cell.lblArtist.text = track.artist
		cell.lblDuration.text = track.duration.minutesDescription

		let currentTrack = myDelegate?.getCurrentTrack()
		if currentTrack != nil && currentTrack == track {
			cell.lblTrack.font = UIFont.systemFont(ofSize: 14, weight: .bold)
			cell.lblTitle.font = UIFont.systemFont(ofSize: 18, weight: .heavy)
			cell.lblArtist.font = UIFont.systemFont(ofSize: 18, weight: .bold)
			cell.lblDuration.font = UIFont.systemFont(ofSize: 14, weight: .bold)
		} else {
			cell.lblTrack.font = UIFont.systemFont(ofSize: 14, weight: .regular)
			cell.lblTitle.font = UIFont.systemFont(ofSize: 18, weight: .medium)
			cell.lblArtist.font = UIFont.systemFont(ofSize: 18, weight: .regular)
			cell.lblDuration.font = UIFont.systemFont(ofSize: 14, weight: .regular)
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
