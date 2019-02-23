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

	// MARK: - Private properties
	// MPD Connection
	private var _connection: AudioServerConnection! = nil
	// Internal queue
	private let _queue: DispatchQueue
	// Timer (1sec)
	private var _timer: DispatchSourceTimer!

	// MARK: - Initializers
	init()
	{
		self._queue = DispatchQueue(label: "fr.whine.mpdremote.queue.player", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object:nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object:nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object:nil)
	}

	// MARK: - Public
	func initialize() -> ActionResult<Void>
	{
		// Sanity check 1
		if _connection != nil && _connection.isConnected
		{
			return ActionResult(succeeded: true)
		}

		// Sanity check 2
		guard let server = server else
		{
			return ActionResult(succeeded: false, message: Message(content: NYXLocalizedString("lbl_message_no_mpd_server"), type: .error))
		}

		// Connect
		_connection = MPDConnection(server)
		let ret = _connection.connect()
		if ret.succeeded
		{
			_connection.delegate = self
			startTimer(500)
		}
		else
		{
			_connection = nil
			return ActionResult(succeeded: false, message: ret.messages.first!)
		}
		return ActionResult(succeeded: true)
	}

	func deinitialize()
	{
		stopTimer()
		if _connection != nil
		{
			_connection.delegate = nil
			_connection.disconnect()
			_connection = nil
		}
	}

	func reinitialize() -> ActionResult<Void>
	{
		deinitialize()
		return initialize()
	}

	// MARK: - Playing
	func playAlbum(_ album: Album, shuffle: Bool, loop: Bool)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf._connection.playAlbum(album, shuffle: shuffle, loop: loop)
		}
	}

	func playTracks(_ tracks: [Track], shuffle: Bool, loop: Bool)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf._connection.playTracks(tracks, shuffle: shuffle, loop: loop)
		}
	}

	func playPlaylist(_ playlist: Playlist, shuffle: Bool, loop: Bool, position: UInt32 = 0)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf._connection.playPlaylist(playlist, shuffle: shuffle, loop: loop, position: position)
		}
	}

	func playTrackAtPosition(_ position: UInt32)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf._connection.playTrackAtPosition(position)
		}
	}

	// MARK: - Pausing
	@objc func togglePause()
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf._connection.togglePause()
		}
	}

	// MARK: - Add to queue
	func addAlbumToQueue(_ album: Album)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf._connection.addAlbumToQueue(album)
		}
	}

	// MARK: - Repeat
	func setRepeat(_ loop: Bool)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf._connection.setRepeat(loop)
		}
	}

	// MARK: - Random
	func setRandom(_ random: Bool)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf._connection.setRandom(random)
		}
	}

	// MARK: - Tracks navigation
	@objc func requestNextTrack()
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf._connection.nextTrack()
		}
	}

	@objc func requestPreviousTrack()
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf._connection.previousTrack()
		}
	}

	func getSongsOfCurrentQueue(callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.getSongsOfCurrentQueue()
			if result.succeeded == false
			{

			}
			else
			{
				strongSelf.listTracksInQueue = result.entity!
				callback()
			}
		}
	}

	// MARK: - Track position
	func setTrackPosition(_ position: Int, trackPosition: UInt32)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf._connection.setTrackPosition(position, trackPosition: trackPosition)
		}
	}

	// MARK: - Volume
	func setVolume(_ volume: Int, callback: @escaping (Bool) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.setVolume(UInt32(volume))
			callback(result.succeeded)
		}
	}

	func getVolume(callback: @escaping (Int) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.getVolume()
			if result.succeeded == false
			{

			}
			else
			{
				callback(result.entity!)
			}
		}
	}

	// MARK: - Outputs
	func getAvailableOutputs(callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.getAvailableOutputs()
			if result.succeeded == false
			{

			}
			else
			{
				strongSelf.outputs = result.entity!
				callback()
			}
		}
	}

	func toggleOutput(output: AudioOutput, callback: @escaping (Bool) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let ret = strongSelf._connection.toggleOutput(output: output)
			callback(ret.succeeded)
		}
	}

	func getTrackInformation(_ track: Track, callback: @escaping ([String : String]) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let ret = strongSelf._connection.getAudioFormat()
			if ret.succeeded
			{
				callback(ret.entity!)
			}
		}
	}

	// MARK: - Private
	private func startTimer(_ interval: Int)
	{
		_timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: _queue)
		_timer.schedule(deadline: .now(), repeating: .milliseconds(interval))
		_timer.setEventHandler { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.playerInformations()
		}
		_timer.resume()
	}

	private func stopTimer()
	{
		if _timer != nil
		{
			_timer.cancel()
			_timer = nil
		}
	}

	private func playerInformations()
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		do
		{
			let result = try _connection.getPlayerInfos()
			if result.succeeded == false
			{
				return
			}
			guard let infos = result.entity else {return}
			let status = infos[kPlayerStatusKey] as! Int
			let track = infos[kPlayerTrackKey] as! Track
			let album = infos[kPlayerAlbumKey] as! Album

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
		catch
		{
			
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

extension PlayerController : AudioServerConnectionDelegate
{
	func albumMatchingName(_ name: String) -> Album?
	{
		let albums = MusicDataSource.shared.albums
		return albums.filter({$0.name == name}).first
	}
}
