import UIKit


final class MusicDataSource
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = MusicDataSource()
	// MPD server
	var server: MPDServer! = nil
	// Selected display type
	private(set) var displayType = DisplayType.albums
	// Albums list
	private(set) var albums = [Album]()
	// Genres list
	private(set) var genres = [Genre]()
	// Artists list
	private(set) var artists = [Artist]()
	// Playlists list
	private(set) var playlists = [Playlist]()
	//
	private(set) var albumsartists = [Artist]()

	// MARK: - Private properties
	// MPD Connection
	private var _connection: AudioServerConnection! = nil
	// Serial queue for the connection
	private let _queue: DispatchQueue
	// Timer (1sec)
	private var _timer: DispatchSourceTimer!

	// MARK: - Initializers
	init()
	{
		self._queue = DispatchQueue(label: "fr.whine.mpdremote.queue.datasource", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target:  nil)

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object: nil)
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
			startTimer(20)
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

	func selectedList() -> [MusicalEntity]
	{
		switch displayType
		{
			case .albums:
				return albums
			case .artists:
				return artists
			case .albumsartists:
				return albumsartists
			case .genres:
				return genres
			case .playlists:
				return playlists
		}
	}

	func getListForDisplayType(_ displayType: DisplayType, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		self.displayType = displayType

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.getListForDisplayType(displayType)
			if result.succeeded == false
			{

			}
			else
			{
				let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
				switch (displayType)
				{
					case .albums:
						strongSelf.albums = (result.entity as! [Album]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
					case .artists:
						strongSelf.artists = (result.entity as! [Artist]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
					case .albumsartists:
						strongSelf.albumsartists = (result.entity as! [Artist]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
					case .genres:
						strongSelf.genres = (result.entity as! [Genre]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
					case .playlists:
						strongSelf.playlists = (result.entity as! [Playlist]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
				}

				callback()
			}
		}
	}

	func getAlbumsForGenre(_ genre: Genre, firstOnly: Bool, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.getAlbumsForGenre(genre, firstOnly: firstOnly)
			if result.succeeded == false
			{

			}
			else
			{
				genre.albums = result.entity!
				callback()
			}
		}
	}

	func getAlbumsForArtist(_ artist: Artist, isAlbumArtist: Bool = false, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.getAlbumsForArtist(artist, isAlbumArtist: isAlbumArtist)
			if result.succeeded == false
			{

			}
			else
			{
				let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
				artist.albums = result.entity!.sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
				callback()
			}
		}
	}

	func getArtistsForGenre(_ genre: Genre, callback: @escaping ([Artist]) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.getArtistsForGenre(genre)
			if result.succeeded == false
			{

			}
			else
			{
				let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
				callback(result.entity!.sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)}))
			}
		}
	}

	func getPathForAlbum(_ album: Album, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.getPathForAlbum(album)
			if result.succeeded == false
			{

			}
			else
			{
				album.path = result.entity
				callback()
			}
		}
	}

	func getTracksForAlbums(_ albums: [Album], callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			for album in albums
			{
				let result = strongSelf._connection.getTracksForAlbum(album)
				album.tracks = result.entity
				callback()
			}
		}
	}

	func getTracksForPlaylist(_ playlist: Playlist, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.getTracksForPlaylist(playlist)
			if result.succeeded == false
			{

			}
			else
			{
				playlist.tracks = result.entity
				callback()
			}
		}
	}

	func getMetadatasForAlbum(_ album: Album, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			do
			{
				let result = try strongSelf._connection.getMetadatasForAlbum(album)
				if result.succeeded == false
				{
				}
				else
				{
					let metadatas = result.entity!
					if let artist = metadatas["artist"] as! String?
					{
						album.artist = artist
					}
					if let year = metadatas["year"] as! String?
					{
						album.year = year
					}
					if let genre = metadatas["genre"] as! String?
					{
						album.genre = genre
					}

					callback()
				}
			}
			catch
			{
				DispatchQueue.main.async {
					_ = strongSelf.reinitialize()
				}
			}
		}
	}

	func getStats(_ callback: @escaping ([String : String]) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.getStats()
			if result.succeeded == false
			{

			}
			else
			{
				callback(result.entity!)
			}
		}
	}

	func updateDatabase(_ callback: @escaping (Bool) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.updateDatabase()
			callback(result.succeeded)
		}
	}

	func createPlaylist(name: String, _ callback: @escaping (ActionResult<Void>) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.createPlaylist(name: name)
			if result.succeeded == false
			{
				DispatchQueue.main.async {
					_ = strongSelf.reinitialize()
				}
			}
			callback(result)
		}
	}

	func deletePlaylist(name: String, _ callback: @escaping (ActionResult<Void>) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.deletePlaylist(name: name)
			callback(result)
		}
	}

	func renamePlaylist(playlist: Playlist, newName: String, _ callback: @escaping (ActionResult<Void>) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.renamePlaylist(playlist: playlist, newName: newName)
			callback(result)
		}
	}

	func addTrackToPlaylist(playlist: Playlist, track: Track, _ callback: @escaping (ActionResult<Void>) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.addTrackToPlaylist(playlist: playlist, track: track)
			callback(result)
		}
	}

	func removeTrackFromPlaylist(playlist: Playlist, track: Track, _ callback: @escaping (ActionResult<Void>) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf._connection.removeTrackFromPlaylist(playlist: playlist, track: track)
			callback(result)
		}
	}

	// MARK: - Private
	private func startTimer(_ interval: Int)
	{
		_timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: _queue)
		_timer.schedule(deadline: .now(), repeating: .seconds(interval))
		_timer.setEventHandler { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.getPlayerStatus()
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

	private func getPlayerStatus()
	{
		_ = _connection.getStatus()
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

extension MusicDataSource : AudioServerConnectionDelegate
{
	func albumMatchingName(_ name: String) -> Album?
	{
		let albums = MusicDataSource.shared.albums
		return albums.filter({$0.name == name}).first
	}
}
