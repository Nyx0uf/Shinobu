import UIKit


final class PlayerController
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = PlayerController()
	// MPD server
	var server: MPDServer! = nil
	// Player status (playing, paused, stopped)
	private(set) var currentStatus: PlayerStatus = .unknown
	// Current playing track
	private(set) var currentTrack: Track? = nil
	// Current playing album
	private(set) var currentAlbum: Album? = nil
	// Audio outputs list
	private(set) var outputs = [AudioOutput]()
	// List of the tracks of the current queue
	private(set) var listTracksInQueue = [Track]()
	// Albums list
	var albums = [Album]()

	// MARK: - Private properties
	// MPD Connection
	private var connection: MPDConnection! = nil
	// Internal queue
	private let queue: DispatchQueue
	// Timer (1sec)
	private var timer: DispatchSourceTimer!

	// MARK: - Initializers
	init()
	{
		self.queue = DispatchQueue(label: "fr.whine.shinobu.queue.player", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object:nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object:nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object:nil)
	}

	// MARK: - Public
	func initialize() -> Result<Bool, MPDConnectionError>
	{
		// Sanity check 1
		if MPDConnection.isValid(connection)
		{
			return .success(true)
		}

		// Sanity check 2
		guard let s = self.server else
		{
			return .failure(MPDConnectionError(.invalidServerParameters, Message(content: NYXLocalizedString("lbl_message_no_mpd_server"), type: .error)))
		}

		// Connect
		connection = MPDConnection(s)
		let ret = connection.connect()
		switch ret
		{
			case .failure(let error):
				connection = nil
				return .failure(MPDConnectionError(error.kind, error.message))
			case .success( _):
				connection.delegate = self
				startTimer(20)
				return .success(true)
		}
	}

	func deinitialize()
	{
		stopTimer()
		if connection != nil
		{
			connection.delegate = nil
			connection.disconnect()
			connection = nil
		}
	}

	func reinitialize() -> Result<Bool, MPDConnectionError>
	{
		deinitialize()
		return initialize()
	}

	// MARK: - Playing
	func playAlbum(_ album: Album, shuffle: Bool, loop: Bool)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.playAlbum(album, shuffle: shuffle, loop: loop)
		}
	}

	func playTracks(_ tracks: [Track], shuffle: Bool, loop: Bool)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.playTracks(tracks, shuffle: shuffle, loop: loop)
		}
	}

	func playPlaylist(_ playlist: Playlist, shuffle: Bool, loop: Bool, position: UInt32 = 0)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.playPlaylist(playlist, shuffle: shuffle, loop: loop, position: position)
		}
	}

	func playTrackAtPosition(_ position: UInt32)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.playTrackAtPosition(position)
		}
	}

	// MARK: - Pausing
	@objc func togglePause()
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.togglePause()
		}
	}

	// MARK: - Add to queue
	func addAlbumToQueue(_ album: Album)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.addAlbumToQueue(album)
		}
	}

	// MARK: - Repeat
	func setRepeat(_ loop: Bool)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.setRepeat(loop)
		}
	}

	// MARK: - Random
	func setRandom(_ random: Bool)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.setRandom(random)
		}
	}

	// MARK: - Tracks navigation
	@objc func requestNextTrack()
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.nextTrack()
		}
	}

	@objc func requestPreviousTrack()
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.previousTrack()
		}
	}

	func getSongsOfCurrentQueue(callback: @escaping () -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getSongsOfCurrentQueue()
			switch result
			{
				case .failure( _):
					break
				case .success(let tracks):
					strongSelf.listTracksInQueue = tracks
					callback()
			}
		}
	}

	// MARK: - Track position
	func setTrackPosition(_ position: Int, trackPosition: UInt32)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.setTrackPosition(position, trackPosition: trackPosition)
		}
	}

	// MARK: - Volume
	func setVolume(_ volume: Int, callback: @escaping (Bool) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.setVolume(UInt32(volume))
			switch result
			{
				case .failure( _):
					callback(false)
				case .success( _):
					callback(true)
			}
		}
	}

	func getVolume(callback: @escaping (Int) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getVolume()
			switch result
			{
				case .failure( _):
					break
				case .success(let volume):
					callback(volume)
			}
		}
	}

	// MARK: - Outputs
	func getAvailableOutputs(callback: @escaping () -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getAvailableOutputs()
			switch result
			{
				case .failure( _):
					break
				case .success(let outputs):
					strongSelf.outputs = outputs
					callback()
			}
		}
	}

	func toggleOutput(_ output: AudioOutput, callback: @escaping (Bool) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let ret = strongSelf.connection.toggleOutput(output)
			switch ret
			{
				case .failure( _):
					callback(false)
				case .success( _):
					callback(true)
			}
		}
	}

	// MARK: - Private
	private func startTimer(_ interval: Int)
	{
		timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: queue)
		timer.schedule(deadline: .now(), repeating: .milliseconds(interval))
		timer.setEventHandler { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.playerInformations()
		}
		timer.resume()
	}

	private func stopTimer()
	{
		if timer != nil
		{
			timer.cancel()
			timer = nil
		}
	}

	private func playerInformations()
	{
		guard MPDConnection.isValid(connection) else { return }

		do
		{
			let result = try connection.getPlayerInfos()
			switch result
			{
				case .failure(let error):
					Logger.shared.log(message: error.message)
				case .success(let result):
					guard let infos = result else {return}
					let status = infos[PLAYER_STATUS_KEY] as! Int
					let track = infos[PLAYER_TRACK_KEY] as! Track
					let album = infos[PLAYER_ALBUM_KEY] as! Album

					// Track changed
					if currentTrack == nil || (currentTrack != nil && track != currentTrack!)
					{
						NotificationCenter.default.postOnMainThreadAsync(name: .playingTrackChanged, object: nil, userInfo: infos)
					}

					// Status changed
					if currentStatus.rawValue != status
					{
						NotificationCenter.default.postOnMainThreadAsync(name: .playerStatusChanged, object: nil, userInfo: infos)
					}

					self.currentStatus = PlayerStatus(rawValue: status)!
					currentTrack = track
					currentAlbum = album
					NotificationCenter.default.postOnMainThreadAsync(name: .currentPlayingTrack, object: nil, userInfo: infos)
			}
		}
		catch let error
		{
			Logger.shared.log(error: error)
		}
	}

	// MARK: - Notifications
	@objc func audioServerConfigurationDidChange(_ aNotification: Notification)
	{
		if let server = aNotification.object as? MPDServer
		{
			self.server = server
			_ = self.reinitialize()
		}
	}

	@objc func applicationDidEnterBackground(_ aNotification: Notification)
	{
		deinitialize()
	}

	@objc func applicationWillEnterForeground(_ aNotification: Notification)
	{
		_ = reinitialize()
	}
}

extension PlayerController : MPDConnectionDelegate
{
	func albumMatchingName(_ name: String) -> Album?
	{
		return self.albums.filter({$0.name == name}).first
	}
}
