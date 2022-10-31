import UIKit
import Logging
import SwiftyMPDClient

final class MPDBridge {
	// MARK: - Public properties
	// MPD server
	var server: MPDServer! = nil
	// Browse by dir, not albums
	var isDirectoryBased = false

	// MARK: - Private properties
	// MPD Connection
	private var connection: MPDConnection! = nil
	// Serial queue for the connection
	private let queue: DispatchQueue
	// Timer (1sec)
	private var timer: DispatchSourceTimer!
	// Albums list
	private var _albums: [Album]?
	// Artists list
	private var _artists: [Artist]?
	// Albums's artists
	private var _albumsartists: [Artist]?
	// Genres list
	private var _genres: [Genre]?
	// Current playing track
	private var currentTrack: Track?
	// Current playing album
	private var currentAlbum: Album?
	// Player status (playing, paused, stopped)
	private var currentState = PlayerState(status: .unknown, isRandom: false, isRepeat: false)
	// Logger
	private let logger = Logger(label: "logger.mpdbridge")

	// MARK: - Initializers
	init(isDirectoryBased: Bool) {
		self.isDirectoryBased = isDirectoryBased
		self.queue = DispatchQueue(label: "fr.whine.shinobu.queue.mpdbridge", qos: .utility, attributes: [], autoreleaseFrequency: .inherit, target: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
	}

	// MARK: - Public
	func initialize() -> Result<Bool, MPDConnectionError> {
		// Sanity check 1
		if MPDConnection.isValid(connection) {
			return .success(true)
		}

		// Sanity check 2
		guard let server = server else {
			return .failure(MPDConnectionError(.invalidServerParameters, Message(content: NYXLocalizedString("lbl_message_no_mpd_server"), type: .error)))
		}

		// Connect
		connection = MPDConnection(server)
		let ret = connection.connect()
		switch ret {
		case .failure(let error):
			connection = nil
			return .failure(error)
		case .success:
			connection.delegate = self
			startTimer(200)
			return .success(true)
		}
	}

	func deinitialize() {
		stopTimer()
		if connection != nil {
			connection.delegate = nil
			connection.disconnect()
			connection = nil
		}
	}

	func reinitialize() -> Result<Bool, MPDConnectionError> {
		deinitialize()
		return initialize()
	}

	func getCurrentTrack() -> Track? {
		queue.sync { self.currentTrack }
	}

	func getCurrentAlbum() -> Album? {
		queue.sync { self.currentAlbum }
	}

	func getCurrentState() -> PlayerState {
		queue.sync { self.currentState }
	}

	func getAllEntities(callback: @escaping () -> Void) {
		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.getListForMusicalEntityType(.albums) { _ in
				strongSelf.getListForMusicalEntityType(.artists) { _ in
					strongSelf.getListForMusicalEntityType(.albumsartists) { _ in
						strongSelf.getListForMusicalEntityType(.genres) { _ in
							callback()
						}
					}
				}
			}
		}
	}

	func entitiesForType(_ type: MusicalEntityType, callback: @escaping ([MusicalEntity]) -> Void) {
		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			var entities: [MusicalEntity]?
			switch type {
			case .albums:
				entities = strongSelf._albums
			case .artists:
				entities = strongSelf._artists
			case .albumsartists:
				entities = strongSelf._albumsartists
			case .genres:
				entities = strongSelf._genres
			case .playlists:
				break // Playlists can be modified from the app, need to be dynamic
			default:
				return
			}

			if let entities = entities {
				callback(entities)
			} else {
				strongSelf.getListForMusicalEntityType(type) { (entities) in
					callback(entities)
				}
			}
		}
	}

	func getAlbumsForGenre(_ genre: Genre, firstOnly: Bool, callback: @escaping ([Album]) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getAlbumsForGenre(genre, firstOnly: firstOnly)
			switch result {
			case .failure:
				break
			case .success(let list):
				genre.albums = list
				callback(list)
			}
		}
	}

	func getAlbumsForArtist(_ artist: Artist, isAlbumArtist: Bool = false, callback: @escaping ([Album]) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getAlbumsForArtist(artist, isAlbumArtist: isAlbumArtist)
			switch result {
			case .failure:
				break
			case .success(let list):
				let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
				let albums = list.sorted(by: { $0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set) })
				artist.albums = albums
				callback(albums)
			}
		}
	}

	func getArtistsForGenre(_ genre: Genre, isAlbumArtist: Bool, callback: @escaping ([Artist]) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getArtistsForGenre(genre, isAlbumArtist: isAlbumArtist)
			switch result {
			case .failure:
				break
			case .success(let list):
				let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
				callback(list.sorted(by: { $0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set) }))
			}
		}
	}

	func getPathForAlbum(_ album: Album, callback: @escaping () -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getPathForAlbum(album)
			switch result {
			case .failure:
				break
			case .success(let path):
				album.path = path
				callback()
			}
		}
	}

	func getPathForAlbum2(_ album: Album, callback: @escaping (Bool, String?) -> Void) -> DispatchWorkItem? {
		var dwi: DispatchWorkItem?

		guard MPDConnection.isValid(connection) else { return dwi }

		dwi = DispatchWorkItem { [weak self] in
			guard let strongSelf = self else {
				callback(false, nil)
				return
			}

			if dwi!.isCancelled {
				strongSelf.logger.info("cancelling work item for <\(album)>")
				callback(false, nil)
				return
			}

			if mpd_search_db_songs(strongSelf.connection.connection, true) == false {
				callback(false, nil)
				return
			}

			if dwi!.isCancelled {
				strongSelf.logger.info("cancelling work item for [mpd_search_db_songs] <\(album)>")
				mpd_search_cancel(strongSelf.connection.connection)
				callback(false, nil)
				return
			}

			if mpd_search_add_tag_constraint(strongSelf.connection.connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false {
				callback(false, nil)
				return
			}

			if dwi!.isCancelled {
				strongSelf.logger.info("cancelling work item for [mpd_search_add_tag_constraint] <\(album)>")
				mpd_search_cancel(strongSelf.connection.connection)
				callback(false, nil)
				return
			}

			if mpd_search_commit(strongSelf.connection.connection) == false {
				callback(false, nil)
				return
			}

			if dwi!.isCancelled {
				strongSelf.logger.info("cancelling work item for [mpd_search_commit] <\(album)>")
				mpd_response_finish(strongSelf.connection.connection)
				callback(false, nil)
				return
			}

			var path: String?
			var songUri: String?
			if let song = mpd_recv_song(strongSelf.connection.connection) {
				if let uri = mpd_song_get_uri(song) {
					let name = String(cString: uri)
					songUri = name
					path = URL(fileURLWithPath: name).deletingLastPathComponent().path
				}
			}

			if mpd_connection_get_error(strongSelf.connection.connection) != MPD_ERROR_SUCCESS || mpd_response_finish(strongSelf.connection.connection) == false {
				callback(false, nil)
				return
			}

			album.path = path
			album.randomSongPath = songUri
			callback(path != nil, path)
		}

		queue.async(execute: dwi!)

		return dwi
	}

	func getTracksForAlbums(_ albums: [Album], callback: @escaping ([Track]?) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			for album in albums {
				let result = strongSelf.connection.getTracksForAlbum(album)
				switch result {
				case .failure:
					album.tracks = nil
					callback(nil)
				case .success(let tracks):
					album.tracks = tracks
					callback(tracks)
				}
			}
		}
	}

	func getTracksForPlaylist(_ playlist: Playlist, callback: @escaping ([Track]?) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getTracksForPlaylist(playlist)
			switch result {
			case .failure:
				callback(nil)
			case .success(let tracks):
				playlist.tracks = tracks
				callback(tracks)
			}
		}
	}

	func getMetadatasForAlbum(_ album: Album, callback: @escaping () -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			do {
				let result = try strongSelf.connection.getMetadatasForAlbum(album)
				switch result {
				case .failure:
					break
				case .success(let metadatas):
					if let artist = metadatas["artist"] as! String? {
						album.artist = artist
					}
					if let year = metadatas["year"] as! String? {
						album.year = year
					}
					if let genre = metadatas["genre"] as! String? {
						album.genre = genre
					}

					callback()
				}
			} catch {
				DispatchQueue.main.async {
					_ = strongSelf.reinitialize()
				}
			}
		}
	}

	func updateDatabase(_ callback: @escaping (Bool) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.updateDatabase()
			switch result {
			case .failure:
				callback(false)
			case .success:
				callback(true)
			}
		}
	}

	func createPlaylist(named name: String, _ callback: @escaping (Result<Bool, MPDConnectionError>) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.createPlaylist(named: name)
			switch result {
			case .failure:
				DispatchQueue.main.async {
					_ = strongSelf.reinitialize()
				}
			case .success:
				break
			}
			callback(result)
		}
	}

	func deletePlaylist(named name: String, _ callback: @escaping (Result<Bool, MPDConnectionError>) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.deletePlaylist(named: name)
			callback(result)
		}
	}

	func rename(playlist: Playlist, withNewName newName: String, _ callback: @escaping (Result<Bool, MPDConnectionError>) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.renamePlaylist(playlist, withNewName: newName)
			callback(result)
		}
	}

	func addTrack(to playlist: Playlist, track: Track, _ callback: @escaping (Result<Bool, MPDConnectionError>) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.addTrack(track, toPlaylist: playlist)
			callback(result)
		}
	}

	func removeTrack(from playlist: Playlist, track: Track, _ callback: @escaping (Result<Bool, MPDConnectionError>) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.removeTrack(track, fromPlaylist: playlist)
			callback(result)
		}
	}

	// MARK: - Playing
	func playAlbum(_ album: Album, shuffle: Bool, loop: Bool) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.playAlbum(album, shuffle: shuffle, loop: loop)
		}
	}

	func playTracks(_ tracks: [Track], shuffle: Bool, loop: Bool) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.playTracks(tracks, shuffle: shuffle, loop: loop)
		}
	}

	func playPlaylist(_ playlist: Playlist, shuffle: Bool, loop: Bool, position: UInt32 = 0) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.playPlaylist(playlist, shuffle: shuffle, loop: loop, position: position)
		}
	}

	func playTrackAtPosition(_ position: UInt32) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.playTrackAtPosition(position)
		}
	}

	func play() {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.play()
		}
	}

	// MARK: - Pausing
	@objc func togglePause() {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.togglePause()
		}
	}

	@objc func stop() {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.stop()
		}
	}

	// MARK: - Add to queue
	func addAlbumToQueue(_ album: Album) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.addAlbumToQueue(album)
		}
	}

	// MARK: - Repeat
	func setRepeat(_ loop: Bool) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.setRepeat(loop)
		}
	}

	func toggleRepeat() {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.setRepeat(!strongSelf.currentState.isRepeat)
		}
	}

	// MARK: - Random
	func setRandom(_ random: Bool) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.setRandom(random)
		}
	}

	func toggleRandom() {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.setRandom(!strongSelf.currentState.isRandom)
		}
	}

	// MARK: - Tracks navigation
	@objc func requestNextTrack() {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.nextTrack()
		}
	}

	@objc func requestPreviousTrack() {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.previousTrack()
		}
	}

	func getSongsOfCurrentQueue(callback: @escaping ([Track]) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getSongsOfCurrentQueue()
			switch result {
			case .failure:
				break
			case .success(let tracks):
				callback(tracks)
			}
		}
	}

	// MARK: - Track position
	func setTrackPosition(_ position: Int, trackPosition: UInt32) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			_ = strongSelf.connection.setTrackPosition(position, trackPosition: trackPosition)
		}
	}

	// MARK: - Volume
	func setVolume(_ volume: Int, callback: @escaping (Bool) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.setVolume(UInt32(volume))
			switch result {
			case .failure:
				callback(false)
			case .success:
				callback(true)
			}
		}
	}

	func getVolume(callback: @escaping (Int) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getVolume()
			switch result {
			case .failure:
				break
			case .success(let volume):
				callback(volume)
			}
		}
	}

	// MARK: - Directories
	func getDirectoryListAtPath(_ path: String?, callback: @escaping ([MPDEntity]) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getDirectoryListAtPath(path)
			switch result {
			case .failure:
				break
			case .success(let list):
				let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
				let entities = list.sorted(by: { $0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set) })
				callback(entities)
			}
		}
	}

	func getCoverForDirectoryAtPath(_ path: String, callback: @escaping (Data) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let result = strongSelf.connection.getCoverForDirectoryAtPath(path)
			switch result {
			case .failure:
				break
			case .success(let data):
				callback(data)
			}
		}
	}

	// MARK: - Private
	private func startTimer(_ interval: Int) {
		timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: queue)
		timer.schedule(deadline: .now(), repeating: .milliseconds(interval))
		timer.setEventHandler { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.playerInformations()
		}
		timer.resume()
	}

	private func stopTimer() {
		if timer != nil {
			timer.cancel()
			timer = nil
		}
	}

	private func getListForMusicalEntityType(_ type: MusicalEntityType, callback: @escaping ([MusicalEntity]) -> Void) {
		guard MPDConnection.isValid(connection) else { return }

		queue.async { [weak self] in
			guard let strongSelf = self else { return }

			let result = strongSelf.connection.getListForMusicalEntityType(type)
			switch result {
			case .failure:
				break
			case .success(let list):
				let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
				let entities = list.sorted(by: { $0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set) })
				switch type {
				case .albums:
					strongSelf._albums = entities as? [Album]
				case .artists:
					strongSelf._artists = entities as? [Artist]
				case .albumsartists:
					strongSelf._albumsartists = entities as? [Artist]
				case .genres:
					strongSelf._genres = entities as? [Genre]
				case .playlists:
					break
				default:
					return
				}
				callback(entities)
			}
		}
	}

	private func playerInformations() {
		guard MPDConnection.isValid(connection) else { return }

		do {
			let result = try connection.getPlayerInfos(matchAlbum: self.isDirectoryBased == false)
			switch result {
			case .failure(let error):
				if self.isDirectoryBased == false {
					logger.error(Logger.Message(stringLiteral: error.message.description))
				}
			case .success(let result):
				guard let infos = result else { return }
				let status = infos[PLAYER_STATUS_KEY] as! Int
				let track = infos[PLAYER_TRACK_KEY] as! Track
				let album = infos[PLAYER_ALBUM_KEY] as! Album
				let random = infos[PLAYER_RANDOM_KEY] as! Bool
				let loop = infos[PLAYER_REPEAT_KEY] as! Bool

				// Track changed
				if currentTrack == nil || (currentTrack != nil && track != currentTrack!) {
					NotificationCenter.default.postOnMainThreadAsync(name: .playingTrackChanged, object: nil, userInfo: infos)
				}

				// Status changed
				if currentState.status.rawValue != status {
					NotificationCenter.default.postOnMainThreadAsync(name: .playerStatusChanged, object: nil, userInfo: infos)
				}

				currentState = PlayerState(status: PlayerStatus(rawValue: status)!, isRandom: random, isRepeat: loop)
				currentTrack = track
				currentAlbum = album
				NotificationCenter.default.postOnMainThreadAsync(name: .currentPlayingTrack, object: nil, userInfo: infos)
			}
		} catch let error {
			logger.error(Logger.Message(stringLiteral: error.localizedDescription))
		}
	}

	// MARK: - Notifications
	@objc func audioServerConfigurationDidChange(_ aNotification: Notification) {
		if let server = aNotification.object as? MPDServer {
			self.server = server
			_ = reinitialize()
		}
	}

	@objc func applicationDidEnterBackground(_ aNotification: Notification) {
		deinitialize()
	}

	@objc func applicationWillEnterForeground(_ aNotification: Notification) {
		_ = reinitialize()
	}
}

extension MPDBridge: MPDConnectionDelegate {
	func albumMatchingName(_ name: String) -> Album? {
		_albums?.filter { $0.name == name }.first
	}
}
