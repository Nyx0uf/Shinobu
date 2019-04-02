import UIKit


final class MPDDataSource
{
	// MARK: - Public properties
	// MPD server
	var server: MPDServer! = nil
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
	private var connection: MPDConnection! = nil
	// Serial queue for the connection
	private let queue: DispatchQueue
	// Timer (1sec)
	private var timer: DispatchSourceTimer!

	// MARK: - Initializers
	init()
	{
		self.queue = DispatchQueue(label: "fr.whine.shinobu.queue.datasource", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target:  nil)

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object: nil)
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
		guard let server = server else
		{
			return .failure(MPDConnectionError(.invalidServerParameters, Message(content: NYXLocalizedString("lbl_message_no_mpd_server"), type: .error)))
		}

		// Connect
		connection = MPDConnection(server)
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

	func listForMusicalEntityType(_ type: MusicalEntityType) -> [MusicalEntity]
	{
		switch type
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
			default:
				return albums
		}
	}

	func getListForMusicalEntityType(_ type: MusicalEntityType, callback: @escaping () -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getListForMusicalEntityType(type)
			switch result
			{
				case .failure( _):
					break
				case .success(let list):
					let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
					switch type
					{
						case .albums:
							strongSelf.albums = (list as! [Album]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
						case .artists:
							strongSelf.artists = (list as! [Artist]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
						case .albumsartists:
							strongSelf.albumsartists = (list as! [Artist]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
						case .genres:
							strongSelf.genres = (list as! [Genre]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
						case .playlists:
							strongSelf.playlists = (list as! [Playlist]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
						default:
							raise(0)
					}
					callback()
			}
		}
	}

	func getAlbumsForGenre(_ genre: Genre, firstOnly: Bool, callback: @escaping ([Album]) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getAlbumsForGenre(genre, firstOnly: firstOnly)
			switch result
			{
				case .failure( _):
					break
				case .success(let list):
					genre.albums = list
					callback(list)
			}
		}
	}

	func getAlbumsForArtist(_ artist: Artist, isAlbumArtist: Bool = false, callback: @escaping ([Album]) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getAlbumsForArtist(artist, isAlbumArtist: isAlbumArtist)
			switch result
			{
				case .failure( _):
					break
				case .success(let list):
					let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
					let albums = list.sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
					artist.albums = albums
					callback(albums)
			}
		}
	}

	func getArtistsForGenre(_ genre: Genre, isAlbumArtist: Bool, callback: @escaping ([Artist]) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getArtistsForGenre(genre, isAlbumArtist: isAlbumArtist)
			switch result
			{
				case .failure( _):
					break
				case .success(let list):
					let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
					callback(list.sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)}))
			}
		}
	}

	func getPathForAlbum(_ album: Album, callback: @escaping () -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getPathForAlbum(album)
			switch result
			{
				case .failure( _):
					break
				case .success(let path):
					album.path = path
					callback()
			}
		}
	}

	func getTracksForAlbums(_ albums: [Album], callback: @escaping () -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			for album in albums
			{
				let result = strongSelf.connection.getTracksForAlbum(album)
				switch result
				{
					case .failure( _):
						album.tracks = nil
					case .success(let tracks):
						album.tracks = tracks
				}
				callback()
			}
		}
	}

	func getTracksForPlaylist(_ playlist: Playlist, callback: @escaping () -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getTracksForPlaylist(playlist)
			switch result
			{
				case .failure( _):
					break
				case .success(let tracks):
					playlist.tracks = tracks
					callback()
			}
		}
	}

	func getMetadatasForAlbum(_ album: Album, callback: @escaping () -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			do
			{
				let result = try strongSelf.connection.getMetadatasForAlbum(album)
				switch result
				{
					case .failure( _):
						break
					case .success(let metadatas):
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

	func updateDatabase(_ callback: @escaping (Bool) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.updateDatabase()
			switch result
			{
				case .failure( _):
					callback(false)
				case .success( _):
					callback(true)
			}
		}
	}

	func createPlaylist(named name: String, _ callback: @escaping (Result<Bool, MPDConnectionError>) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.createPlaylist(named: name)
			switch result
			{
				case .failure( _):
					DispatchQueue.main.async {
						_ = strongSelf.reinitialize()
					}
				case .success( _):
					break
			}
			callback(result)
		}
	}

	func deletePlaylist(named name: String, _ callback: @escaping (Result<Bool, MPDConnectionError>) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.deletePlaylist(named: name)
			callback(result)
		}
	}

	func rename(playlist: Playlist, withNewName newName: String, _ callback: @escaping (Result<Bool, MPDConnectionError>) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.renamePlaylist(playlist, withNewName: newName)
			callback(result)
		}
	}

	func addTrack(to playlist: Playlist, track: Track, _ callback: @escaping (Result<Bool, MPDConnectionError>) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.addTrack(track, toPlaylist: playlist)
			callback(result)
		}
	}

	func removeTrack(from playlist: Playlist, track: Track, _ callback: @escaping (Result<Bool, MPDConnectionError>) -> Void)
	{
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.removeTrack(track, fromPlaylist: playlist)
			callback(result)
		}
	}

	// MARK: - Private
	private func startTimer(_ interval: Int)
	{
		timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: queue)
		timer.schedule(deadline: .now(), repeating: .seconds(interval))
		timer.setEventHandler { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.getPlayerStatus()
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

	private func getPlayerStatus()
	{
		_ = connection.getStatus()
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

extension MPDDataSource : MPDConnectionDelegate
{
	func albumMatchingName(_ name: String) -> Album?
	{
		return self.albums.filter({$0.name == name}).first
	}
}
