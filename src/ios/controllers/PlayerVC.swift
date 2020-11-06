import UIKit

private let miniBaseHeight = CGFloat(64)
private var miniHeight = miniBaseHeight
private let miniCoverMargin = CGFloat(8)
private let miniCoverSize = miniBaseHeight - 2 * miniCoverMargin
private let marginX = CGFloat(16)
private let btnSize = CGFloat(44)

final class PlayerVC: NYXViewController {
	// MARK: - Public properties
	private(set) var isMinified = true

	// MARK: - Private properties
	// MPD Data source
	private let mpdBridge: MPDBridge
	// Blurred view
	private let blurEffectView = UIVisualEffectView()
	// Cover
	private let coverView = UIImageView()
	// Tappable view
	private let tapableView = UIView()
	// Track label
	private let lblTrack = AutoScrollLabel()
	private let sliderTrack = LabeledSlider()
	// Album & Artist labels
	private let lblAlbumArtist = AutoScrollLabel()
	private let lblArtist = ImagedLabel()
	private let lblAlbum = ImagedLabel()
	// Play / Pause button
	private let btnPlay = Button()
	// Next button
	private let btnNext = Button()
	// Previous button
	private let btnPrevious = Button()
	// Random button
	private let btnRandom = Button()
	// Repeat button
	private let btnRepeat = Button()
	// Stop button
	private let btnStop = Button()
	// Show queue button
	private let btnQueue = Button()
	// Elapsed time
	private let vev_elapsed = UIVisualEffectView()
	private let lblElapsedDuration = UILabel()
	// Remaining time
	private let vev_remaining = UIVisualEffectView()
	private let lblRemainingDuration = UILabel()
	// Progress bar for mini view
	private let progress = UIVisualEffectView()
	// Volume control
	private let sliderVolume = ImagedSlider(minImage: #imageLiteral(resourceName: "img-volume-mute"), midImage: #imageLiteral(resourceName: "img-volume-lo"), maxImage: #imageLiteral(resourceName: "img-volume-hi"))
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

	init(mpdBridge: MPDBridge) {
		self.mpdBridge = mpdBridge

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()

		self.overrideUserInterfaceStyle = .dark

		let width = UIScreen.main.bounds.width
		if let bottom = (UIApplication.shared.delegate as! AppDelegate).window?.safeAreaInsets.bottom {
			miniHeight = miniBaseHeight + bottom
		}

		// Blurred background
		view = UIImageView(image: nil)
		view.frame = CGRect(0, UIScreen.main.bounds.height - miniHeight, UIScreen.main.bounds.size)
		view.isUserInteractionEnabled = true

		blurEffectView.effect = UIBlurEffect(style: .dark)
		blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)

		// Top corners radius
		view.layer.cornerRadius = 10
		view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
		view.layer.masksToBounds = true

		// Progress
		progress.frame = CGRect(0, 0, width, miniHeight)
		progress.effect = UIBlurEffect(style: .light)
		progress.alpha = 1
		progress.isUserInteractionEnabled = false
		blurEffectView.contentView.addSubview(progress)

		// Cover view
		coverView.frame = CGRect(miniCoverMargin, (miniHeight - miniCoverSize) / 2, miniCoverSize, miniCoverSize)
		coverView.isUserInteractionEnabled = true
		coverView.layer.shadowColor = UIColor(rgb: 0x222222).cgColor
		coverView.layer.shadowRadius = 1
		coverView.layer.shadowOffset = CGSize(0, 1)
		coverView.layer.cornerRadius = 5
		coverView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
		coverView.layer.masksToBounds = true
		blurEffectView.contentView.addSubview(coverView)

		// Next button
		btnNext.frame = CGRect(view.frame.maxX - btnSize, (miniHeight - btnSize) / 2, btnSize, btnSize)
		btnNext.addTarget(mpdBridge, action: #selector(MPDBridge.requestNextTrack), for: .touchUpInside)
		btnNext.isAccessibilityElement = true
		btnNext.setImage(#imageLiteral(resourceName: "btn-next"), tintColor: .secondaryLabel, selectedTintColor: .label)
		blurEffectView.contentView.addSubview(btnNext)

		// Previous button
		btnPrevious.frame = CGRect(view.frame.maxX - btnSize, (miniHeight - btnSize) / 2, btnSize, btnSize)
		btnPrevious.addTarget(mpdBridge, action: #selector(MPDBridge.requestPreviousTrack), for: .touchUpInside)
		btnPrevious.isAccessibilityElement = true
		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous"), tintColor: .secondaryLabel, selectedTintColor: .label)
		btnPrevious.alpha = 0
		blurEffectView.contentView.addSubview(btnPrevious)

		// Play / Pause button
		btnPlay.frame = CGRect(btnNext.x - btnSize, btnNext.y, btnSize, btnSize)
		btnPlay.addTarget(self, action: #selector(changePlaybackAction(_:)), for: .touchUpInside)
		btnPlay.tag = PlayerStatus.stopped.rawValue
		btnPlay.isAccessibilityElement = true
		btnPlay.setImage(#imageLiteral(resourceName: "btn-play"), tintColor: .secondaryLabel, selectedTintColor: .label)
		blurEffectView.contentView.addSubview(btnPlay)

		// Stop button
		btnStop.frame = CGRect(width - marginX - btnSize, btnPlay.y, btnSize, btnSize)
		btnStop.addTarget(mpdBridge, action: #selector(MPDBridge.stop), for: .touchUpInside)
		btnStop.setImage(#imageLiteral(resourceName: "btn-stop"), tintColor: .secondaryLabel, selectedTintColor: .label)
		btnStop.alpha = 0
		blurEffectView.contentView.addSubview(btnStop)

		// Queue button
		btnQueue.frame = CGRect(marginX, view.height - miniHeight, btnSize, btnSize)
		btnQueue.addTarget(self, action: #selector(showUpNextAction(_:)), for: .touchUpInside)
		btnQueue.setImage(#imageLiteral(resourceName: "img-queue"), tintColor: .secondaryLabel, selectedTintColor: .label)
		blurEffectView.contentView.addSubview(btnQueue)

		// Track label (minified)
		let lblsHeightTotal = CGFloat(18 + 4 + 16)
		lblTrack.frame = CGRect(coverView.maxX + 8, (miniHeight - lblsHeightTotal) / 2, ((btnPlay.x + 8) - (coverView.maxX + 8)), 18)
		lblTrack.textAlignment = .left
		lblTrack.font = UIFont.systemFont(ofSize: 14, weight: .bold)
		lblTrack.textColor = UIColor(rgb: 0xFFFFFF)
		lblTrack.isAccessibilityElement = false
		lblTrack.scrollSpeed = 60
		blurEffectView.contentView.addSubview(lblTrack)

		// Track pos & title (full)
		sliderTrack.frame = CGRect(coverView.maxX + 8, (miniHeight - lblsHeightTotal) / 2, ((btnPlay.x + 8) - (coverView.maxX + 8)), 32)
		sliderTrack.addTarget(self, action: #selector(changeTrackPositionAction(_:)), for: .touchUpInside)
		sliderTrack.alpha = 0
		sliderTrack.label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
		sliderTrack.label.textColor = UIColor(rgb: 0xFFFFFF)
		sliderTrack.label.textAlignment = .center
		blurEffectView.contentView.addSubview(sliderTrack)

		// Album — Artist (minified)
		lblAlbumArtist.frame = CGRect(coverView.maxX + 8, lblTrack.maxY + 2, lblTrack.width, 16)
		lblAlbumArtist.textAlignment = .left
		lblAlbumArtist.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		lblAlbumArtist.textColor = UIColor(rgb: 0xFFFFFF)
		lblAlbumArtist.isAccessibilityElement = false
		blurEffectView.contentView.addSubview(lblAlbumArtist)

		// Artist (full)
		lblArtist.frame = CGRect(marginX, lblTrack.maxY, (width - 3 * marginX) / 2, 20)
		lblArtist.image = #imageLiteral(resourceName: "img-mic").withTintColor(.white)
		lblArtist.highlightedImage = #imageLiteral(resourceName: "img-mic").withTintColor(.label)
		lblArtist.textColor = .secondaryLabel
		lblArtist.highlightedTextColor = .label
		lblArtist.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
		lblArtist.underlined = true
		lblArtist.alpha = 0
		lblArtist.addTarget(self, action: #selector(showArtistAction(_:)), for: .touchUpInside)
		blurEffectView.contentView.addSubview(lblArtist)

		// Album (full)
		lblAlbum.align = .right
		lblAlbum.frame = CGRect(lblArtist.maxX + marginX, lblTrack.maxY, (width - 3 * marginX) / 2, 20)
		lblAlbum.image = #imageLiteral(resourceName: "img-album").withTintColor(.white)
		lblAlbum.highlightedImage = #imageLiteral(resourceName: "img-album").withTintColor(.label)
		lblAlbum.textColor = .secondaryLabel
		lblAlbum.highlightedTextColor = .label
		lblAlbum.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
		lblAlbum.underlined = true
		lblAlbum.alpha = 0
		lblAlbum.addTarget(self, action: #selector(showAlbumAction(_:)), for: .touchUpInside)
		blurEffectView.contentView.addSubview(lblAlbum)

		// Elapsed label
		let sizeTimeLabels = CGSize(40, 16)
		vev_elapsed.frame = CGRect(marginX, 0, sizeTimeLabels)
		vev_elapsed.effect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark))
		lblElapsedDuration.frame = vev_elapsed.bounds
		lblElapsedDuration.font = UIFont.systemFont(ofSize: 12, weight: .bold)
		lblElapsedDuration.textColor = UIColor(rgb: 0xFFFFFF)
		lblElapsedDuration.textAlignment = .left
		vev_elapsed.contentView.addSubview(lblElapsedDuration)
		blurEffectView.contentView.addSubview(vev_elapsed)
		vev_elapsed.alpha = 0

		// Remaining label
		vev_remaining.frame = CGRect(width - marginX - sizeTimeLabels.width, 0, sizeTimeLabels)
		vev_remaining.effect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark))
		lblRemainingDuration.frame = vev_remaining.bounds
		lblRemainingDuration.font = UIFont.systemFont(ofSize: 12, weight: .bold)
		lblRemainingDuration.textColor = UIColor(rgb: 0xFFFFFF)
		lblRemainingDuration.textAlignment = .right
		vev_remaining.contentView.addSubview(lblRemainingDuration)
		blurEffectView.contentView.addSubview(vev_remaining)
		vev_remaining.alpha = 0

		// Repeat button
		btnRepeat.frame = CGRect(width - marginX - btnSize, btnPlay.maxY + 16, btnSize, btnSize)
		btnRepeat.setImage(#imageLiteral(resourceName: "btn-repeat"), tintColor: .secondaryLabel, selectedTintColor: .label)
		btnRepeat.addTarget(self, action: #selector(toggleRepeatAction(_:)), for: .touchUpInside)
		btnRepeat.alpha = 0
		self.blurEffectView.contentView.addSubview(btnRepeat)

		// Random button
		btnRandom.frame = CGRect(marginX, btnPlay.maxY + 16, btnSize, btnSize)
		btnRandom.setImage(#imageLiteral(resourceName: "btn-random"), tintColor: .secondaryLabel, selectedTintColor: .label)
		btnRandom.addTarget(self, action: #selector(toggleRandomAction(_:)), for: .touchUpInside)
		btnRandom.alpha = 0
		blurEffectView.contentView.addSubview(btnRandom)

		// Slider volume
		sliderVolume.frame = CGRect(btnRandom.maxX + marginX, btnPlay.maxY + 16, btnRepeat.x - marginX - btnRandom.maxX - marginX, btnSize)
		sliderVolume.addTarget(self, action: #selector(changeVolumeAction(_:)), for: .touchUpInside)
		sliderVolume.minimumValue = 0
		sliderVolume.maximumValue = 100
		blurEffectView.contentView.addSubview(sliderVolume)

		// Next track
		lblNextTrack.frame = CGRect(btnQueue.maxX + marginX, btnQueue.y, width - btnQueue.maxX - marginX - marginX - marginX - btnSize, 20)
		lblNextTrack.textAlignment = .center
		lblNextTrack.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
		lblNextTrack.textColor = .secondaryLabel
		lblNextTrack.isAccessibilityElement = false
		lblNextTrack.scrollSpeed = 60
		blurEffectView.contentView.addSubview(lblNextTrack)

		// Next artist + album
		lblNextAlbumArtist.frame = CGRect(btnQueue.maxX + marginX, lblNextTrack.maxY, width - btnQueue.maxX - marginX - marginX - marginX - btnSize, 20)
		lblNextAlbumArtist.textAlignment = .center
		lblNextAlbumArtist.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
		lblNextAlbumArtist.textColor = .secondaryLabel
		lblNextAlbumArtist.isAccessibilityElement = false
		blurEffectView.contentView.addSubview(lblNextAlbumArtist)

		// tapableView
		tapableView.isUserInteractionEnabled = true
		tapableView.frame = CGRect(.zero, btnPlay.x, miniBaseHeight)
		view.addSubview(tapableView)

		// Single tap to request full player view
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		singleTap.addTarget(self, action: #selector(singleTap(_:)))
		tapableView.addGestureRecognizer(singleTap)

		// Double tap in minified view to directly show up next
		doubleTap.numberOfTapsRequired = 2
		doubleTap.numberOfTouchesRequired = 1
		doubleTap.addTarget(self, action: #selector(doubleTap(_:)))
		tapableView.addGestureRecognizer(doubleTap)
		singleTap.require(toFail: doubleTap)

		// Useless motion effect
		motionEffectX.minimumRelativeValue = 20
		motionEffectX.maximumRelativeValue = -20
		motionEffectY.minimumRelativeValue = 20
		motionEffectY.maximumRelativeValue = -20

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackNotification(_:)), name: .currentPlayingTrack, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(playerStatusChangedNotification(_:)), name: .playerStatusChanged, object: nil)
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
		let uvc = UpNextVC(mpdBridge: mpdBridge)
		let nvc = NYXNavigationController(rootViewController: uvc)
		present(nvc, animated: true, completion: nil)
	}

	@objc func showArtistAction(_ sender: Any?) {
		toggleMinified()

		NotificationCenter.default.postOnMainThreadAsync(name: .showArtistNotification, object: lblArtist.text)
	}

	@objc func showAlbumAction(_ sender: Any?) {
		toggleMinified()

		if let album = mpdBridge.getCurrentAlbum() {
			NotificationCenter.default.postOnMainThreadAsync(name: .showAlbumNotification, object: album)
		}
	}

	// MARK: - Gestures
	@objc func singleTap(_ gesture: UITapGestureRecognizer) {
		if gesture.state == .ended {
			toggleMinified()
		}
	}

	@objc func doubleTap(_ gesture: UITapGestureRecognizer) {
		if gesture.state == .ended {
			showUpNextAction(nil)
		}
	}

	// MARK: - Notifications
	@objc func playingTrackNotification(_ aNotification: Notification?) {
		guard let notif = aNotification, let userInfos = notif.userInfo else { return }

		guard let track = userInfos[PLAYER_TRACK_KEY] as? Track, let elapsed = userInfos[PLAYER_ELAPSED_KEY] as? Int else { return }

		if isMinified { // Components to update when minified
			progress.width = (CGFloat(elapsed) * (view.width - coverView.width)) / CGFloat(track.duration.seconds)
			guard let isRandom = userInfos[PLAYER_RANDOM_KEY] as? Bool else { return }
			doubleTap.isEnabled = isRandom == false
		} else { // Components to update when full screen
			// Update track position slider if not panning the slider
			if !sliderTrack.isHighlighted && !sliderTrack.isSelected {
				sliderTrack.value = CGFloat(elapsed)
				sliderTrack.accessibilityLabel = "\(NYXLocalizedString("lbl_track_position")) : \(Int((sliderTrack.value * 100) / sliderTrack.maximumValue))%"
			}

			let elapsedDuration = Duration(seconds: elapsed)
			let remainingDuration = track.duration - elapsedDuration
			lblElapsedDuration.text = elapsedDuration.minutesRepresentationAsString()
			lblRemainingDuration.text = "-\(remainingDuration.minutesRepresentationAsString())"

			updateRandomAndRepeatState()
		}
	}

	@objc func playingTrackChangedNotification(_ aNotification: Notification?) {
		guard let notif = aNotification, let userInfos = notif.userInfo else { return }

		guard let track = userInfos[PLAYER_TRACK_KEY] as? Track, let album = userInfos[PLAYER_ALBUM_KEY] as? Album else { return }

		// Update cover if from another album (playlist case)
		if let cover = album.asset(ofSize: .large) {
			DispatchQueue.main.async {
				self.imgCover = cover
				UIView.transition(with: self.view, duration: 0.35, options: .transitionCrossDissolve, animations: {
					(self.view as? UIImageView)?.image = cover
					self.lblTrack.text = track.name
					self.sliderTrack.label.text = track.name
					self.sliderTrack.maximumValue = CGFloat(track.duration.seconds)
					self.lblAlbumArtist.text = "\(track.artist) — \(album.name)"
					self.lblArtist.text = track.artist
					self.lblAlbum.text = album.name
				}, completion: nil)
				self.updatePlayPauseState()
			}
		} else {
			mpdBridge.getPathForAlbum(album) {
				var cop = CoverOperations(album: album)
				cop.processCallback = { (large, medium, small) in
					DispatchQueue.main.async {
						self.imgCover = large
						UIView.transition(with: self.view, duration: 0.35, options: .transitionCrossDissolve, animations: {
							(self.view as? UIImageView)?.image = large
							self.lblTrack.text = track.name
							self.sliderTrack.label.text = track.name
							self.sliderTrack.maximumValue = CGFloat(track.duration.seconds)
							self.lblAlbumArtist.text = "\(track.artist) — \(album.name)"
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
			btnPlay.setImage(#imageLiteral(resourceName: "btn-play"), tintColor: .secondaryLabel, selectedTintColor: .label)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")

			DispatchQueue.global(qos: .userInteractive).async {
				let grayscaled = self.imgCover?.grayscaled()
				DispatchQueue.main.async {
					UIView.transition(with: self.coverView, duration: 0.35, options: .transitionCrossDissolve, animations: { self.coverView.image = grayscaled
					}, completion: nil)
				}
			}
		} else {
			btnPlay.setImage(#imageLiteral(resourceName: "btn-pause"), tintColor: .secondaryLabel, selectedTintColor: .label)
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

	private func toggleMinified() {
		let width = UIScreen.main.bounds.width
		if isMinified {
			mpdBridge.getVolume { (volume) in
				DispatchQueue.main.async {
					if volume == -1 {
						self.sliderVolume.isEnabled = false
						self.sliderVolume.value = 0
						self.sliderVolume.accessibilityLabel = NYXLocalizedString("lbl_volume_control_disabled")
					} else {
						self.sliderVolume.isEnabled = true
						self.sliderVolume.value = CGFloat(volume)
						self.sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(volume)%"
					}
				}
			}

			updateUpNext(after: mpdBridge.getCurrentTrack()?.position ?? 0)

			let y = UIApplication.shared.mainWindow?.safeAreaInsets.top ?? 0
			UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
				self.view.y = 0

				self.vev_elapsed.origin = CGPoint(marginX, y)
				self.vev_elapsed.alpha = 1
				self.vev_remaining.origin = CGPoint(width - self.vev_remaining.width - marginX, self.vev_elapsed.y)
				self.vev_remaining.alpha = 1

				self.lblTrack.frame = CGRect(marginX, self.vev_elapsed.maxY + 10, width - 2 * marginX, 32)
				self.lblTrack.alpha = 0
				self.sliderTrack.frame = CGRect(marginX, self.vev_elapsed.maxY + 10, width - 2 * marginX, 32)
				self.sliderTrack.alpha = 1

				self.lblAlbumArtist.frame = CGRect(marginX, self.lblTrack.maxY + 10, width - 2 * marginX, self.lblTrack.height)
				self.lblAlbumArtist.alpha = 0
				self.lblArtist.origin = CGPoint(marginX, self.lblTrack.maxY + 10)
				self.lblArtist.alpha = 1
				self.lblAlbum.origin = CGPoint(self.lblArtist.maxX + marginX, self.lblArtist.y)
				self.lblAlbum.alpha = 1

				self.coverView.frame = CGRect(32, self.lblArtist.maxY + 16, width - 64, width - 64)
				self.coverView.layer.shadowOpacity = 1
				self.coverView.layer.masksToBounds = false

				self.btnPlay.origin = CGPoint((width - self.btnPlay.width) / 2, self.coverView.maxY + 20)
				self.btnPrevious.origin = CGPoint(self.btnPlay.x - self.btnPrevious.width - 8, self.btnPlay.y)
				self.btnPrevious.alpha = 1
				self.btnNext.origin = CGPoint(self.btnPlay.maxX + 8, self.btnPlay.y)
				self.btnStop.origin = CGPoint(width - marginX - btnSize, self.btnPlay.y)
				self.btnStop.alpha = 1

				self.btnRandom.origin = CGPoint(marginX, self.btnPlay.maxY + 16)
				self.btnRandom.alpha = 1
				self.btnRepeat.origin = CGPoint(width - marginX - btnSize, self.btnRandom.y)
				self.btnRepeat.alpha = 1
				self.sliderVolume.origin = CGPoint(self.btnRandom.maxX + marginX, self.btnRandom.y)
				self.sliderVolume.alpha = 1

				self.tapableView.frame = self.coverView.frame

				self.progress.alpha = 0
			}, completion: { (_) in
				self.coverView.addMotionEffect(self.motionEffectX)
				self.coverView.addMotionEffect(self.motionEffectY)
				self.setNeedsStatusBarAppearanceUpdate()
			})
			self.doubleTap.isEnabled = false
		} else {
			let lblsHeightTotal = CGFloat(18 + 4 + 16)
			UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
				self.view.y = UIScreen.main.bounds.height - miniHeight

				self.coverView.frame = CGRect(miniCoverMargin, (miniHeight - miniCoverSize) / 2, miniCoverSize, miniCoverSize)
				self.coverView.layer.shadowOpacity = 0
				self.coverView.layer.masksToBounds = true

				self.btnNext.origin = CGPoint(self.view.maxX - btnSize, (miniHeight - btnSize) / 2)
				self.btnPlay.origin = CGPoint(self.btnNext.x - btnSize, self.btnNext.y)

				self.lblTrack.frame = CGRect(self.coverView.maxX + 8, (miniHeight - lblsHeightTotal) / 2, ((self.btnPlay.x + 8) - (self.coverView.maxX + 8)), 18)
				self.sliderTrack.frame = CGRect(self.coverView.maxX + 8, (miniHeight - lblsHeightTotal) / 2, ((self.btnPlay.x + 8) - (self.coverView.maxX + 8)), 18)
				self.lblAlbumArtist.frame = CGRect(self.coverView.maxX + 8, self.lblTrack.maxY + 2, self.lblTrack.width, 16)

				self.tapableView.frame = CGRect(.zero, self.btnPlay.x, miniBaseHeight)

				self.lblAlbumArtist.alpha = 1
				self.lblTrack.alpha = 1
				self.progress.alpha = 1
				self.sliderTrack.alpha = 0
				self.lblArtist.alpha = 0
				self.lblAlbum.alpha = 0
				self.btnPrevious.alpha = 0
				self.btnRandom.alpha = 0
				self.btnRepeat.alpha = 0
				self.btnStop.alpha = 0
				self.vev_elapsed.alpha = 0
				self.vev_remaining.alpha = 0
			}, completion: { (_) in
				self.coverView.removeMotionEffect(self.motionEffectX)
				self.coverView.removeMotionEffect(self.motionEffectY)
				self.setNeedsStatusBarAppearanceUpdate()
			})
			self.doubleTap.isEnabled = true
		}
		isMinified.toggle()
	}
}
