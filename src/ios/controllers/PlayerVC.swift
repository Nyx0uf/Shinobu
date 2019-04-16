import UIKit


fileprivate let miniBaseHeight = CGFloat(44)
fileprivate var miniHeight = miniBaseHeight
fileprivate let marginX = CGFloat(16)


final class PlayerVC : NYXViewController
{
	// MARK: - Public properties
	private(set) var isMinified = true

	// MARK: - Private properties
	// Blur view
	private var blurEffectView = UIVisualEffectView()
	// Cover
	private var coverView = UIImageView()
	// Track label
	private var lblTrack = AutoScrollLabel()
	private var sliderTrack = LabeledSlider()
	// Album & Artist labels
	private var lblAlbumArtist = AutoScrollLabel()
	private var lblArtist = ImagedLabel()
	private var lblAlbum = ImagedLabel()
	// Play / Pause button
	private var btnPlay = Button()
	// Next button
	private var btnNext = Button()
	// Previous button
	private var btnPrevious = Button()
	// Random button
	private var btnRandom = Button()
	// Repeat button
	private var btnRepeat = Button()
	// Dtop button
	private var btnStop = Button()
	// Elapsed time
	private var vev_elapsed = UIVisualEffectView()
	private var lblElapsedDuration = UILabel()
	// Remaining time
	private var vev_remaining = UIVisualEffectView()
	private var lblRemainingDuration = UILabel()
	// Progress bar for mini view
	private var progress = UIVisualEffectView()
	// Volume control
	private var sliderVolume = ImagedSlider(minImage: #imageLiteral(resourceName: "img-volume-mute"), midImage: #imageLiteral(resourceName: "img-volume-lo"), maxImage: #imageLiteral(resourceName: "img-volume-hi"))
	// Motion effects
	private var motionEffectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
	private var motionEffectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
	// MPD Data source
	private var mpdBridge: MPDBridge

	init(mpdBridge: MPDBridge)
	{
		self.mpdBridge = mpdBridge

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) { fatalError("no coder") }

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		let width = UIScreen.main.bounds.width
		if let bottom = (UIApplication.shared.delegate as! AppDelegate).window?.safeAreaInsets.bottom
		{
			miniHeight += bottom
		}

		// Blurred background
		view = UIImageView(image: nil)
		view.frame = CGRect(0, UIScreen.main.bounds.height - miniHeight, UIScreen.main.bounds.size)
		view.isUserInteractionEnabled = true

		blurEffectView.effect = UIBlurEffect(style: .dark)
		blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)

		// Top corners radius
		if UIDevice.current.isiPhoneX()
		{
			view.layer.cornerRadius = 10
			view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
			view.layer.masksToBounds = true
		}

		// Cover view
		coverView.frame = CGRect(.zero, miniHeight, miniHeight)
		coverView.isUserInteractionEnabled = true
		blurEffectView.contentView.addSubview(coverView)

		// Progress
		progress.frame = CGRect(coverView.maxX, 0, width - coverView.maxX, miniHeight)
			progress.effect = UIBlurEffect(style: .light)
		progress.alpha = 1
		progress.isUserInteractionEnabled = false
		blurEffectView.contentView.addSubview(progress)

		// Next button
		btnNext.frame = CGRect(view.frame.maxX - miniBaseHeight, (miniHeight - miniBaseHeight) / 2, miniBaseHeight, miniBaseHeight)
		btnNext.addTarget(mpdBridge, action: #selector(MPDBridge.requestNextTrack), for: .touchUpInside)
		btnNext.isAccessibilityElement = true
		btnNext.setImage(#imageLiteral(resourceName: "btn-next"))
		blurEffectView.contentView.addSubview(btnNext)

		// Previous button
		btnPrevious.frame = CGRect(view.frame.maxX - miniBaseHeight, (miniHeight - miniBaseHeight) / 2, miniBaseHeight, miniBaseHeight)
		btnPrevious.addTarget(mpdBridge, action: #selector(MPDBridge.requestPreviousTrack), for: .touchUpInside)
		btnPrevious.isAccessibilityElement = true
		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous"))
		btnPrevious.alpha = 0
		blurEffectView.contentView.addSubview(btnPrevious)

		// Play / Pause button
		btnPlay.frame = CGRect(btnNext.x - miniBaseHeight, btnNext.y, miniBaseHeight, miniBaseHeight)
		btnPlay.addTarget(self, action: #selector(changePlaybackAction(_:)), for: .touchUpInside)
		btnPlay.tag = PlayerStatus.stopped.rawValue
		btnPlay.isAccessibilityElement = true
		btnPlay.setImage(#imageLiteral(resourceName: "btn-play"))
		blurEffectView.contentView.addSubview(btnPlay)

		btnStop.frame = CGRect(width - marginX - miniBaseHeight, btnPlay.y, miniBaseHeight, miniBaseHeight)
		btnStop.addTarget(mpdBridge, action: #selector(MPDBridge.stop), for: .touchUpInside)
		btnStop.setImage(#imageLiteral(resourceName: "btn-stop"))
		btnStop.alpha = 0
		blurEffectView.contentView.addSubview(btnStop)

		// Track label
		let lblsHeightTotal = CGFloat(18 + 4 + 16)
		lblTrack.frame = CGRect(coverView.maxX + 8, (miniHeight - lblsHeightTotal) / 2, ((btnPlay.x + 8) - (coverView.maxX + 8)), 18)
		lblTrack.textAlignment = .left
		lblTrack.font = UIFont.systemFont(ofSize: 14, weight: .bold)
		lblTrack.textColor = UIColor(rgb: 0xFFFFFF)
		lblTrack.isAccessibilityElement = false
		lblTrack.scrollSpeed = 60
		blurEffectView.contentView.addSubview(lblTrack)

		// Track pos
		sliderTrack.frame = CGRect(coverView.maxX + 8, (miniHeight - lblsHeightTotal) / 2, ((btnPlay.x + 8) - (coverView.maxX + 8)), 32)
		sliderTrack.addTarget(self, action: #selector(changeTrackPositionAction(_:)), for: .touchUpInside)
		sliderTrack.alpha = 0
		sliderTrack.label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
		sliderTrack.label.textColor = UIColor(rgb: 0xFFFFFF)
		blurEffectView.contentView.addSubview(sliderTrack)

		// Album — Artist
		lblAlbumArtist.frame = CGRect(coverView.maxX + 8, lblTrack.maxY + 2, lblTrack.width, 16)
		lblAlbumArtist.textAlignment = .left
		lblAlbumArtist.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		lblAlbumArtist.textColor = UIColor(rgb: 0xFFFFFF)
		lblAlbumArtist.isAccessibilityElement = false
		blurEffectView.contentView.addSubview(lblAlbumArtist)

		lblArtist.frame = CGRect(marginX, lblTrack.maxY, (width - 3 * marginX) / 2, 20)
		lblArtist.imageView.image = #imageLiteral(resourceName: "img-mic").withRenderingMode(.alwaysTemplate).tinted(withColor: UIColor(rgb: 0xFFFFFF))
		lblArtist.label.textColor = UIColor(rgb: 0xFFFFFF)
		lblArtist.label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		lblArtist.alpha = 0
		blurEffectView.contentView.addSubview(lblArtist)

		lblAlbum.align = .right
		lblAlbum.frame = CGRect(lblArtist.maxX + marginX, lblTrack.maxY, (width - 3 * marginX) / 2, 20)
		lblAlbum.imageView.image = #imageLiteral(resourceName: "img-album").withRenderingMode(.alwaysTemplate).tinted(withColor: UIColor(rgb: 0xFFFFFF))
		lblAlbum.label.textColor = UIColor(rgb: 0xFFFFFF)
		lblAlbum.label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		lblAlbum.alpha = 0
		blurEffectView.contentView.addSubview(lblAlbum)

		// Elapsed label
		let sizeTimeLabels = CGSize(40, 16)
		vev_elapsed.frame = CGRect(marginX, 0, sizeTimeLabels)
		vev_elapsed.effect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark))
		lblElapsedDuration.frame = vev_elapsed.bounds
		lblElapsedDuration.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		lblElapsedDuration.textColor = UIColor(rgb: 0xFFFFFF)
		lblElapsedDuration.textAlignment = .left
		vev_elapsed.contentView.addSubview(lblElapsedDuration)
		blurEffectView.contentView.addSubview(vev_elapsed)
		vev_elapsed.alpha = 0

		// Remaining label
		vev_remaining.frame = CGRect(width - marginX - sizeTimeLabels.width, 0, sizeTimeLabels)
		vev_remaining.effect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark))
		lblRemainingDuration.frame = vev_remaining.bounds
		lblRemainingDuration.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		lblRemainingDuration.textColor = UIColor(rgb: 0xFFFFFF)
		lblRemainingDuration.textAlignment = .right
		vev_remaining.contentView.addSubview(lblRemainingDuration)
		blurEffectView.contentView.addSubview(vev_remaining)
		vev_remaining.alpha = 0

		// Repeat button
		let imageRepeat = #imageLiteral(resourceName: "btn-repeat")
		btnRepeat.frame = CGRect(width - marginX - miniHeight, btnPlay.maxY + 16, miniHeight, miniHeight)
		btnRepeat.setImage(imageRepeat)
		btnRepeat.addTarget(self, action: #selector(toggleRepeatAction(_:)), for: .touchUpInside)
		btnRepeat.alpha = 0
		self.blurEffectView.contentView.addSubview(btnRepeat)

		// Random button
		let imageRandom = #imageLiteral(resourceName: "btn-random")
		btnRandom.frame = CGRect(marginX, btnPlay.maxY + 16, miniHeight, miniHeight)
		btnRandom.setImage(imageRandom)
		btnRandom.addTarget(self, action: #selector(toggleRandomAction(_:)), for: .touchUpInside)
		btnRandom.alpha = 0
		blurEffectView.contentView.addSubview(btnRandom)

		// Slider volume
		sliderVolume.frame = CGRect(btnRandom.maxX + marginX, btnPlay.maxY + 16, btnRepeat.x - marginX - btnRandom.maxX - marginX, miniHeight)
		sliderVolume.addTarget(self, action: #selector(changeVolumeAction(_:)), for: .touchUpInside)
		sliderVolume.minimumValue = 0
		sliderVolume.maximumValue = 100
		blurEffectView.contentView.addSubview(sliderVolume)

		// Single tap to request full player view
		let singleTap = UITapGestureRecognizer()
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		singleTap.addTarget(self, action: #selector(singleTap(_:)))
		coverView.addGestureRecognizer(singleTap)

		// Useless motion effect
		motionEffectX.minimumRelativeValue = 20
		motionEffectX.maximumRelativeValue = -20
		motionEffectY.minimumRelativeValue = 20
		motionEffectY.maximumRelativeValue = -20

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackNotification(_:)), name: .currentPlayingTrack, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(playerStatusChangedNotification(_:)), name: .playerStatusChanged, object: nil)

		initializeTheming()
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
	}

	// MARK: - Buttons actions
	@objc func changePlaybackAction(_ sender: UIButton?)
	{
		if btnPlay.tag == PlayerStatus.stopped.rawValue
		{
			mpdBridge.play()
		}
		else
		{
			mpdBridge.togglePause()
		}
	}

	@objc func toggleRandomAction(_ sender: Any?)
	{
		mpdBridge.setRandom(!btnRandom.isSelected)
	}

	@objc func toggleRepeatAction(_ sender: Any?)
	{
		mpdBridge.setRepeat(!btnRepeat.isSelected)
	}

	@objc func changeTrackPositionAction(_ sender: UISlider?)
	{
		if let track = mpdBridge.getCurrentTrack()
		{
			mpdBridge.setTrackPosition(Int(sliderTrack.value), trackPosition: track.position)
		}
	}

	@objc func changeVolumeAction(_ sender: UISlider?)
	{
		setVolume(sliderVolume.value)
	}

	// MARK: - Gestures
	@objc func singleTap(_ gesture: UITapGestureRecognizer)
	{
		if gesture.state == .ended
		{
			let width = UIScreen.main.bounds.width
			if isMinified
			{
				mpdBridge.getVolume { (volume) in
					DispatchQueue.main.async {
						if volume == -1
						{
							self.sliderVolume.isHidden = true
							self.sliderVolume.value = 0
							self.sliderVolume.accessibilityLabel = NYXLocalizedString("lbl_volume_control_disabled")
						}
						else
						{
							self.sliderVolume.isHidden = false
							self.sliderVolume.value = CGFloat(volume)
							self.sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(volume)%"
						}
					}
				}

				let y = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
				UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
					self.view.frame = CGRect(.zero, self.view.size)
					self.vev_elapsed.frame = CGRect(marginX, y, self.vev_elapsed.size)
					self.vev_elapsed.alpha = 1
					self.vev_remaining.frame = CGRect(width - self.vev_remaining.width - marginX, y, self.vev_remaining.size)
					self.vev_remaining.alpha = 1
					self.lblTrack.frame = CGRect(marginX, self.vev_elapsed.maxY + 10, self.view.width - 2 * marginX, 32)
					self.lblTrack.alpha = 0
					self.sliderTrack.frame = CGRect(marginX, self.vev_elapsed.maxY + 10, self.view.width - 2 * marginX, 32)
					self.sliderTrack.alpha = 1
					self.lblAlbumArtist.frame = CGRect(marginX, self.lblTrack.maxY + 10, self.view.width - 2 * marginX, self.lblTrack.height)
					self.lblAlbumArtist.alpha = 0
					self.lblArtist.frame = CGRect(marginX, self.lblTrack.maxY + 10, self.lblArtist.size)
					self.lblArtist.alpha = 1
					self.lblAlbum.frame = CGRect(self.lblArtist.maxX + marginX, self.lblArtist.y, self.lblAlbum.size)
					self.lblAlbum.alpha = 1
					self.coverView.frame = CGRect(32, self.lblArtist.maxY + 16, self.view.size.width - 64, self.view.size.width - 64)
					self.btnPlay.frame = CGRect((width - self.btnPlay.width) / 2, self.coverView.maxY + 20, self.btnPlay.size)
					self.btnPrevious.frame = CGRect(self.btnPlay.x - self.btnPrevious.width - 8, self.coverView.maxY + 20, self.btnPrevious.size)
					self.btnPrevious.alpha = 1
					self.btnNext.frame = CGRect(self.btnPlay.maxX + 8, self.coverView.maxY + 20, self.btnNext.size)
					self.btnRandom.frame = CGRect(marginX, self.btnPlay.maxY + 16, self.btnRandom.size)
					self.btnRandom.alpha = 1
					self.btnRepeat.frame = CGRect(width - marginX - miniHeight, self.btnPlay.maxY + 16, self.btnRepeat.size)
					self.btnRepeat.alpha = 1
					self.btnStop.frame = CGRect(width - marginX - miniBaseHeight, self.btnPlay.y, miniBaseHeight, miniBaseHeight)
					self.btnStop.alpha = 1
					self.sliderVolume.frame = CGRect(self.btnRandom.maxX + marginX, self.btnPlay.maxY + 16, self.sliderVolume.size)
					self.sliderVolume.alpha = 1
					self.progress.alpha = 0
				}, completion: { (finished) in
					self.coverView.addMotionEffect(self.motionEffectX)
					self.coverView.addMotionEffect(self.motionEffectY)
				})
			}
			else
			{
				let lblsHeightTotal = CGFloat(18 + 4 + 16)
				UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
					self.view.frame = CGRect(0, UIScreen.main.bounds.height - miniHeight, self.view.size)
					self.coverView.frame = CGRect(.zero, miniHeight, miniHeight)
					self.vev_elapsed.alpha = 0
					self.vev_remaining.alpha = 0

					self.btnNext.frame = CGRect(self.view.frame.maxX - miniBaseHeight, (miniHeight - miniBaseHeight) / 2, miniBaseHeight, miniBaseHeight)
					self.btnPlay.frame = CGRect(self.btnNext.x - miniBaseHeight, self.btnNext.y, miniBaseHeight, miniBaseHeight)
					self.btnPrevious.alpha = 0
					self.btnRandom.alpha = 0
					self.btnRepeat.alpha = 0
					self.btnStop.alpha = 0

					self.lblTrack.frame = CGRect(self.coverView.maxX + 8, (miniHeight - lblsHeightTotal) / 2, ((self.btnPlay.x + 8) - (self.coverView.maxX + 8)), 18)
					self.lblTrack.alpha = 1
					self.sliderTrack.frame = CGRect(self.coverView.maxX + 8, (miniHeight - lblsHeightTotal) / 2, ((self.btnPlay.x + 8) - (self.coverView.maxX + 8)), 18)
					self.sliderTrack.alpha = 0
					self.lblAlbumArtist.frame = CGRect(self.coverView.maxX + 8, self.lblTrack.maxY + 2, self.lblTrack.width, 16)
					self.lblAlbumArtist.alpha = 1
					self.lblArtist.alpha = 0
					self.lblAlbum.alpha = 0
					self.progress.alpha = 1
				}, completion: { (finished) in
					self.coverView.removeMotionEffect(self.motionEffectX)
					self.coverView.removeMotionEffect(self.motionEffectY)
				})
			}
			isMinified.toggle()
		}
	}

	// MARK: - Notifications
	@objc func playingTrackNotification(_ aNotification: Notification?)
	{
		guard let track = aNotification?.userInfo![PLAYER_TRACK_KEY] as? Track, let elapsed = aNotification?.userInfo![PLAYER_ELAPSED_KEY] as? Int else
		{
			return
		}

		if !sliderTrack.isSelected && !sliderTrack.isHighlighted
		{
			sliderTrack.value = CGFloat(elapsed)
			sliderTrack.accessibilityLabel = "\(NYXLocalizedString("lbl_track_position")) : \(Int((sliderTrack.value * 100) / sliderTrack.maximumValue))%"
		}

		let elapsedDuration = Duration(seconds: elapsed)
		let remainingDuration = track.duration - elapsedDuration
		lblElapsedDuration.text = elapsedDuration.minutesRepresentationAsString()
		lblRemainingDuration.text = "-\(remainingDuration.minutesRepresentationAsString())"
		progress.width = (CGFloat(elapsed) * (view.width - coverView.width)) / CGFloat(track.duration.seconds)

		updateRandomAndRepeatButtons(random: aNotification?.userInfo?[PLAYER_RANDOM_KEY] as! Bool, loop: aNotification?.userInfo?[PLAYER_REPEAT_KEY] as! Bool)
	}

	@objc func playingTrackChangedNotification(_ aNotification: Notification?)
	{
		guard let track = aNotification?.userInfo![PLAYER_TRACK_KEY] as? Track, let album = aNotification?.userInfo![PLAYER_ALBUM_KEY] as? Album else
		{
			return
		}
		lblTrack.text = track.name
		sliderTrack.label.text = track.name
		sliderTrack.maximumValue = CGFloat(track.duration.seconds)
		lblAlbumArtist.text = "\(track.artist) — \(album.name)"
		lblArtist.label.text = track.artist
		lblAlbum.label.text = album.name

		// Update cover if from another album (playlist case)
		let iv = view as? UIImageView
		if album.path != nil
		{
			let op = CoverOperation(album: album, cropSize: coverView.size)
			op.callback = { (cover, thumbnail) in
				DispatchQueue.main.async {
					self.coverView.image = cover
					iv?.image = cover
				}
			}
			OperationManager.shared.addOperation(op)
		}
		else
		{
			let size = coverView.size
			mpdBridge.getPathForAlbum(album) {
				let op = CoverOperation(album: album, cropSize: size)
				op.callback = { (cover, thumbnail) in
					DispatchQueue.main.async {
						self.coverView.image = cover
						iv?.image = cover
					}
				}
				OperationManager.shared.addOperation(op)
			}
		}
	}

	@objc func playerStatusChangedNotification(_ aNotification: Notification?)
	{
		updatePlayPauseButton()
		updateRandomAndRepeatButtons(random: aNotification?.userInfo?[PLAYER_RANDOM_KEY] as! Bool, loop: aNotification?.userInfo?[PLAYER_REPEAT_KEY] as! Bool)
	}

	// MARK: - Private
	private func updatePlayPauseButton()
	{
		let status = mpdBridge.getCurrentStatus()
		if status == .paused || status == .stopped
		{
			let imgPlay = #imageLiteral(resourceName: "btn-play")
			btnPlay.setImage(imgPlay)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			let imgPause = #imageLiteral(resourceName: "btn-pause")
			btnPlay.setImage(imgPause)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}
		btnPlay.tag = status.rawValue
	}

	private func updateRandomAndRepeatButtons(random: Bool, loop: Bool)
	{
		btnRandom.isSelected = random
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		btnRepeat.isSelected = loop
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")
	}

	func setVolume(_ valueToSet: CGFloat)
	{
		let tmp = clamp(ceil(valueToSet), lower: 0, upper: 100)
		let volume = Int(tmp)

		mpdBridge.setVolume(volume) { (success) in
			if success
			{
				DispatchQueue.main.async {
					self.sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(volume)%"
				}
			}
		}
	}
}

extension PlayerVC: Themed
{
	func applyTheme(_ theme: Theme)
	{

	}
}
