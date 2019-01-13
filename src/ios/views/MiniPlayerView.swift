// MiniPlayerView.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit


let baseHeight = CGFloat(44.0)


final class MiniPlayerView : UIView
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = MiniPlayerView(frame: .zero)
	// Visible flag
	private(set) var visible = false
	private(set) var fullyVisible = false
	// Player should stay hidden, regardless of playback status
	var stayHidden = false
	// Album cover
	private(set) var imageView: UIImageView!

	// MARK: - Private properties
	private var blurEffectView: UIVisualEffectView!
	// Queue's track list
	private var tableView: TracksListTableView!
	// Dummy acessible view for title
	private var accessibleView: UIView!
	// Track title
	private var lblTitle: AutoScrollLabel!
	// Track artist
	private var lblArtist: UILabel!
	// Play/pause button
	private var btnPlay: UIButton!
	// View to indicate track progression
	private var progressView: UIView!

	// MARK: - Initializers
	override init(frame f: CGRect)
	{
		let headerHeight: CGFloat
		let marginTop: CGFloat
		if #available(iOS 11, *)
		{
			if let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom
			{
				headerHeight = baseHeight + bottom
				marginTop = (UIApplication.shared.keyWindow?.safeAreaInsets.top)! < 20 ? 20 : (UIApplication.shared.keyWindow?.safeAreaInsets.top)!
			}
			else
			{
				headerHeight = baseHeight
				marginTop = 20.0
			}
		}
		else
		{
			headerHeight = baseHeight
			marginTop = 20.0
		}

		let frame = CGRect(0.0, (UIApplication.shared.keyWindow?.frame.height)! + headerHeight, (UIApplication.shared.keyWindow?.frame.width)!, (UIApplication.shared.keyWindow?.frame.height)! - marginTop - baseHeight)

		super.init(frame: frame)
		self.backgroundColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 0)

		// Top shadow
		self.layer.shadowPath = UIBezierPath(rect: CGRect(-2.0, 5.0, frame.width + 4.0, 4.0)).cgPath
		self.layer.shadowRadius = 3.0
		self.layer.shadowOpacity = 1.0
		self.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
		self.layer.masksToBounds = false
		self.isAccessibilityElement = false

		// Blur background
		let blurEffect = UIBlurEffect(style: .light)
		self.blurEffectView = UIVisualEffectView(effect: blurEffect)
		self.blurEffectView.frame = CGRect(.zero, frame.size.width, headerHeight)
		self.addSubview(self.blurEffectView)

		self.imageView = UIImageView(frame: CGRect(0.0, 0.0, headerHeight, headerHeight))
		self.imageView.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
		self.imageView.isUserInteractionEnabled = true
		self.blurEffectView.contentView.addSubview(self.imageView)

		// Vibrancy over the play/pause button
		let vibrancyEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
		vibrancyEffectView.frame = CGRect(frame.right - headerHeight, 0.0, headerHeight, headerHeight)
		self.blurEffectView.contentView.addSubview(vibrancyEffectView)

		// Play / pause button
		self.btnPlay = UIButton(type: .custom)
		self.btnPlay.frame = CGRect(6.0, 6.0, 32.0, 32.0)
		self.btnPlay.setImage(#imageLiteral(resourceName: "btn-play").withRenderingMode(.alwaysTemplate), for: .normal)
		self.btnPlay.addTarget(self, action: #selector(MiniPlayerView.changePlaybackAction(_:)), for: .touchUpInside)
		self.btnPlay.tag = PlayerStatus.stopped.rawValue
		self.btnPlay.isAccessibilityElement = true
		vibrancyEffectView.contentView.addSubview(self.btnPlay)

		// Dummy accessibility view
		self.accessibleView = UIView(frame: CGRect(self.imageView.right, 0.0, vibrancyEffectView.left - self.imageView.right, headerHeight))
		self.accessibleView.backgroundColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 0)
		self.accessibleView.isAccessibilityElement = true
		self.blurEffectView.contentView.addSubview(self.accessibleView)

		// Title
		self.lblTitle = AutoScrollLabel(frame: CGRect(self.imageView.right + 5.0, 2.0, ((vibrancyEffectView.left + 5.0) - (self.imageView.right + 5.0)), 18.0))
		self.lblTitle.textAlignment = .center
		self.lblTitle.font = UIFont(name: "GillSans-Bold", size: 14.0)
		self.lblTitle.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		self.lblTitle.isAccessibilityElement = false
		self.blurEffectView.contentView.addSubview(self.lblTitle)

		// Artist
		self.lblArtist = UILabel(frame: CGRect(self.imageView.right + 5.0, self.lblTitle.bottom + 2.0, self.lblTitle.width, 16.0))
		self.lblArtist.textAlignment = .center
		self.lblArtist.font = UIFont(name: "GillSans", size: 12.0)
		self.lblArtist.textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
		self.lblArtist.isAccessibilityElement = false
		self.blurEffectView.contentView.addSubview(self.lblArtist)

		// Progress
		self.progressView = UIView(frame: CGRect(0.0, 0.0, 0.0, 1.0))
		self.progressView.isAccessibilityElement = false
		self.addSubview(self.progressView)

		// Tableview
		self.tableView = TracksListTableView(frame: CGRect(0.0, headerHeight, frame.width, frame.height - headerHeight), style: .plain)
		self.tableView.delegate = self
		self.addSubview(self.tableView)

		// Single tap to request full player view
		let singleTap = UITapGestureRecognizer()
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		singleTap.addTarget(self, action: #selector(singleTap(_:)))
		if UIDevice.current.isiPhoneX()
		{
			self.imageView.addGestureRecognizer(singleTap)
		}
		else
		{
			self.addGestureRecognizer(singleTap)
		}

		let doubleTap = UITapGestureRecognizer()
		doubleTap.numberOfTapsRequired = 2
		doubleTap.numberOfTouchesRequired = 1
		doubleTap.addTarget(self, action: #selector(doubleTap(_:)))
		if UIDevice.current.isiPhoneX()
		{
			self.imageView.addGestureRecognizer(doubleTap)
		}
		else
		{
			self.addGestureRecognizer(doubleTap)
		}
		singleTap.require(toFail: doubleTap)

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackNotification(_:)), name: .currentPlayingTrack, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(playerStatusChangedNotification(_:)), name: .playerStatusChanged, object: nil)

		APP_DELEGATE().window?.addSubview(self)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Public
	func setInfoFromTrack(_ track: Track, ofAlbum album: Album)
	{
		lblTitle.text = track.name
		lblArtist.text = track.artist

		guard let url = album.localCoverURL else {return}
		if let image = UIImage.loadFromFileURL(url)
		{
			let x = KawaiiColors(image: image)
			x.analyze()
			progressView.backgroundColor = x.dominantColor
			imageView.image = image.scaled(toSize: CGSize(imageView.width * UIScreen.main.scale, imageView.height * UIScreen.main.scale))
		}
		else
		{
			let sizeAsData = Settings.shared.data(forKey: kNYXPrefCoversSize)!
			//let cropSize = NSKeyedUnarchiver.unarchiveObject(with: sizeAsData) as! NSValue
			let cropSize = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSValue.classForCoder()], from: sizeAsData) as? NSValue
			if album.path != nil
			{
				let op = CoverOperation(album: album, cropSize: (cropSize?.cgSizeValue)!)
				op.callback = {(cover: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						self.setInfoFromTrack(track, ofAlbum: album)
					}
				}
				OperationManager.shared.addOperation(op)
			}
			else
			{
				MusicDataSource.shared.getPathForAlbum(album) {
					let op = CoverOperation(album: album, cropSize: (cropSize?.cgSizeValue)!)
					op.callback = {(cover: UIImage, thumbnail: UIImage) in
						DispatchQueue.main.async {
							self.setInfoFromTrack(track, ofAlbum: album)
						}
					}
					OperationManager.shared.addOperation(op)
				}
			}
		}
	}

	func show(_ animated: Bool = true)
	{
		NotificationCenter.default.post(name: .miniPlayerViewWillShow, object: nil)
		let w = UIApplication.shared.keyWindow!
		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay: 0.0, options: UIView.AnimationOptions(), animations: {
			self.y = w.frame.height - self.blurEffectView.height
		}, completion: { finished in
			self.visible = true
			NotificationCenter.default.post(name: .miniPlayerViewDidShow, object: nil)
		})
	}

	func hide(_ animated: Bool = true)
	{
		NotificationCenter.default.post(name: .miniPlayerViewWillHide, object: nil)
		let w = UIApplication.shared.keyWindow!
		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay: 0.0, options: UIView.AnimationOptions(), animations: {
			self.y = w.frame.height + self.blurEffectView.height
		}, completion: { finished in
			self.visible = false
			NotificationCenter.default.post(name: .miniPlayerViewDidHide, object: nil)
		})
	}

	// MARK: - Buttons actions
	@objc func changePlaybackAction(_ sender: UIButton?)
	{
		if btnPlay.tag == PlayerStatus.playing.rawValue
		{
			btnPlay.setImage(#imageLiteral(resourceName: "btn-play").withRenderingMode(.alwaysTemplate), for: .normal)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			btnPlay.setImage(#imageLiteral(resourceName: "btn-pause").withRenderingMode(.alwaysTemplate), for: .normal)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}
		PlayerController.shared.togglePause()
	}

	// MARK: - Gestures
	@objc func singleTap(_ gesture: UITapGestureRecognizer)
	{
		if gesture.state == .ended
		{
			NotificationCenter.default.post(name: .miniPlayerShouldExpand, object: nil)
		}
	}

	@objc func doubleTap(_ gesture: UITapGestureRecognizer)
	{
		if fullyVisible == false
		{
			PlayerController.shared.getSongsOfCurrentQueue {
				DispatchQueue.main.async {
					self.tableView.tracks = PlayerController.shared.listTracksInQueue
				}
			}

			let w = UIApplication.shared.keyWindow!
			UIView.animate(withDuration: 0.35, delay: 0.0, options: UIView.AnimationOptions(), animations: {
				self.y = w.frame.height - self.height
			}, completion: { finished in
				self.fullyVisible = true
			})
		}
		else
		{
			let w = UIApplication.shared.keyWindow!
			UIView.animate(withDuration: 0.35, delay: 0.0, options: UIView.AnimationOptions(), animations: {
				self.y = w.frame.height - self.blurEffectView.height
			}, completion: { finished in
				self.fullyVisible = false
			})
		}
	}

	// MARK: - Notifications
	@objc func playingTrackNotification(_ aNotification: Notification)
	{
		if let infos = aNotification.userInfo
		{
			// Player not visible and should be
			if visible == false && stayHidden == false
			{
				show()
			}

			let track = infos[kPlayerTrackKey] as! Track
			let album = infos[kPlayerAlbumKey] as! Album
			let elapsed = infos[kPlayerElapsedKey] as! Int

			if track.name != lblTitle.text
			{
				setInfoFromTrack(track, ofAlbum: album)
			}

			let ratio = width / CGFloat(track.duration.seconds)
			UIView.animate(withDuration: 0.5) {
				self.progressView.width = ratio * CGFloat(elapsed)
			}
			accessibleView.accessibilityLabel = "\(track.name) \(NYXLocalizedString("lbl_by")) \(track.artist)\n\((100 * elapsed) / Int(track.duration.seconds))% \(NYXLocalizedString("lbl_played"))"
		}
	}

	@objc func playerStatusChangedNotification(_ aNotification: Notification)
	{
		if let infos = aNotification.userInfo
		{
			let state = infos[kPlayerStatusKey] as! Int
			if state == PlayerStatus.playing.rawValue
			{
				btnPlay.setImage(#imageLiteral(resourceName: "btn-pause").withRenderingMode(.alwaysTemplate), for: .normal)
				btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
			}
			else
			{
				btnPlay.setImage(#imageLiteral(resourceName: "btn-play").withRenderingMode(.alwaysTemplate), for: .normal)
				btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
			}
			btnPlay.tag = state
		}
	}
}

// MARK: - UITableViewDelegate
extension MiniPlayerView : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Toggle play / pause for the current track
		if let currentPlayingTrack = PlayerController.shared.currentTrack
		{
			let selectedTrack = self.tableView.tracks[indexPath.row]
			if selectedTrack == currentPlayingTrack
			{
				PlayerController.shared.togglePause()
				return
			}
		}

		PlayerController.shared.playTrackAtPosition(UInt32(indexPath.row))
	}
}
