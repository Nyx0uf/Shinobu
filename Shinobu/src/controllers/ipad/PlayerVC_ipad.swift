import UIKit
import Defaults

private let btnSize = CGFloat(44)

final class PlayerVCIPAD: NYXViewController {
	// MARK: - Private properties
	// MPD Data source
	private let mpdBridge: MPDBridge
	// Blurred view
	private let blurEffectView = UIVisualEffectView()
	// Cover
	private let coverView = UIImageView()
	// Track label
	private let sliderTrack = LabeledSlider()
	// Album & Artist labels
	private let lblArtist = ImagedLabel()
	private let lblAlbum = ImagedLabel()
	// Play / Pause button
	private let btnPlay = ControlButton()
	// Next button
	private let btnNext = ControlButton()
	// Previous button
	private let btnPrevious = ControlButton()
	// Random button
	private let btnRandom = ControlButton()
	// Repeat button
	private let btnRepeat = ControlButton()
	// Stop button
	private let btnStop = ControlButton()
	// Show queue button
	private let btnQueue = ControlButton()
	// Elapsed time
	private let vev_elapsed = UIVisualEffectView()
	private let lblElapsedDuration = UILabel()
	// Remaining time
	private let vev_remaining = UIVisualEffectView()
	private let lblRemainingDuration = UILabel()
	// Volume control
	private let sliderVolume = ImagedSlider(minImage: UIImage(systemName: "speaker")!, midImage: UIImage(systemName: "speaker.1")!, maxImage: UIImage(systemName: "speaker.3")!)
	// Motion effects
	private let motionEffectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
	private let motionEffectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
	// Taps
	private let singleTap = UITapGestureRecognizer()
	private let doubleTap = UITapGestureRecognizer()
	// Up next
	private let lblNextTrack = AutoScrollLabel()
	private let lblNextAlbumArtist = AutoScrollLabel()
	// Current cover
	private var imgCover: UIImage?
	// Local URL for the cover
	private(set) lazy var localCoverURL: URL = {
		let cachesDirectoryURL = FileManager.default.cachesDirectory()
		let coversDirectoryURL = cachesDirectoryURL.appendingPathComponent(Defaults[.coversDirectory], isDirectory: true)
		if FileManager.default.fileExists(atPath: coversDirectoryURL.absoluteString) == false {
			try! FileManager.default.createDirectory(at: coversDirectoryURL, withIntermediateDirectories: true, attributes: nil)
		}
		return coversDirectoryURL
	}()

	init(mpdBridge: MPDBridge) {
		self.mpdBridge = mpdBridge

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		[.landscapeLeft, .landscapeRight]
	}

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		let width = ceil(UIScreen.main.bounds.width / 3)
		let coverSize = width - 32
		let marginLeft = CGFloat(16)

		// Blurred background
		view = UIImageView(image: nil)
		view.frame = CGRect(UIScreen.main.bounds.width - width, 0, width, UIScreen.main.bounds.height)
		view.isUserInteractionEnabled = true

		blurEffectView.effect = UIBlurEffect(style: .dark)
		blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)

		// Elapsed label
		let sizeTimeLabels = CGSize(40, 16)
		vev_elapsed.frame = CGRect(marginLeft, 40, sizeTimeLabels)
		vev_elapsed.effect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark))
		lblElapsedDuration.frame = vev_elapsed.bounds
		lblElapsedDuration.font = UIFont.systemFont(ofSize: 12, weight: .bold)
		lblElapsedDuration.textColor = UIColor(rgb: 0xFFFFFF)
		lblElapsedDuration.textAlignment = .left
		vev_elapsed.contentView.addSubview(lblElapsedDuration)
		blurEffectView.contentView.addSubview(vev_elapsed)

		// Remaining label
		vev_remaining.frame = CGRect(width - marginLeft - sizeTimeLabels.width, 40, sizeTimeLabels)
		vev_remaining.effect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark))
		lblRemainingDuration.frame = vev_remaining.bounds
		lblRemainingDuration.font = UIFont.systemFont(ofSize: 12, weight: .bold)
		lblRemainingDuration.textColor = UIColor(rgb: 0xFFFFFF)
		lblRemainingDuration.textAlignment = .right
		vev_remaining.contentView.addSubview(lblRemainingDuration)
		blurEffectView.contentView.addSubview(vev_remaining)

		// Track pos & title (full)
		sliderTrack.frame = CGRect(marginLeft, vev_remaining.maxY + 10, width - 2 * marginLeft, 32)
		sliderTrack.addTarget(self, action: #selector(changeTrackPositionAction(_:)), for: .touchUpInside)
		sliderTrack.label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
		sliderTrack.label.textColor = UIColor(rgb: 0xFFFFFF)
		sliderTrack.label.textAlignment = .center
		blurEffectView.contentView.addSubview(sliderTrack)

		// Artist (full)
		lblArtist.frame = CGRect(sliderTrack.x, sliderTrack.maxY + 10, 100, 20)
		lblArtist.image = UIImage(systemName: "mic")!.withTintColor(.white).withRenderingMode(.alwaysOriginal)
		lblArtist.highlightedImage = UIImage(systemName: "mic.fill")!.withTintColor(.label).withRenderingMode(.alwaysOriginal)
		lblArtist.textColor = .secondaryLabel
		lblArtist.highlightedTextColor = .label
		lblArtist.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
		lblArtist.underlined = true
		lblArtist.addTarget(self, action: #selector(showArtistAction(_:)), for: .touchUpInside)
		blurEffectView.contentView.addSubview(lblArtist)

		// Album (full)
		lblAlbum.align = .right
		lblAlbum.frame = CGRect(width - 100 - marginLeft, sliderTrack.maxY + 10, 100, 20)
		lblAlbum.image = UIImage(systemName: "opticaldisc")!.withTintColor(.white).withRenderingMode(.alwaysOriginal)
		lblAlbum.highlightedImage = UIImage(systemName: "opticaldisc.fill")!.withTintColor(.label).withRenderingMode(.alwaysOriginal)
		lblAlbum.textColor = .secondaryLabel
		lblAlbum.highlightedTextColor = .label
		lblAlbum.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
		lblAlbum.underlined = true
		lblAlbum.addTarget(self, action: #selector(showAlbumAction(_:)), for: .touchUpInside)
		blurEffectView.contentView.addSubview(lblAlbum)

		// Cover view
		coverView.frame = CGRect(16, lblAlbum.maxY + 16, coverSize, coverSize)
		coverView.backgroundColor = .black
		coverView.isUserInteractionEnabled = true
		coverView.layer.shadowColor = UIColor(rgb: 0x222222).cgColor
		coverView.layer.shadowRadius = 1
		coverView.layer.shadowOffset = CGSize(0, 1)
		coverView.layer.cornerRadius = 5
		coverView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		coverView.layer.masksToBounds = true
		blurEffectView.contentView.addSubview(coverView)

		// Next button
		btnNext.frame = CGRect(coverView.maxX - btnSize, coverView.frame.maxY + 10, btnSize, btnSize)
		btnNext.addTarget(mpdBridge, action: #selector(MPDBridge.requestNextTrack), for: .touchUpInside)
		btnNext.isAccessibilityElement = true
		btnNext.setImage(UIImage(systemName: "forward.end")!, tintColor: .secondaryLabel, selectedTintColor: .label)
		blurEffectView.contentView.addSubview(btnNext)

		// Previous button
		btnPrevious.frame = CGRect(marginLeft, coverView.frame.maxY + 10, btnSize, btnSize)
		btnPrevious.addTarget(mpdBridge, action: #selector(MPDBridge.requestPreviousTrack), for: .touchUpInside)
		btnPrevious.isAccessibilityElement = true
		btnPrevious.setImage(UIImage(systemName: "backward.end")!, tintColor: .secondaryLabel, selectedTintColor: .label)
		blurEffectView.contentView.addSubview(btnPrevious)

		// Play / Pause button
		let ww = btnSize * 2 + marginLeft
		btnPlay.frame = CGRect((width - ww) / 2, btnNext.y, btnSize, btnSize)
		btnPlay.addTarget(self, action: #selector(changePlaybackAction(_:)), for: .touchUpInside)
		btnPlay.tag = PlayerStatus.stopped.rawValue
		btnPlay.isAccessibilityElement = true
		btnPlay.setImage(UIImage(systemName: "play")!, tintColor: .secondaryLabel, selectedTintColor: .label)
		blurEffectView.contentView.addSubview(btnPlay)

		// Stop button
		btnStop.frame = CGRect(btnPlay.maxX + marginLeft, btnPlay.y, btnSize, btnSize)
		btnStop.addTarget(mpdBridge, action: #selector(MPDBridge.stop), for: .touchUpInside)
		btnStop.setImage(UIImage(systemName: "stop")!, tintColor: .secondaryLabel, selectedTintColor: .label)
		blurEffectView.contentView.addSubview(btnStop)

		// Random button
		btnRandom.frame = CGRect(marginLeft, btnPlay.maxY + 16, btnSize, btnSize)
		btnRandom.setImage(UIImage(systemName: "shuffle")!, tintColor: .secondaryLabel, selectedTintColor: .label)
		btnRandom.addTarget(self, action: #selector(toggleRandomAction(_:)), for: .touchUpInside)
		blurEffectView.contentView.addSubview(btnRandom)

		// Repeat button
		btnRepeat.frame = CGRect(width - marginLeft - btnSize, btnPlay.maxY + 16, btnSize, btnSize)
		btnRepeat.setImage(UIImage(systemName: "repeat")!, tintColor: .secondaryLabel, selectedTintColor: .label)
		btnRepeat.addTarget(self, action: #selector(toggleRepeatAction(_:)), for: .touchUpInside)
		self.blurEffectView.contentView.addSubview(btnRepeat)

		// Slider volume
		sliderVolume.frame = CGRect(marginLeft, btnRepeat.maxY + 16, width - 2 * marginLeft, 32)
		sliderVolume.addTarget(self, action: #selector(changeVolumeAction(_:)), for: .touchUpInside)
		sliderVolume.minimumValue = 0
		sliderVolume.maximumValue = 100
		blurEffectView.contentView.addSubview(sliderVolume)

		// Queue button
		btnQueue.frame = CGRect(marginLeft, view.height - btnSize, btnSize, btnSize)
		btnQueue.addTarget(self, action: #selector(showUpNextAction(_:)), for: .touchUpInside)
		btnQueue.setImage(UIImage(systemName: "music.note.list")!, tintColor: .secondaryLabel, selectedTintColor: .label)
		blurEffectView.contentView.addSubview(btnQueue)

		// Next track
		lblNextTrack.frame = CGRect(btnQueue.maxX + marginLeft, btnQueue.y, width - btnQueue.maxX - marginLeft - marginLeft - marginLeft - btnSize, 20)
		lblNextTrack.textAlignment = .center
		lblNextTrack.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
		lblNextTrack.textColor = .secondaryLabel
		lblNextTrack.isAccessibilityElement = false
		lblNextTrack.scrollSpeed = 60
		blurEffectView.contentView.addSubview(lblNextTrack)

		// Next artist + album
		lblNextAlbumArtist.frame = CGRect(btnQueue.maxX + marginLeft, lblNextTrack.maxY, width - btnQueue.maxX - marginLeft - marginLeft - marginLeft - btnSize, 20)
		lblNextAlbumArtist.textAlignment = .center
		lblNextAlbumArtist.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
		lblNextAlbumArtist.textColor = .secondaryLabel
		lblNextAlbumArtist.isAccessibilityElement = false
		blurEffectView.contentView.addSubview(lblNextAlbumArtist)

		// Useless motion effect
		motionEffectX.minimumRelativeValue = 20
		motionEffectX.maximumRelativeValue = -20
		motionEffectY.minimumRelativeValue = 20
		motionEffectY.maximumRelativeValue = -20

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackNotification(_:)), name: .currentPlayingTrack, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(playerStatusChangedNotification(_:)), name: .playerStatusChanged, object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		.lightContent
	}

	override var prefersHomeIndicatorAutoHidden: Bool {
		true
	}

	// MARK: - Buttons actions
	@objc func changePlaybackAction(_ sender: UIButton?) {
		if btnPlay.tag == PlayerStatus.stopped.rawValue {
			mpdBridge.play()
		} else {
			mpdBridge.togglePause()
		}
	}

	@objc func toggleRandomAction(_ sender: Any?) {
		mpdBridge.toggleRandom()
	}

	@objc func toggleRepeatAction(_ sender: Any?) {
		mpdBridge.toggleRepeat()
	}

	@objc func changeTrackPositionAction(_ sender: Slider?) {
		if let track = mpdBridge.getCurrentTrack() {
			mpdBridge.setTrackPosition(Int(sliderTrack.value), trackPosition: track.position)
		}
	}

	@objc func changeVolumeAction(_ sender: Slider?) {
		let tmp = clamp(ceil(sliderVolume.value), lower: 0, upper: 100)
		let volume = Int(tmp)

		mpdBridge.setVolume(volume) { (success) in
			if success {
				DispatchQueue.main.async {
					self.sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(volume)%"
				}
			}
		}
	}

	@objc func showUpNextAction(_ sender: Any?) {
		let uvc = UpNextVCIPAD(mpdBridge: mpdBridge)
		let nvc = NYXNavigationController(rootViewController: uvc)
		present(nvc, animated: true, completion: nil)
	}

	@objc func showArtistAction(_ sender: Any?) {
		NotificationCenter.default.postOnMainThreadAsync(name: .showArtistNotification, object: lblArtist.text)
	}

	@objc func showAlbumAction(_ sender: Any?) {
		if let album = mpdBridge.getCurrentAlbum() {
			NotificationCenter.default.postOnMainThreadAsync(name: .showAlbumNotification, object: album)
		}
	}

	// MARK: - Notifications
	@objc func playingTrackNotification(_ aNotification: Notification?) {
		guard let notif = aNotification, let userInfos = notif.userInfo else { return }

		guard let track = userInfos[PLAYER_TRACK_KEY] as? Track, let elapsed = userInfos[PLAYER_ELAPSED_KEY] as? Int else { return }

		// Update track position slider if not panning the slider
		if !sliderTrack.isHighlighted && !sliderTrack.isSelected {
			sliderTrack.value = CGFloat(elapsed)
			sliderTrack.accessibilityLabel = "\(NYXLocalizedString("lbl_track_position")) : \(Int((sliderTrack.value * 100) / sliderTrack.maximumValue))%"
		}

		var elapsedDuration = Duration(seconds: UInt(elapsed))
		var remainingDuration = track.duration - elapsedDuration
		lblElapsedDuration.text = elapsedDuration.minutesDescription
		lblRemainingDuration.text = "-\(remainingDuration.minutesDescription)"

		updateRandomAndRepeatState()
	}

	@objc func playingTrackChangedNotification(_ aNotification: Notification?) {
		guard let notif = aNotification, let userInfos = notif.userInfo else { return }

		guard let track = userInfos[PLAYER_TRACK_KEY] as? Track, let album = userInfos[PLAYER_ALBUM_KEY] as? Album else { return }

		if mpdBridge.isDirectoryBased {
			let songURL = URL(fileURLWithPath: track.uri)
			let dirPath = songURL.deletingLastPathComponent().absoluteString
			let hashedUri = dirPath.sha256() + ".jpg"

			let coverURL = self.localCoverURL.appendingPathComponent(hashedUri)
			if let cover = UIImage.loadFromFileURL(coverURL) {
				DispatchQueue.main.async {
					self.imgCover = cover
					UIView.transition(with: self.view, duration: 0.35, options: .transitionCrossDissolve, animations: {
						(self.view as? UIImageView)?.image = cover
						self.sliderTrack.label.text = track.name
						self.sliderTrack.maximumValue = CGFloat(track.duration.value)
						self.lblArtist.text = track.artist
						self.lblAlbum.text = album.name
					}, completion: nil)
					self.updatePlayPauseState()
				}
			} else {
				self.mpdBridge.getCoverForDirectoryAtPath(track.uri) { [weak self] (data: Data) in
					guard let strongSelf = self else { return }

					DispatchQueue.global(qos: .userInteractive).async {
						guard let img = UIImage(data: data) else { return }

						let cropSize = CoverOperations.cropSizes()[.large]!
						if let cropped = img.smartCropped(toSize: cropSize, highQuality: false, screenScale: true) {
							DispatchQueue.main.async {
								strongSelf.imgCover = cropped
								UIView.transition(with: strongSelf.view, duration: 0.35, options: .transitionCrossDissolve, animations: {
									(strongSelf.view as? UIImageView)?.image = cropped
									strongSelf.sliderTrack.label.text = track.name
									strongSelf.sliderTrack.maximumValue = CGFloat(track.duration.value)
									strongSelf.lblArtist.text = track.artist
									strongSelf.lblAlbum.text = album.name
								}, completion: nil)
								strongSelf.updatePlayPauseState()
							}

							_ = cropped.save(url: coverURL)
						}
					}
				}
			}

			return
		}

		// Update cover if from another album (playlist case)
		if let cover = album.asset(ofSize: .large) {
			DispatchQueue.main.async {
				self.imgCover = cover
				UIView.transition(with: self.view, duration: 0.35, options: .transitionCrossDissolve, animations: {
					(self.view as? UIImageView)?.image = cover
					self.sliderTrack.label.text = track.name
					self.sliderTrack.maximumValue = CGFloat(track.duration.value)
					self.lblArtist.text = track.artist
					self.lblAlbum.text = album.name
				}, completion: nil)
				self.updatePlayPauseState()
			}
		} else {
			mpdBridge.getPathForAlbum(album) {
				var cop = CoverOperations(album: album, mpdBridge: self.mpdBridge)
				cop.processCallback = { (large, _, _) in
					DispatchQueue.main.async {
						self.imgCover = large
						UIView.transition(with: self.view, duration: 0.35, options: .transitionCrossDissolve, animations: {
							(self.view as? UIImageView)?.image = large
							self.sliderTrack.label.text = track.name
							self.sliderTrack.maximumValue = CGFloat(track.duration.value)
							self.lblArtist.text = track.artist
							self.lblAlbum.text = album.name
						}, completion: nil)
						self.updatePlayPauseState()
					}
				}
				cop.submit()
			}
		}

		// Up next
		updateUpNext(after: track.position)
	}

	@objc func playerStatusChangedNotification(_ aNotification: Notification?) {
		updatePlayPauseState()
		updateRandomAndRepeatState()
	}

	// MARK: - Private
	private func updatePlayPauseState() {
		let status = mpdBridge.getCurrentState().status
		if status == .paused || status == .stopped {
			btnPlay.setImage(UIImage(systemName: "play")!, tintColor: .secondaryLabel, selectedTintColor: .label)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")

			DispatchQueue.global(qos: .userInteractive).async {
				let grayscaled = self.imgCover?.grayscaled()
				DispatchQueue.main.async {
					UIView.transition(with: self.coverView, duration: 0.35, options: .transitionCrossDissolve, animations: { self.coverView.image = grayscaled
					}, completion: nil)
				}
			}
		} else {
			btnPlay.setImage(UIImage(systemName: "pause")!, tintColor: .secondaryLabel, selectedTintColor: .label)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")

			UIView.transition(with: coverView, duration: 0.35, options: .transitionCrossDissolve, animations: {
				self.coverView.image = self.imgCover
			}, completion: nil)
		}
		btnPlay.tag = status.rawValue
	}

	private func updateRandomAndRepeatState() {
		let state = mpdBridge.getCurrentState()

		UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
			if !self.btnRandom.isHighlighted {
				self.btnRandom.isSelected = state.isRandom
				self.btnRandom.accessibilityLabel = NYXLocalizedString(state.isRandom ? "lbl_random_disable" : "lbl_random_enable")
			}

			if !self.btnRepeat.isHighlighted {
				self.btnRepeat.isSelected = state.isRepeat
				self.btnRepeat.accessibilityLabel = NYXLocalizedString(state.isRepeat ? "lbl_repeat_disable" : "lbl_repeat_enable")
			}

			self.lblNextTrack.alpha = state.isRandom ? 0 : 1
			self.lblNextAlbumArtist.alpha = state.isRandom ? 0 : 1
			self.btnQueue.alpha = state.isRandom ? 0 : 1
			self.doubleTap.isEnabled = state.isRandom == false
		}, completion: nil)
	}

	private func updateUpNext(after: UInt32) {
		// Up next
		mpdBridge.getSongsOfCurrentQueue { [weak self] (tracks) in
			guard let strongSelf = self else { return }
			DispatchQueue.main.async {
				if tracks.count > 0 {
					let t = tracks.filter {$0.position > after}.sorted(by: { $0.position < $1.position })
					if t.count > 0 {
						strongSelf.lblNextTrack.text = t[0].name
						strongSelf.lblNextAlbumArtist.text = "\(t[0].artist) — \(t[0].albumName)"
						return
					}
				}
				strongSelf.lblNextTrack.text = ""
				strongSelf.lblNextAlbumArtist.text = ""
			}
		}
	}
}
