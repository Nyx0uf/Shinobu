import UIKit


final class PlayerVC : UIViewController, InteractableImageViewDelegate
{
	// MARK: - Private properties
	// Blur view
	@IBOutlet private var blurEffectView: UIVisualEffectView! = nil
	// Cover view
	@IBOutlet fileprivate var coverView: InteractableImageView! = nil
	// Track title
	@IBOutlet private var lblTrackTitle: AutoScrollLabel! = nil
	// Track artist name
	@IBOutlet private var lblTrackArtist: UILabel! = nil
	// Album name
	@IBOutlet private var lblAlbumName: UILabel! = nil
	// Play/Pause button
	@IBOutlet private var btnPlay: UIButton! = nil
	// Next button
	@IBOutlet private var btnNext: UIButton! = nil
	// Previous button
	@IBOutlet private var btnPrevious: UIButton! = nil
	// Random button
	@IBOutlet private var btnRandom: UIButton! = nil
	// Repeat button
	@IBOutlet private var btnRepeat: UIButton! = nil
	// Song technical info button
	@IBOutlet private var btnStats: UIButton! = nil
	// Progress bar
	@IBOutlet private var sliderPosition: UISlider! = nil
	// Track title
	@IBOutlet private var lblElapsedDuration: UILabel! = nil
	// Track artist name
	@IBOutlet private var lblRemainingDuration: UILabel! = nil
	// Bit depth & samplerate
	@IBOutlet private var lblTrackInformation: UILabel! = nil
	// Volume control
	@IBOutlet private var sliderVolume: UISlider! = nil
	// Low volume image
	@IBOutlet private var btnVolumeLo: UIButton! = nil
	// High volume image
	@IBOutlet private var btnVolumeHi: UIButton! = nil
	// Album tracks view
	@IBOutlet private var trackListView: TracksListTableView! = nil

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		trackListView.delegate = self

		// Slider track position
		sliderPosition.addTarget(self, action: #selector(changeTrackPositionAction(_:)), for: .touchUpInside)

		// Slider volume
		sliderVolume.addTarget(self, action: #selector(changeVolumeAction(_:)), for: .touchUpInside)
		btnVolumeLo.addTarget(self, action: #selector(decreaseVolumeAction(_:)), for: .touchUpInside)
		btnVolumeHi.addTarget(self, action: #selector(increaseVolumeAction(_:)), for: .touchUpInside)
		btnVolumeLo.setImage(#imageLiteral(resourceName: "img-volume-lo").tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for: .normal)
		btnVolumeLo.setImage(#imageLiteral(resourceName: "img-volume-lo").tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1)), for: .highlighted)
		btnVolumeHi.setImage(#imageLiteral(resourceName: "img-volume-hi").tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for: .normal)
		btnVolumeHi.setImage(#imageLiteral(resourceName: "img-volume-hi").tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1)), for: .highlighted)

		btnPlay.addTarget(PlayerController.shared, action: #selector(PlayerController.togglePause), for: .touchUpInside)

		btnNext.setImage(#imageLiteral(resourceName: "btn-next").tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for: .normal)
		btnNext.setImage(#imageLiteral(resourceName: "btn-next").tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1)), for: .highlighted)
		btnNext.addTarget(PlayerController.shared, action: #selector(PlayerController.requestNextTrack), for: .touchUpInside)

		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous").tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for: .normal)
		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous").tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1)), for: .highlighted)
		btnPrevious.addTarget(PlayerController.shared, action: #selector(PlayerController.requestPreviousTrack), for: .touchUpInside)

		let loop = Settings.shared.bool(forKey: Settings.keys.mpd_repeat)
		let imageRepeat = #imageLiteral(resourceName: "btn-repeat")
		btnRepeat.setImage(imageRepeat.tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .normal)
		btnRepeat.setImage(imageRepeat.tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .highlighted)
		btnRepeat.setImage(imageRepeat.tinted(withColor: #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .selected)
		btnRepeat.isSelected = loop
		btnRepeat.addTarget(self, action: #selector(toggleRepeatAction(_:)), for: .touchUpInside)
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		let random = Settings.shared.bool(forKey: Settings.keys.mpd_shuffle)
		let imageRandom = #imageLiteral(resourceName: "btn-random")
		btnRandom.setImage(imageRandom.tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .normal)
		btnRandom.setImage(imageRandom.tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .highlighted)
		btnRandom.setImage(imageRandom.tinted(withColor: #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .selected)
		btnRandom.isSelected = random
		btnRandom.addTarget(self, action: #selector(toggleRandomAction(_:)), for: .touchUpInside)
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		let imageStats = #imageLiteral(resourceName: "btn-stats")
		btnStats.setImage(imageStats.tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .normal)
		btnStats.setImage(imageStats.tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .highlighted)
		btnStats.setImage(imageStats.tinted(withColor: #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .selected)
		btnStats.addTarget(self, action: #selector(toggleStats(_:)), for: .touchUpInside)
		btnStats.accessibilityLabel = NYXLocalizedString("lbl_show_songs_stats")

		coverView.delegate = self
		// Useless motion effect
		var motionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
		coverView.addMotionEffect(motionEffect)
		motionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
		coverView.addMotionEffect(motionEffect)

		lblTrackTitle.font = UIFont(name: "GillSans-Bold", size: 15.0)
		lblTrackTitle.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		lblTrackTitle.textAlignment = .center

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

		PlayerController.shared.getVolume { (volume: Int) in
			DispatchQueue.main.async {
				if volume == -1
				{
					self.sliderVolume.isHidden = true
					self.btnVolumeLo.isHidden = true
					self.btnVolumeHi.isHidden = true
					self.sliderVolume.value = 0
					self.sliderVolume.accessibilityLabel = NYXLocalizedString("lbl_volume_control_disabled")
				}
				else
				{
					self.sliderVolume.isHidden = false
					self.btnVolumeLo.isHidden = false
					self.btnVolumeHi.isHidden = false
					self.btnVolumeLo.isEnabled = volume > 0
					self.btnVolumeHi.isEnabled = volume < 100
					self.sliderVolume.value = Float(volume)
					self.sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(volume)%"
				}
			}
		}

		if let track = PlayerController.shared.currentTrack, let album = PlayerController.shared.currentAlbum
		{
			lblTrackTitle.text = track.name
			lblTrackArtist.text = track.artist
			lblAlbumName.text = album.name
			sliderPosition.maximumValue = Float(track.duration.seconds)
			let iv = view as? UIImageView

			if album.path != nil
			{
				let op = CoverOperation(album: album, cropSize: coverView.size)
				op.callback = {(cover: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						self.coverView.image = cover
						iv?.image = cover
					}
				}
				OperationManager.shared.addOperation(op)
			}
			else
			{
				let size = self.coverView.size
				MusicDataSource.shared.getPathForAlbum(album) {
					let op = CoverOperation(album: album, cropSize: size)
					op.callback = {(cover: UIImage, thumbnail: UIImage) in
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

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation
	{
		return .portrait
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
			trackListView.alpha = 0.0
			if let tracks = PlayerController.shared.currentAlbum?.tracks
			{
				trackListView.tracks = tracks
			}
			else
			{
				MusicDataSource.shared.getTracksForAlbums([PlayerController.shared.currentAlbum!], callback: {
					if let tracks = PlayerController.shared.currentAlbum?.tracks
					{
						DispatchQueue.main.async {
							self.trackListView.tracks = tracks
						}
					}
				})
			}

			UIView.animate(withDuration: 0.5, delay: 0, options: [.curveLinear], animations: {
				self.coverView.alpha = 0.0
				self.trackListView.alpha = 1.0
				self.coverView.transform = CGAffineTransform(scaleX: -1, y: 1)
				self.trackListView.transform = CGAffineTransform(scaleX: 1, y: 1)
			}) { (finished) in
				
			}
		}
		else
		{
			UIView.animate(withDuration: 0.5, delay: 0, options: [.curveLinear], animations: {
				self.coverView.alpha = 1.0
				self.trackListView.alpha = 0.0
				self.coverView.transform = CGAffineTransform(scaleX: 1, y: 1)
				self.trackListView.transform = CGAffineTransform(scaleX: -1, y: 1)
			}) { (finished) in
				
			}
		}
	}

	// MARK: - Buttons actions
	@objc func toggleRandomAction(_ sender: Any?)
	{
		let random = !Settings.shared.bool(forKey: Settings.keys.mpd_shuffle)

		btnRandom.isSelected = random
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		Settings.shared.set(random, forKey: Settings.keys.mpd_shuffle)

		PlayerController.shared.setRandom(random)
	}

	@objc func toggleRepeatAction(_ sender: Any?)
	{
		let loop = !Settings.shared.bool(forKey: Settings.keys.mpd_repeat)

		btnRepeat.isSelected = loop
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		Settings.shared.set(loop, forKey: Settings.keys.mpd_repeat)

		PlayerController.shared.setRepeat(loop)
	}

	@objc func toggleStats(_ sender: Any?)
	{
		if lblTrackInformation.isHidden == false
		{
			lblTrackInformation.isHidden = true
			return
		}

		self.updateCurrentTrackInformation()
	}

	@objc func changeTrackPositionAction(_ sender: UISlider?)
	{
		if let track = PlayerController.shared.currentTrack
		{
			PlayerController.shared.setTrackPosition(Int(sliderPosition.value), trackPosition: track.position)
		}
	}

	@objc func changeVolumeAction(_ sender: UISlider?)
	{
		setVolume(sliderVolume.value)
	}

	@objc func increaseVolumeAction(_ sender: UIButton?)
	{
		setVolume(sliderVolume.value + 1)
	}

	@objc func decreaseVolumeAction(_ sender: UIButton?)
	{
		setVolume(sliderVolume.value - 1)
	}

	// MARK: - Notifications
	@objc func playingTrackNotification(_ aNotification: Notification?)
	{
		guard let track = aNotification?.userInfo![kPlayerTrackKey] as? Track, let elapsed = aNotification?.userInfo![kPlayerElapsedKey] as? Int else
		{
			return
		}

		if !sliderPosition.isSelected && !sliderPosition.isHighlighted
		{
			sliderPosition.setValue(Float(elapsed), animated: true)
			sliderPosition.accessibilityLabel = "\(NYXLocalizedString("lbl_track_position")) : \(Int((sliderPosition.value * 100.0) / sliderPosition.maximumValue))%"
		}

		let elapsedDuration = Duration(seconds: elapsed)
		let remainingDuration = track.duration - elapsedDuration
		lblElapsedDuration.text = elapsedDuration.minutesRepresentationAsString()
		lblRemainingDuration.text = "-\(remainingDuration.minutesRepresentationAsString())"
	}

	@objc func playingTrackChangedNotification(_ aNotification: Notification?)
	{
		guard let track = aNotification?.userInfo![kPlayerTrackKey] as? Track, let album = aNotification?.userInfo![kPlayerAlbumKey] as? Album else
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
			op.callback = {(cover: UIImage, thumbnail: UIImage) in
				DispatchQueue.main.async {
					self.coverView.image = cover
					iv?.image = cover
				}
			}
			OperationManager.shared.addOperation(op)
		}
		else
		{
			let size = self.coverView.size
			MusicDataSource.shared.getPathForAlbum(album) {
				let op = CoverOperation(album: album, cropSize: size)
				op.callback = {(cover: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						self.coverView.image = cover
						iv?.image = cover
					}
				}
				OperationManager.shared.addOperation(op)
			}
		}

		self.updateCurrentTrackInformation()
	}

	@objc func playerStatusChangedNotification(_ aNotification: Notification?)
	{
		updatePlayPauseButton()
	}

	// MARK: - Private
	private func updatePlayPauseButton()
	{
		if PlayerController.shared.currentStatus == .paused
		{
			let imgPlay = #imageLiteral(resourceName: "btn-play")
			btnPlay.setImage(imgPlay.tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for: .normal)
			btnPlay.setImage(imgPlay.tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1)), for: .highlighted)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			let imgPause = #imageLiteral(resourceName: "btn-pause")
			btnPlay.setImage(imgPause.tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for: .normal)
			btnPlay.setImage(imgPause.tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1)), for: .highlighted)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}
	}

	func setVolume(_ valueToSet: Float)
	{
		let tmp = clamp(ceil(valueToSet), lower: 0.0, upper: 100.0)
		let volume = Int(tmp)

		PlayerController.shared.setVolume(volume) { (success: Bool) in
			if success
			{
				DispatchQueue.main.async {
					self.sliderVolume.value = tmp
					self.sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(volume)%"
					self.btnVolumeLo.isEnabled = valueToSet > 0
					self.btnVolumeHi.isEnabled = valueToSet < 100
				}
			}
		}
	}

	func updateCurrentTrackInformation()
	{
		if let track = PlayerController.shared.currentTrack
		{
			PlayerController.shared.getTrackInformation(track, callback: { (infos: [String : String]) in
				let channels = Int(infos["channels"]!)!
				let bits = Int(infos["bits"]!)!
				let samplerate = Int(infos["samplerate"]!)!
				let formatted = "\(bits)Bits / \(samplerate)Hz (\(channels == 1 ? "Mono" : "Stereo"))"
				DispatchQueue.main.async {
					self.lblTrackInformation.text = formatted
					self.lblTrackInformation.isHidden = false
				}
			})
		}
	}
}

// MARK: - UITableViewDelegate
extension PlayerVC : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Toggle play / pause for the current track
		if let currentPlayingTrack = PlayerController.shared.currentTrack
		{
			let selectedTrack = trackListView.tracks[indexPath.row]
			if selectedTrack == currentPlayingTrack
			{
				PlayerController.shared.togglePause()
				return
			}
		}

		let b = trackListView.tracks.filter({$0.trackNumber >= (indexPath.row + 1)})
		PlayerController.shared.playTracks(b, shuffle: Settings.shared.bool(forKey: Settings.keys.mpd_shuffle), loop: Settings.shared.bool(forKey: Settings.keys.mpd_repeat))
	}
}

final class PlayerVCCustomPresentAnimationController : NSObject, UIViewControllerAnimatedTransitioning
{
	var presenting: Bool = true

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
			iv.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 0)
			iv.image = MiniPlayerView.shared.imageView.image
			if let coverURL = PlayerController.shared.currentAlbum?.localCoverURL
			{
				if let cover = UIImage.loadFromFileURL(coverURL)
				{
					iv.image = cover
				}
			}
			toViewController.coverView.image = iv.image
			containerView.addSubview(iv)

			toViewController.view.alpha = 0.0
			MiniPlayerView.shared.stayHidden = true
			UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
				iv.frame = CGRect(32, UIDevice.current.isiPhoneX() ? 124 : 100, bounds.width - 64, bounds.width - 64)
				MiniPlayerView.shared.hide()
			}, completion: { finished in
				UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: {
					toViewController.view.alpha = 1.0
				}, completion: { finished in
					iv.removeFromSuperview()
					transitionContext.completeTransition(true)
				})
			})
		}
		else
		{
			let fromViewController = transitionContext.viewController(forKey: .from) as! PlayerVC

			let iv = UIImageView(frame: CGRect(32, 100, bounds.width - 64, bounds.width - 64))
			iv.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 0)
			iv.image = fromViewController.coverView.image
			iv.alpha = 0.0
			containerView.addSubview(iv)

			UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: {
				fromViewController.view.alpha = 0.0
				iv.alpha = 1.0
			}, completion: { finished in
				UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
					iv.frame = CGRect(0, bounds.height - MiniPlayerView.shared.imageView.height, MiniPlayerView.shared.imageView.height, MiniPlayerView.shared.imageView.height)
				}, completion: { finished in
					transitionContext.completeTransition(true)
					iv.removeFromSuperview()
					let toViewController = transitionContext.viewController(forKey: .to)!
					toViewController.setNeedsStatusBarAppearanceUpdate()
				})
			})
		}
	}
}
