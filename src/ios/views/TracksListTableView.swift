import UIKit

protocol TracksListTableViewDelegate: class {
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
	// Cell identifier
	private let cellIdentifier = "fr.whine.shinobu.cell.track"
	//
	weak var myDelegate: TracksListTableViewDelegate?

	override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)

		self.dataSource = self
		self.register(TrackTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
		self.separatorStyle = .none
		self.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
		self.rowHeight = 44

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)

		initializeTheming()
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

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
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! TrackTableViewCell

		cell.isEvenCell = indexPath.row.isMultiple(of: 2)
		cell.lblTitle.textColor = .label
		cell.lblTrack.textColor = .label
		cell.lblDuration.textColor = .label
		cell.lblTitle.highlightedTextColor = themeProvider.currentTheme.tintColor
		cell.lblTrack.highlightedTextColor = themeProvider.currentTheme.tintColor
		cell.lblDuration.highlightedTextColor = themeProvider.currentTheme.tintColor

		let track = tracks[indexPath.row]
		cell.lblTrack.text = String(track.trackNumber)
		cell.lblTitle.text = track.name
		let minutes = track.duration.minutesRepresentation().minutes
		let seconds = track.duration.minutesRepresentation().seconds
		cell.lblDuration.text = "\(minutes):\(seconds < 10 ? "0" : "")\(seconds)"

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
		if minutes > 0 {
			stra += "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes")) "
		}
		if seconds > 0 {
			stra += "\(seconds) \(seconds == 1 ? NYXLocalizedString("lbl_second") : NYXLocalizedString("lbl_seconds"))"
		}
		cell.accessibilityLabel = stra

		let v = UIView()
		v.backgroundColor = themeProvider.currentTheme.tintColor.withAlphaComponent(0.2)
		cell.selectedBackgroundView = v

		return cell
	}
}

extension TracksListTableView: Themed {
	func applyTheme(_ theme: Theme) {
		reloadData()
	}
}
