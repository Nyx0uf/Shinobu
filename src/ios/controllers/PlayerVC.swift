import UIKit


final class PlayerVC: NYXViewController, InteractableImageViewDelegate
{
	// MARK: - Private properties
	// Blur view
	private var blurEffectView: UIVisualEffectView! = nil
	// Cover view
	fileprivate var coverView: InteractableImageView! = nil
	// Track title
	private var lblTrackTitle: AutoScrollLabel! = nil
	// Track artist name
	private var lblTrackArtist: UILabel! = nil
	// Album name
	private var lblAlbumName: UILabel! = nil
	// Play/Pause button
	private var btnPlay: UIButton! = nil
	// Next button
	private var btnNext: UIButton! = nil
	// Previous button
	private var btnPrevious: UIButton! = nil
	// Random button
	private var btnRandom: UIButton! = nil
	// Repeat button
	private var btnRepeat: UIButton! = nil
	// Progress bar
	private var sliderPosition: UISlider! = nil
	// Track title
	private var lblElapsedDuration: UILabel! = nil
	// Track artist name
	private var lblRemainingDuration: UILabel! = nil
	// Bit depth & samplerate
	private var lblTrackInformation: UILabel! = nil
	// Volume control
	private var sliderVolume: UISlider! = nil
	// Album tracks view
	private var trackListView: TracksListTableView! = nil
	// MPD Data source
	private(set) var mpdBridge: MPDBridge

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

		// Blurred background
		view = UIImageView(frame: view.bounds)
		view.isUserInteractionEnabled = true
		blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
		blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)

		let statusHeight: CGFloat
		if let top = UIApplication.shared.keyWindow?.safeAreaInsets.top
		{
			statusHeight = top < 20 ? 20 : top
		}
		else
		{
			statusHeight = 20
		}

		let width = UIScreen.main.bounds.width
		let margin = CGFloat(32)
		let heightTopLabels = CGFloat(20)

		// Track title
		let vev_title = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_title.frame = CGRect(0, statusHeight, width, heightTopLabels)
		lblTrackTitle = AutoScrollLabel(frame: vev_title.bounds)
		lblTrackTitle.font = UIFont.systemFont(ofSize: 15, weight: .bold)
		lblTrackTitle.textColor = .white
		lblTrackTitle.textAlignment = .center
		vev_title.contentView.addSubview(lblTrackTitle)
		blurEffectView.contentView.addSubview(vev_title)

		// Track artist
		let vev_artist = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_artist.frame = CGRect(0, vev_title.maxY, width, heightTopLabels)
		lblTrackArtist = UILabel(frame: vev_artist.bounds)
		lblTrackArtist.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		lblTrackArtist.textColor = .white
		lblTrackArtist.textAlignment = .center
		vev_artist.contentView.addSubview(lblTrackArtist)
		blurEffectView.contentView.addSubview(vev_artist)

		// Album
		let vev_album = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_album.frame = CGRect(0, vev_artist.maxY, width, heightTopLabels)
		lblAlbumName = UILabel(frame: vev_album.bounds)
		lblAlbumName.font = UIFont.systemFont(ofSize: 13, weight: .light)
		lblAlbumName.textColor = .white
		lblAlbumName.textAlignment = .center
		vev_album.contentView.addSubview(lblAlbumName)
		blurEffectView.contentView.addSubview(vev_album)

		// Track list view
		let theight = width - (2 * margin)
		let tframe = CGRect(margin, vev_album.maxY + 20, theight, theight)
		trackListView = TracksListTableView(frame: tframe, style: .plain)
		trackListView.delegate = self
		trackListView.myDelegate = self
		blurEffectView.contentView.addSubview(trackListView)

		// Cover
		coverView = InteractableImageView(frame: tframe)
		coverView.delegate = self
		blurEffectView.contentView.addSubview(coverView)

		// Elapsed label
		let sizeTimeLabels = CGSize(40, 16)
		let vev_elapsed = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_elapsed.frame = CGRect(coverView.x, coverView.maxY + 4, sizeTimeLabels)
		lblElapsedDuration = UILabel(frame: vev_elapsed.bounds)
		lblElapsedDuration.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		lblElapsedDuration.textColor = .white
		lblElapsedDuration.textAlignment = .left
		vev_elapsed.contentView.addSubview(lblElapsedDuration)
		blurEffectView.contentView.addSubview(vev_elapsed)

		// Remaining label
		let vev_remaining = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_remaining.frame = CGRect(width - margin - sizeTimeLabels.width, coverView.maxY + 4, sizeTimeLabels)
		lblRemainingDuration = UILabel(frame: vev_remaining.bounds)
		lblRemainingDuration.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		lblRemainingDuration.textColor = .white
		lblRemainingDuration.textAlignment = .right
		vev_remaining.contentView.addSubview(lblRemainingDuration)
		blurEffectView.contentView.addSubview(vev_remaining)

		// Slider track position
		sliderPosition = UISlider(frame: CGRect(margin, vev_remaining.maxY, tframe.width, 31))
		sliderPosition.addTarget(self, action: #selector(changeTrackPositionAction(_:)), for: .touchUpInside)
		blurEffectView.contentView.addSubview(sliderPosition)

		// Previous button
		let sizeButtonsTracks = CGSize(48, 48)
		let yButtonsTracks = sliderPosition.maxY + 16
		btnPrevious = UIButton(frame: CGRect(margin, yButtonsTracks, sizeButtonsTracks))
		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous").tinted(withColor: .white), for: .normal)
		btnPrevious.addTarget(mpdBridge, action: #selector(MPDBridge.requestPreviousTrack), for: .touchUpInside)
		blurEffectView.contentView.addSubview(btnPrevious)

		// Play/Pause button
		btnPlay = UIButton(frame: CGRect((width - sizeButtonsTracks.width) / 2, yButtonsTracks, sizeButtonsTracks))
		btnPlay.addTarget(mpdBridge, action: #selector(MPDBridge.togglePause), for: .touchUpInside)
		blurEffectView.contentView.addSubview(btnPlay)

		// Next button
		btnNext = UIButton(frame: CGRect(width - sizeButtonsTracks.width - margin, yButtonsTracks, sizeButtonsTracks))
		btnNext.setImage(#imageLiteral(resourceName: "btn-next").tinted(withColor: .white), for: .normal)
		btnNext.addTarget(mpdBridge, action: #selector(MPDBridge.requestNextTrack), for: .touchUpInside)
		blurEffectView.contentView.addSubview(btnNext)

		// Slider volume
		sliderVolume = UISlider(frame: CGRect(margin, btnPrevious.maxY + 16, tframe.width, 31))
		sliderVolume.addTarget(self, action: #selector(changeVolumeAction(_:)), for: .touchUpInside)
		sliderVolume.minimumValue = 0
		sliderVolume.maximumValue = 100
		sliderVolume.minimumValueImage = #imageLiteral(resourceName: "img-volume-lo").tinted(withColor: .white)
		sliderVolume.maximumValueImage = #imageLiteral(resourceName: "img-volume-hi").tinted(withColor: .white)
		blurEffectView.contentView.addSubview(sliderVolume)

		// Repeat button
		let loop = Settings.shared.bool(forKey: .mpd_repeat)
		let sizeButtonsRR = CGSize(44, 44)
		let imageRepeat = #imageLiteral(resourceName: "btn-repeat")
		btnRepeat = UIButton(frame: CGRect(margin, view.height - sizeButtonsRR.height, sizeButtonsRR))
		btnRepeat.setImage(imageRepeat.tinted(withColor: .white)?.withRenderingMode(.alwaysOriginal), for: .normal)
		btnRepeat.isSelected = loop
		btnRepeat.addTarget(self, action: #selector(toggleRepeatAction(_:)), for: .touchUpInside)
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")
		self.blurEffectView.contentView.addSubview(btnRepeat)

		// Random button
		let random = Settings.shared.bool(forKey: .mpd_shuffle)
		let imageRandom = #imageLiteral(resourceName: "btn-random")
		btnRandom = UIButton(frame: CGRect(width - margin - sizeButtonsRR.width, view.height - sizeButtonsRR.height, sizeButtonsRR))
		btnRandom.setImage(imageRandom.tinted(withColor: .white)?.withRenderingMode(.alwaysOriginal), for: .normal)
		btnRandom.isSelected = random
		btnRandom.addTarget(self, action: #selector(toggleRandomAction(_:)), for: .touchUpInside)
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")
		blurEffectView.contentView.addSubview(btnRandom)

		// Useless motion effect
		var motionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
		motionEffect.minimumRelativeValue = 20
		motionEffect.maximumRelativeValue = -20
		coverView.addMotionEffect(motionEffect)
		motionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
		motionEffect.minimumRelativeValue = 20
		motionEffect.maximumRelativeValue = -20
		coverView.addMotionEffect(motionEffect)

		// Single tap, two fingers
		let singleTapWith2Fingers1 = UITapGestureRecognizer()
		singleTapWith2Fingers1.numberOfTapsRequired = 1
		singleTapWith2Fingers1.numberOfTouchesRequired = 2
		singleTapWith2Fingers1.addTarget(self, action: #selector(singleTapWithTwoFingers(_:)))
		coverView.addGestureRecognizer(singleTapWith2Fingers1)

		let singleTapWith2Fingers2 = UITapGestureRecognizer()
		singleTapWith2Fingers2.numberOfTapsRequired = 1
		singleTapWith2Fingers2.numberOfTouchesRequired = 2
		singleTapWith2Fingers2.addTarget(self, action: #selector(singleTapWithTwoFingers(_:)))
		trackListView.addGestureRecognizer(singleTapWith2Fingers2)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackNotification(_:)), name: .currentPlayingTrack, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(playerStatusChangedNotification(_:)), name: .playerStatusChanged, object: nil)

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
					self.sliderVolume.value = Float(volume)
					self.sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(volume)%"
				}
			}
		}

		if let track = mpdBridge.getCurrentTrack(), let album = mpdBridge.getCurrentAlbum()
		{
			lblTrackTitle.text = track.name
			lblTrackArtist.text = track.artist
			lblAlbumName.text = album.name
			sliderPosition.maximumValue = Float(track.duration.seconds)
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

		updatePlayPauseButton()
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		NotificationCenter.default.removeObserver(self, name: .currentPlayingTrack, object: nil)
		NotificationCenter.default.removeObserver(self, name: .playingTrackChanged, object: nil)
		NotificationCenter.default.removeObserver(self, name: .playerStatusChanged, object: nil)
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	// MARK: - InteractableImageViewDelegate
	func didTap()
	{
		dismiss(animated: true, completion: nil)
		MiniPlayerView.shared.stayHidden = false
		MiniPlayerView.shared.show()
	}

	@objc func singleTapWithTwoFingers(_ gesture: UITapGestureRecognizer)
	{
		if gesture.state != .ended
		{
			return
		}

		if gesture.view === coverView
		{
			trackListView.transform = CGAffineTransform(scaleX: -1, y: 1)
			trackListView.alpha = 0
			if let tracks = mpdBridge.getCurrentAlbum()?.tracks
			{
				trackListView.tracks = tracks
			}
			else
			{
				mpdBridge.getTracksForAlbums([mpdBridge.getCurrentAlbum()!]) { (tracks) in
					DispatchQueue.main.async {
						if let tracks = self.mpdBridge.getCurrentAlbum()?.tracks
						{
							self.trackListView.tracks = tracks
						}
					}
				}
			}

			UIView.animate(withDuration: 0.5, delay: 0, options: [.curveLinear], animations: {
				self.coverView.alpha = 0
				self.trackListView.alpha = 1
				self.coverView.transform = CGAffineTransform(scaleX: -1, y: 1)
				self.trackListView.transform = CGAffineTransform(scaleX: 1, y: 1)
			}) { (finished) in
				
			}
		}
		else
		{
			UIView.animate(withDuration: 0.5, delay: 0, options: [.curveLinear], animations: {
				self.coverView.alpha = 1
				self.trackListView.alpha = 0
				self.coverView.transform = CGAffineTransform(scaleX: 1, y: 1)
				self.trackListView.transform = CGAffineTransform(scaleX: -1, y: 1)
			}) { (finished) in
				
			}
		}
	}

	// MARK: - Buttons actions
	@objc func toggleRandomAction(_ sender: Any?)
	{
		let random = !Settings.shared.bool(forKey: .mpd_shuffle)

		btnRandom.isSelected = random
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		Settings.shared.set(random, forKey: .mpd_shuffle)

		mpdBridge.setRandom(random)
	}

	@objc func toggleRepeatAction(_ sender: Any?)
	{
		let loop = !Settings.shared.bool(forKey: .mpd_repeat)

		btnRepeat.isSelected = loop
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		Settings.shared.set(loop, forKey: .mpd_repeat)

		mpdBridge.setRepeat(loop)
	}

	@objc func changeTrackPositionAction(_ sender: UISlider?)
	{
		if let track = mpdBridge.getCurrentTrack()
		{
			mpdBridge.setTrackPosition(Int(sliderPosition.value), trackPosition: track.position)
		}
	}

	@objc func changeVolumeAction(_ sender: UISlider?)
	{
		setVolume(sliderVolume.value)
	}

	// MARK: - Notifications
	@objc func playingTrackNotification(_ aNotification: Notification?)
	{
		guard let track = aNotification?.userInfo![PLAYER_TRACK_KEY] as? Track, let elapsed = aNotification?.userInfo![PLAYER_ELAPSED_KEY] as? Int else
		{
			return
		}

		if !sliderPosition.isSelected && !sliderPosition.isHighlighted
		{
			sliderPosition.setValue(Float(elapsed), animated: true)
			sliderPosition.accessibilityLabel = "\(NYXLocalizedString("lbl_track_position")) : \(Int((sliderPosition.value * 100) / sliderPosition.maximumValue))%"
		}

		let elapsedDuration = Duration(seconds: elapsed)
		let remainingDuration = track.duration - elapsedDuration
		lblElapsedDuration.text = elapsedDuration.minutesRepresentationAsString()
		lblRemainingDuration.text = "-\(remainingDuration.minutesRepresentationAsString())"
	}

	@objc func playingTrackChangedNotification(_ aNotification: Notification?)
	{
		guard let track = aNotification?.userInfo![PLAYER_TRACK_KEY] as? Track, let album = aNotification?.userInfo![PLAYER_ALBUM_KEY] as? Album else
		{
			return
		}
		lblTrackTitle.text = track.name
		lblTrackArtist.text = track.artist
		lblAlbumName.text = album.name
		sliderPosition.maximumValue = Float(track.duration.seconds)

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
	}

	// MARK: - Private
	private func updatePlayPauseButton()
	{
		if mpdBridge.getCurrentStatus() == .paused
		{
			let imgPlay = #imageLiteral(resourceName: "btn-play")
			btnPlay.setImage(imgPlay.tinted(withColor: .white), for: .normal)
			btnPlay.setImage(imgPlay.tinted(withColor: themeProvider.currentTheme.tintColor), for: .highlighted)
			btnPlay.setImage(imgPlay.tinted(withColor: themeProvider.currentTheme.tintColor), for: .selected)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			let imgPause = #imageLiteral(resourceName: "btn-pause")
			btnPlay.setImage(imgPause.tinted(withColor: .white), for: .normal)
			btnPlay.setImage(imgPause.tinted(withColor: themeProvider.currentTheme.tintColor), for: .highlighted)
			btnPlay.setImage(imgPause.tinted(withColor: themeProvider.currentTheme.tintColor), for: .selected)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}
	}

	func setVolume(_ valueToSet: Float)
	{
		let tmp = clamp(ceil(valueToSet), lower: 0, upper: 100)
		let volume = Int(tmp)

		mpdBridge.setVolume(volume) { (success) in
			if success
			{
				DispatchQueue.main.async {
					self.sliderVolume.value = tmp
					self.sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(volume)%"
				}
			}
		}
	}
}

// MARK: - UITableViewDelegate
extension PlayerVC: UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Toggle play / pause for the current track
		if let currentPlayingTrack = mpdBridge.getCurrentTrack()
		{
			let selectedTrack = trackListView.tracks[indexPath.row]
			if selectedTrack == currentPlayingTrack
			{
				mpdBridge.togglePause()
				return
			}
		}

		let b = trackListView.tracks.filter { $0.trackNumber >= (indexPath.row + 1) }
		mpdBridge.playTracks(b, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
	}
}

final class PlayerVCCustomPresentAnimationController: NSObject, UIViewControllerAnimatedTransitioning
{
	var presenting = true

	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
	{
		return 0.8
	}

	func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
	{
		let containerView = transitionContext.containerView
		let bounds = UIScreen.main.bounds

		if presenting
		{
			let toViewController = transitionContext.viewController(forKey: .to)! as! PlayerVC
			containerView.addSubview(toViewController.view)

			let iv = UIImageView(frame: CGRect(0, bounds.height - MiniPlayerView.shared.imageView.height, MiniPlayerView.shared.imageView.height, MiniPlayerView.shared.imageView.height))
			iv.backgroundColor = .clear
			iv.image = MiniPlayerView.shared.imageView.image
			if let coverURL = toViewController.mpdBridge.getCurrentAlbum()?.localCoverURL
			{
				if let cover = UIImage.loadFromFileURL(coverURL)
				{
					iv.image = cover
				}
			}
			toViewController.coverView.image = iv.image
			containerView.addSubview(iv)

			toViewController.view.alpha = 0
			MiniPlayerView.shared.stayHidden = true
			UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
				iv.frame = CGRect(32, UIDevice.current.isiPhoneX() ? 124 : 100, bounds.width - 64, bounds.width - 64)
				MiniPlayerView.shared.hide()
			}, completion: { (finished) in
				UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
					toViewController.view.alpha = 1
				}, completion: { (finished) in
					iv.removeFromSuperview()
					transitionContext.completeTransition(true)
				})
			})
		}
		else
		{
			let fromViewController = transitionContext.viewController(forKey: .from) as! PlayerVC

			let iv = UIImageView(frame: CGRect(32, 100, bounds.width - 64, bounds.width - 64))
			iv.backgroundColor = .clear
			iv.image = fromViewController.coverView.image
			iv.alpha = 0
			containerView.addSubview(iv)

			UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
				fromViewController.view.alpha = 0
				iv.alpha = 1
			}, completion: { (finished) in
				UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
					iv.frame = CGRect(0, bounds.height - MiniPlayerView.shared.imageView.height, MiniPlayerView.shared.imageView.height, MiniPlayerView.shared.imageView.height)
				}, completion: { (finished) in
					transitionContext.completeTransition(true)
					iv.removeFromSuperview()
					let toViewController = transitionContext.viewController(forKey: .to)!
					toViewController.setNeedsStatusBarAppearanceUpdate()
				})
			})
		}
	}
}

extension PlayerVC: TracksListTableViewDelegate
{
	func getCurrentTrack() -> Track?
	{
		return mpdBridge.getCurrentTrack()
	}
}

extension PlayerVC: Themed
{
	func applyTheme(_ theme: ShinobuTheme)
	{
		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous").tinted(withColor: theme.tintColor), for: .highlighted)
		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous").tinted(withColor: theme.tintColor), for: .selected)
		btnNext.setImage(#imageLiteral(resourceName: "btn-next").tinted(withColor: theme.tintColor), for: .highlighted)
		btnNext.setImage(#imageLiteral(resourceName: "btn-next").tinted(withColor: theme.tintColor), for: .selected)

		let imageRepeat = #imageLiteral(resourceName: "btn-repeat")
		let imageRandom = #imageLiteral(resourceName: "btn-random")
		btnRepeat.setImage(imageRepeat.tinted(withColor: theme.tintColor)?.withRenderingMode(.alwaysOriginal), for: .highlighted)
		btnRandom.setImage(imageRandom.tinted(withColor: theme.tintColor)?.withRenderingMode(.alwaysOriginal), for: .highlighted)

	}
}
