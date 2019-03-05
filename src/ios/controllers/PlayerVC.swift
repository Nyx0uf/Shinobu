import UIKit


final class PlayerVC : NYXViewController, InteractableImageViewDelegate
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
	// Low volume image
	private var btnVolumeLo: UIButton! = nil
	// High volume image
	private var btnVolumeHi: UIButton! = nil
	// Album tracks view
	private var trackListView: TracksListTableView! = nil

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Blurred background
		self.view = UIImageView(frame: self.view.bounds)
		self.view.isUserInteractionEnabled = true
		self.blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
		self.blurEffectView.frame = self.view.bounds
		self.view.addSubview(blurEffectView)

		let statusHeight: CGFloat
		if let top = UIApplication.shared.keyWindow?.safeAreaInsets.top
		{
			statusHeight = top < 20 ? 20 : top
		}
		else
		{
			statusHeight = 20
		}

		// Track title
		let vev_title = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_title.frame = CGRect(0, statusHeight, self.view.width, 20)
		lblTrackTitle = AutoScrollLabel(frame: vev_title.bounds)
		lblTrackTitle.font = UIFont.systemFont(ofSize: 15, weight: .bold)
		lblTrackTitle.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		lblTrackTitle.textAlignment = .center
		vev_title.contentView.addSubview(lblTrackTitle)
		self.blurEffectView.contentView.addSubview(vev_title)

		// Track artist
		let vev_artist = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_artist.frame = CGRect(0, vev_title.bottom, self.view.width, 20)
		lblTrackArtist = UILabel(frame: vev_artist.bounds)
		lblTrackArtist.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		lblTrackArtist.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		lblTrackArtist.textAlignment = .center
		vev_artist.contentView.addSubview(lblTrackArtist)
		self.blurEffectView.contentView.addSubview(vev_artist)

		// Album
		let vev_album = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_album.frame = CGRect(0, vev_artist.bottom, self.view.width, 20)
		lblAlbumName = UILabel(frame: vev_album.bounds)
		lblAlbumName.font = UIFont.systemFont(ofSize: 13, weight: .light)
		lblAlbumName.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		lblAlbumName.textAlignment = .center
		vev_album.contentView.addSubview(lblAlbumName)
		self.blurEffectView.contentView.addSubview(vev_album)

		// Track list view
		let theight = self.view.width - 64
		let tframe = CGRect(32, vev_album.bottom + 20, theight, theight)
		trackListView = TracksListTableView(frame: tframe, style: .plain)
		trackListView.delegate = self
		self.blurEffectView.contentView.addSubview(trackListView)

		// Cover
		coverView = InteractableImageView(frame: tframe)
		coverView.delegate = self
		self.blurEffectView.contentView.addSubview(coverView)

		// Elapsed label
		let vev_elapsed = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_elapsed.frame = CGRect(coverView.left, coverView.bottom + 4, 40, 16)
		lblElapsedDuration = UILabel(frame: vev_elapsed.bounds)
		lblElapsedDuration.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		lblElapsedDuration.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		lblElapsedDuration.textAlignment = .left
		vev_elapsed.contentView.addSubview(lblElapsedDuration)
		self.blurEffectView.contentView.addSubview(vev_elapsed)

		// Remaining label
		let vev_remaining = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_remaining.frame = CGRect(self.view.width - 32 - 40, coverView.bottom + 4, 40, 16)
		lblRemainingDuration = UILabel(frame: vev_remaining.bounds)
		lblRemainingDuration.font = UIFont.systemFont(ofSize: 12, weight: .regular)
		lblRemainingDuration.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		lblRemainingDuration.textAlignment = .right
		vev_remaining.contentView.addSubview(lblRemainingDuration)
		self.blurEffectView.contentView.addSubview(vev_remaining)

		// Slider track position
		sliderPosition = UISlider(frame: CGRect(32, vev_remaining.bottom, tframe.width, 31))
		sliderPosition.addTarget(self, action: #selector(changeTrackPositionAction(_:)), for: .touchUpInside)
		self.blurEffectView.contentView.addSubview(sliderPosition)

		// Previous button
		btnPrevious = UIButton(frame: CGRect(32, sliderPosition.bottom + 16, 48, 48))
		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous").tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for: .normal)
		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous").tinted(withColor: Colors.mainEnabled), for: .highlighted)
		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous").tinted(withColor: Colors.mainEnabled), for: .selected)
		btnPrevious.addTarget(PlayerController.shared, action: #selector(PlayerController.requestPreviousTrack), for: .touchUpInside)
		self.blurEffectView.contentView.addSubview(btnPrevious)

		// Play/Pause button
		btnPlay = UIButton(frame: CGRect((self.view.width - 48) / 2, sliderPosition.bottom + 16, 48, 48))
		btnPlay.addTarget(PlayerController.shared, action: #selector(PlayerController.togglePause), for: .touchUpInside)
		self.blurEffectView.contentView.addSubview(btnPlay)

		// Next button
		btnNext = UIButton(frame: CGRect(self.view.width - 48 - 32, sliderPosition.bottom + 16, 48, 48))
		btnNext.setImage(#imageLiteral(resourceName: "btn-next").tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for: .normal)
		btnNext.setImage(#imageLiteral(resourceName: "btn-next").tinted(withColor: Colors.mainEnabled), for: .highlighted)
		btnNext.setImage(#imageLiteral(resourceName: "btn-next").tinted(withColor: Colors.mainEnabled), for: .selected)
		btnNext.addTarget(PlayerController.shared, action: #selector(PlayerController.requestNextTrack), for: .touchUpInside)
		self.blurEffectView.contentView.addSubview(btnNext)

		// Vol- button
		let vev_volm = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_volm.frame = CGRect(32, btnPrevious.bottom + 12, 18, 18)
		btnVolumeLo = UIButton(frame: vev_volm.bounds)
		btnVolumeLo.addTarget(self, action: #selector(decreaseVolumeAction(_:)), for: .touchUpInside)
		btnVolumeLo.setImage(#imageLiteral(resourceName: "img-volume-lo").tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for: .normal)
		btnVolumeLo.setImage(#imageLiteral(resourceName: "img-volume-lo").tinted(withColor: Colors.mainEnabled), for: .highlighted)
		btnVolumeLo.setImage(#imageLiteral(resourceName: "img-volume-lo").tinted(withColor: Colors.mainEnabled), for: .selected)
		vev_volm.contentView.addSubview(btnVolumeLo)
		self.blurEffectView.contentView.addSubview(vev_volm)

		// Vol+ button
		let vev_volp = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
		vev_volp.frame = CGRect(self.view.width - 32 - 18,  btnNext.bottom + 12, 18, 18)
		btnVolumeHi = UIButton(frame: vev_volp.bounds)
		btnVolumeHi.addTarget(self, action: #selector(increaseVolumeAction(_:)), for: .touchUpInside)
		btnVolumeHi.setImage(#imageLiteral(resourceName: "img-volume-hi").tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for: .normal)
		btnVolumeHi.setImage(#imageLiteral(resourceName: "img-volume-hi").tinted(withColor: Colors.mainEnabled), for: .highlighted)
		btnVolumeHi.setImage(#imageLiteral(resourceName: "img-volume-hi").tinted(withColor: Colors.mainEnabled), for: .selected)
		vev_volp.contentView.addSubview(btnVolumeHi)
		self.blurEffectView.contentView.addSubview(vev_volp)

		// Slider volume
		sliderVolume = UISlider(frame: CGRect(32, vev_volp.bottom + 2, tframe.width, 31))
		sliderVolume.addTarget(self, action: #selector(changeVolumeAction(_:)), for: .touchUpInside)
		sliderVolume.minimumValue = 0
		sliderVolume.maximumValue = 100
		self.blurEffectView.contentView.addSubview(sliderVolume)

		// Repeat button
		let loop = Settings.shared.bool(forKey: .mpd_repeat)
		let imageRepeat = #imageLiteral(resourceName: "btn-repeat")
		btnRepeat = UIButton(frame: CGRect(32, self.view.height - 44, 44, 44))
		btnRepeat.setImage(imageRepeat.tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .normal)
		btnRepeat.setImage(imageRepeat.tinted(withColor: Colors.mainEnabled)?.withRenderingMode(.alwaysOriginal), for: .highlighted)
		btnRepeat.isSelected = loop
		btnRepeat.addTarget(self, action: #selector(toggleRepeatAction(_:)), for: .touchUpInside)
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")
		self.blurEffectView.contentView.addSubview(btnRepeat)

		// Random button
		let random = Settings.shared.bool(forKey: .mpd_shuffle)
		let imageRandom = #imageLiteral(resourceName: "btn-random")
		btnRandom = UIButton(frame: CGRect(self.view.width - 44 - 32, self.view.height - 44, 44, 44))
		btnRandom.setImage(imageRandom.tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .normal)
		btnRandom.setImage(imageRandom.tinted(withColor: Colors.mainEnabled)?.withRenderingMode(.alwaysOriginal), for: .highlighted)
		btnRandom.isSelected = random
		btnRandom.addTarget(self, action: #selector(toggleRandomAction(_:)), for: .touchUpInside)
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")
		self.blurEffectView.contentView.addSubview(btnRandom)

		// Useless motion effect
		var motionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
		coverView.addMotionEffect(motionEffect)
		motionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
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
		let random = !Settings.shared.bool(forKey: .mpd_shuffle)

		btnRandom.isSelected = random
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		Settings.shared.set(random, forKey: .mpd_shuffle)

		PlayerController.shared.setRandom(random)
	}

	@objc func toggleRepeatAction(_ sender: Any?)
	{
		let loop = !Settings.shared.bool(forKey: .mpd_repeat)

		btnRepeat.isSelected = loop
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		Settings.shared.set(loop, forKey: .mpd_repeat)

		PlayerController.shared.setRepeat(loop)
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
			btnPlay.setImage(imgPlay.tinted(withColor: Colors.mainEnabled), for: .highlighted)
			btnPlay.setImage(imgPlay.tinted(withColor: Colors.mainEnabled), for: .selected)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			let imgPause = #imageLiteral(resourceName: "btn-pause")
			btnPlay.setImage(imgPause.tinted(withColor: #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for: .normal)
			btnPlay.setImage(imgPause.tinted(withColor: Colors.mainEnabled), for: .highlighted)
			btnPlay.setImage(imgPause.tinted(withColor: Colors.mainEnabled), for: .selected)
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
		PlayerController.shared.playTracks(b, shuffle: Settings.shared.bool(forKey: .mpd_shuffle), loop: Settings.shared.bool(forKey: .mpd_repeat))
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
