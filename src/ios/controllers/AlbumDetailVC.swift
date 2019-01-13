// AlbumDetailVC.swift
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


final class AlbumDetailVC : UIViewController
{
	// MARK: - Public properties
	// Selected album
	var album: Album

	// MARK: - Private properties
	// Header view (cover + album name, artist)
	@IBOutlet private var headerView: AlbumHeaderView! = nil
	// Header height constraint
	@IBOutlet private var headerHeightConstraint: NSLayoutConstraint! = nil
	// Dummy view for shadow
	@IBOutlet private var dummyView: UIView! = nil
	// Tableview for song list
	@IBOutlet private var tableView: TracksListTableView! = nil
	// Dummy view to color the nav bar
	@IBOutlet private var colorView: UIView! = nil
	// Label in the navigationbar
	private var titleView: UILabel! = nil
	// Random button
	private var btnRandom: UIBarButtonItem! = nil
	// Repeat button
	private var btnRepeat: UIBarButtonItem! = nil

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		// Dummy
		self.album = Album(name: "")

		super.init(coder: aDecoder)
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Navigation bar title
		titleView = UILabel(frame: CGRect(.zero, 100.0, 44.0))
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
		navigationItem.titleView = titleView

		// Album header view
		let coverSize = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSValue.classForCoder()], from: Settings.shared.data(forKey: kNYXPrefCoversSize)!) as? NSValue
		//let coverSize = NSKeyedUnarchiver.unarchiveObject(with: Settings.shared.data(forKey: kNYXPrefCoversSize)!) as! NSValue
		headerView.coverSize = (coverSize?.cgSizeValue)!
		headerHeightConstraint.constant = (coverSize?.cgSizeValue)!.height

		// Dummy tableview host, to create a nice shadow effect
		dummyView.layer.shadowPath = UIBezierPath(rect: CGRect(-2.0, 5.0, view.width + 4.0, 4.0)).cgPath
		dummyView.layer.shadowRadius = 3.0
		dummyView.layer.shadowOpacity = 1.0
		dummyView.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
		dummyView.layer.masksToBounds = false

		// Tableview
		tableView.useDummy = true
		tableView.tableFooterView = UIView()
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Add navbar shadow
		if let navigationBar = navigationController?.navigationBar
		{
			navigationBar.layer.shadowPath = UIBezierPath(rect: CGRect(-2.0, navigationBar.frame.height - 2.0, navigationBar.frame.width + 4.0, 4.0)).cgPath
			navigationBar.layer.shadowRadius = 3.0
			navigationBar.layer.shadowOpacity = 1.0
			navigationBar.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
			navigationBar.layer.masksToBounds = false

			let loop = Settings.shared.bool(forKey: kNYXPrefMPDRepeat)
			btnRepeat = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-repeat").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(toggleRepeatAction(_:)))
			btnRepeat.tintColor = loop ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
			btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

			let rand = Settings.shared.bool(forKey: kNYXPrefMPDShuffle)
			btnRandom = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-random").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(toggleRandomAction(_:)))
			btnRandom.tintColor = rand ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
			btnRandom.accessibilityLabel = NYXLocalizedString(rand ? "lbl_random_disable" : "lbl_random_enable")

			navigationItem.rightBarButtonItems = [btnRandom, btnRepeat]
		}

		// Update header
		updateHeader()

		// Get songs list if needed
		if let tracks = album.tracks
		{
			updateNavigationTitle()
			tableView.tracks = tracks
		}
		else
		{
			MusicDataSource.shared.getTracksForAlbums([album]) {
				DispatchQueue.main.async {
					self.updateNavigationTitle()
					self.tableView.tracks = self.album.tracks!
				}
			}
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		// Remove navbar shadow
		if let navigationBar = navigationController?.navigationBar
		{
			navigationBar.layer.shadowPath = nil
			navigationBar.layer.shadowRadius = 0.0
			navigationBar.layer.shadowOpacity = 0.0
		}
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .default
	}

	// MARK: - Private
	private func updateHeader()
	{
		// Update header view
		headerView.updateHeaderWithAlbum(album)
		colorView.backgroundColor = headerView.backgroundColor

		// Don't have all the metadatas
		if album.artist.count == 0
		{
			MusicDataSource.shared.getMetadatasForAlbum(album) {
				DispatchQueue.main.async {
					self.updateHeader()
				}
			}
		}
	}

	private func updateNavigationTitle()
	{
		if let tracks = album.tracks
		{
			let total = tracks.reduce(Duration(seconds: 0)){$0 + $1.duration}
			let minutes = total.seconds / 60
			let attrs = NSMutableAttributedString(string: "\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))\n", attributes:[NSAttributedString.Key.font : UIFont(name: "HelveticaNeue-Medium", size: 14.0)!])
			attrs.append(NSAttributedString(string: "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))", attributes: [NSAttributedString.Key.font : UIFont(name: "HelveticaNeue", size: 13.0)!]))
			titleView.attributedText = attrs
		}
	}

	// MARK: - Buttons actions
	@objc func toggleRandomAction(_ sender: Any?)
	{
		let random = !Settings.shared.bool(forKey: kNYXPrefMPDShuffle)

		btnRandom.tintColor = random ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		Settings.shared.set(random, forKey: kNYXPrefMPDShuffle)
		Settings.shared.synchronize()

		PlayerController.shared.setRandom(random)
	}

	@objc func toggleRepeatAction(_ sender: Any?)
	{
		let loop = !Settings.shared.bool(forKey: kNYXPrefMPDRepeat)

		btnRepeat.tintColor = loop ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		Settings.shared.set(loop, forKey: kNYXPrefMPDRepeat)
		Settings.shared.synchronize()

		PlayerController.shared.setRepeat(loop)
	}
}

// MARK: - UITableViewDelegate
extension AlbumDetailVC : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Dummy cell
		guard let tracks = album.tracks else { return }
		if indexPath.row >= tracks.count
		{
			return
		}

		// Toggle play / pause for the current track
		if let currentPlayingTrack = PlayerController.shared.currentTrack
		{
			let selectedTrack = tracks[indexPath.row]
			if selectedTrack == currentPlayingTrack
			{
				PlayerController.shared.togglePause()
				return
			}
		}

		let b = tracks.filter({$0.trackNumber >= (indexPath.row + 1)})
		PlayerController.shared.playTracks(b, shuffle: Settings.shared.bool(forKey: kNYXPrefMPDShuffle), loop: Settings.shared.bool(forKey: kNYXPrefMPDRepeat))
	}

	@available(iOS 11.0, *)
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
	{
		// Dummy cell
		guard let tracks = album.tracks else { return nil }
		if indexPath.row >= tracks.count
		{
			return nil
		}

		let action = UIContextualAction(style: .normal, title: NYXLocalizedString("lbl_add_to_playlist"), handler: { (action, view, completionHandler ) in
			MusicDataSource.shared.getListForDisplayType(.playlists) {
				if MusicDataSource.shared.playlists.count == 0
				{
					return
				}

				DispatchQueue.main.async {
					guard let cell = tableView.cellForRow(at: indexPath) else
					{
						return
					}

					let vc = PlaylistsTVC()
					let tvc = NYXNavigationController(rootViewController: vc)
					vc.trackToAdd = tracks[indexPath.row]
					tvc.modalPresentationStyle = .popover
					if let popController = tvc.popoverPresentationController
					{
						popController.permittedArrowDirections = [.up, .down]
						popController.sourceRect = cell.bounds
						popController.sourceView = cell
						popController.delegate = self
						tvc.preferredContentSize = CGSize(300, 200)
						self.present(tvc, animated: true, completion: {
						});
					}
				}
			}
			completionHandler(true)
		})
		action.image = #imageLiteral(resourceName: "btn-playlist-add")
		action.backgroundColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)

		return UISwipeActionsConfiguration(actions: [action])
	}
}

extension AlbumDetailVC : UIPopoverPresentationControllerDelegate
{
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
	{
		return .none
	}
}

// MARK: - Peek & Pop
extension AlbumDetailVC
{
	override var previewActionItems: [UIPreviewActionItem]
	{
		let playAction = UIPreviewAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action, viewController) in
			PlayerController.shared.playAlbum(self.album, shuffle: false, loop: false)
			MiniPlayerView.shared.stayHidden = false
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action, viewController) in
			PlayerController.shared.playAlbum(self.album, shuffle: true, loop: false)
			MiniPlayerView.shared.stayHidden = false
		}

		let addQueueAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action, viewController) in
			PlayerController.shared.addAlbumToQueue(self.album)
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, addQueueAction]
	}
}
