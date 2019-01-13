import MPDCLIENT
import UIKit


final class MPDConnection : AudioServerConnection
{
	// MARK: - Public properties
	// mpd server
	let server: AudioServer
	// Delegate
	weak var delegate: AudioServerConnectionDelegate?
	// Connected flag
	private(set) var isConnected = false

	// MARK: - Private properties
	// mpd_connection object
	private var _connection: OpaquePointer? = nil
	// Timeout in seconds
	private let _timeout = UInt32(10)

	// MARK: - Initializers
	init(_ server: AudioServer)
	{
		self.server = server
	}

	deinit
	{
		self.disconnect()
	}

	// MARK: - Connection
	func connect() -> ActionResult<Void>
	{
		// Open connection
		_connection = mpd_connection_new(server.hostname, UInt32(server.port), _timeout * 1000)
		if mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS
		{
			_connection = nil
			return ActionResult<Void>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		// Set password if needed
		if server.password.count > 0
		{
			if mpd_run_password(_connection, server.password) == false
			{
				mpd_connection_free(_connection)
				_connection = nil
				return ActionResult<Void>(succeeded: false, message: getLastErrorMessageForConnection())
			}
		}

		isConnected = true
		return ActionResult<Void>(succeeded: true)
	}

	func disconnect()
	{
		if _connection != nil
		{
			mpd_connection_free(_connection)
			_connection = nil
		}
		isConnected = false
	}

	// MARK: - Get infos about tracks / albums / etc…
	func getListForDisplayType(_ displayType: DisplayType) -> ActionResult<[MusicalEntity]>
	{
		if displayType == .playlists
		{
			return self.getPlaylists()
		}

		let tagType = mpdTagTypeFromDisplayType(displayType)

		var list = [MusicalEntity]()
		if (mpd_search_db_tags(_connection, tagType) == false || mpd_search_commit(_connection) == false)
		{
			return ActionResult<[MusicalEntity]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		var pair = mpd_recv_pair_tag(_connection, tagType)
		while pair != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (pair?.pointee.value)!), count: Int(strlen(pair?.pointee.value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				switch displayType
				{
					case .albums:
						list.append(Album(name: name))
					case .artists:
						list.append(Artist(name: name))
					case .albumsartists:
						list.append(Artist(name: name))
					case .genres:
						list.append(Genre(name: name))
					case .playlists:
						raise(0)
				}
			}

			mpd_return_pair(_connection, pair)
			pair = mpd_recv_pair_tag(_connection, tagType)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			return ActionResult<[MusicalEntity]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		return ActionResult<[MusicalEntity]>(succeeded: true, entity: list)
	}

	func getAlbumsForGenre(_ genre: Genre, firstOnly: Bool) -> ActionResult<[Album]>
	{
		if mpd_search_db_tags(_connection, MPD_TAG_ALBUM) == false
		{
			return ActionResult<[Album]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name) == false
		{
			return ActionResult<[Album]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_commit(_connection) == false
		{
			return ActionResult<[Album]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		var list = [Album]()
		var pair = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM)
		while pair != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (pair?.pointee.value)!), count: Int(strlen(pair?.pointee.value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				if let album = delegate?.albumMatchingName(name)
				{
					list.append(album)
				}
			}

			mpd_return_pair(_connection, pair)

			if list.count >= 1 && firstOnly == true
			{
				break
			}

			pair = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			return ActionResult<[Album]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		return ActionResult<[Album]>(succeeded: true, entity: list)
	}

	func getAlbumsForArtist(_ artist: Artist, isAlbumArtist: Bool = false) -> ActionResult<[Album]>
	{
		if mpd_search_db_tags(_connection, MPD_TAG_ALBUM) == false
		{
			return ActionResult<[Album]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, isAlbumArtist ? MPD_TAG_ALBUM_ARTIST : MPD_TAG_ARTIST, artist.name) == false
		{
			return ActionResult<[Album]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_commit(_connection) == false
		{
			return ActionResult<[Album]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		var list = [Album]()
		var pair = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM)
		while pair != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (pair?.pointee.value)!), count: Int(strlen(pair?.pointee.value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				if let album = delegate?.albumMatchingName(name)
				{
					list.append(album)
				}
			}

			mpd_return_pair(_connection, pair)
			pair = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			return ActionResult<[Album]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		return ActionResult<[Album]>(succeeded: true, entity: list)
	}

	func getArtistsForGenre(_ genre: Genre) -> ActionResult<[Artist]>
	{
		if mpd_search_db_tags(_connection, MPD_TAG_ARTIST) == false
		{
			return ActionResult<[Artist]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name) == false
		{
			return ActionResult<[Artist]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_commit(_connection) == false
		{
			return ActionResult<[Artist]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		var list = [Artist]()
		var pair = mpd_recv_pair_tag(_connection, MPD_TAG_ARTIST)
		while pair != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (pair?.pointee.value)!), count: Int(strlen(pair?.pointee.value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				list.append(Artist(name: name))
			}
			
			mpd_return_pair(_connection, pair)
			pair = mpd_recv_pair_tag(_connection, MPD_TAG_ARTIST)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			return ActionResult<[Artist]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		return ActionResult<[Artist]>(succeeded: true, entity: list)
	}

	func getPathForAlbum(_ album: Album) -> ActionResult<String>
	{
		if mpd_search_db_songs(_connection, true) == false
		{
			return ActionResult<String>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			return ActionResult<String>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_commit(_connection) == false
		{
			return ActionResult<String>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		var path: String? = nil
		if let song = mpd_recv_song(_connection)
		{
			if let uri = mpd_song_get_uri(song)
			{
				let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: uri), count: Int(strlen(uri)), deallocator: .none)
				if let name = String(data: dataTemp, encoding: .utf8)
				{
					path = URL(fileURLWithPath: name).deletingLastPathComponent().path
				}
			}
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			return ActionResult<String>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		return ActionResult<String>(succeeded: true, entity: path)
	}

	func getTracksForAlbum(_ album: Album) -> ActionResult<[Track]>
	{
		if mpd_search_db_songs(_connection, true) == false
		{
			return ActionResult<[Track]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			return ActionResult<[Track]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if album.artist.count > 0
		{
			if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM_ARTIST, album.artist) == false
			{
				return ActionResult<[Track]>(succeeded: false, message: getLastErrorMessageForConnection())
			}
		}
		if mpd_search_commit(_connection) == false
		{
			return ActionResult<[Track]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		var list = [Track]()
		var song = mpd_recv_song(_connection)
		while song != nil
		{
			if let track = trackFromMPDSongObject(song!)
			{
				list.append(track)
			}
			song = mpd_recv_song(_connection)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			return ActionResult<[Track]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		return ActionResult<[Track]>(succeeded: true, entity: list)
	}

	func getTracksForPlaylist(_ playlist: Playlist) -> ActionResult<[Track]>
	{
		if mpd_send_list_playlist(_connection, playlist.name) == false
		{
			return ActionResult<[Track]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		var list = [Track]()
		var entity = mpd_recv_entity(_connection)
		var trackNumber = 1
		while entity != nil
		{
			if let song = mpd_entity_get_song(entity)
			{
				if let track = trackFromMPDSongObject(song)
				{
					track.trackNumber = trackNumber
					list.append(track)
					trackNumber += 1
				}
			}
			entity = mpd_recv_entity(_connection)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			return ActionResult<[Track]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		for track in list
		{
			if mpd_search_db_songs(_connection, true) == false
			{
				Logger.shared.log(type: .error, message: getLastErrorMessageForConnection().description)
				continue
			}
			if mpd_search_add_uri_constraint(_connection, MPD_OPERATOR_DEFAULT, track.uri) == false
			{
				Logger.shared.log(type: .error, message: getLastErrorMessageForConnection().description)
				continue
			}

			if mpd_search_commit(_connection) == false
			{
				Logger.shared.log(type: .error, message: getLastErrorMessageForConnection().description)
				continue
			}

			var song = mpd_recv_song(_connection)
			while song != nil
			{
				if let t = trackFromMPDSongObject(song!)
				{
					track.artist = t.artist
					track.duration = t.duration
					track.position = t.position
					track.name = t.name
				}
				song = mpd_recv_song(_connection)
			}

			if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
			{
				return ActionResult<[Track]>(succeeded: false, message: getLastErrorMessageForConnection())
			}
		}

		return ActionResult<[Track]>(succeeded: true, entity: list)
	}

	func getMetadatasForAlbum(_ album: Album) throws -> ActionResult<[String : Any]>
	{
		// Find album artist
		if mpd_search_db_tags(_connection, MPD_TAG_ALBUM_ARTIST) == false
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_commit(_connection) == false
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		var metadatas = [String : Any]()
		let tmpArtist = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM_ARTIST)
		if tmpArtist != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (tmpArtist?.pointee.value)!), count: Int(strlen(tmpArtist?.pointee.value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				metadatas["artist"] = name
			}
			mpd_return_pair(_connection, tmpArtist)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		// Find album year
		if mpd_search_db_tags(_connection, MPD_TAG_DATE) == false
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_commit(_connection) == false
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		let tmpDate = mpd_recv_pair_tag(_connection, MPD_TAG_DATE)
		if tmpDate != nil
		{
			var l = Int(strlen(tmpDate?.pointee.value))
			if l > 4
			{
				l = 4
			}
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (tmpDate?.pointee.value)!), count: l, deallocator: .none)
			if let year = String(data: dataTemp, encoding: .utf8)
			{
				metadatas["year"] = year
			}
			mpd_return_pair(_connection, tmpDate)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		// Find album genre
		if mpd_search_db_tags(_connection, MPD_TAG_GENRE) == false
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		if mpd_search_commit(_connection) == false
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		let tmpGenre = mpd_recv_pair_tag(_connection, MPD_TAG_GENRE)
		if tmpGenre != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (tmpGenre?.pointee.value)!), count: Int(strlen(tmpGenre?.pointee.value)), deallocator: .none)
			if let genre = String(data: dataTemp, encoding: .utf8)
			{
				metadatas["genre"] = genre
			}
			mpd_return_pair(_connection, tmpGenre)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.shared.log(type: .error, message: getLastErrorMessageForConnection().description)
		}

		return ActionResult<[String : Any]>(succeeded: true, entity: metadatas)
	}

	// MARK: - Playlists
	func getPlaylists() -> ActionResult<[MusicalEntity]>
	{
		if mpd_send_list_playlists(_connection) == false
		{
			return ActionResult<[MusicalEntity]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		var list = [Playlist]()
		var playlist = mpd_recv_playlist(_connection)
		while playlist != nil
		{
			if let tmpPath = mpd_playlist_get_path(playlist)
			{
				if let name = String(cString: tmpPath, encoding: .utf8)
				{
					list.append(Playlist(name: name))
				}
			}

			playlist = mpd_recv_playlist(_connection)
		}

		return ActionResult<[MusicalEntity]>(succeeded: true, entity: list)
	}

	func getSongsOfCurrentQueue() -> ActionResult<[Track]>
	{
		if mpd_send_list_queue_meta(_connection) == false
		{
			return ActionResult<[Track]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		var list = [Track]()
		var song = mpd_recv_song(_connection)
		while song != nil
		{
			if let track = trackFromMPDSongObject(song!)
			{
				list.append(track)
			}
			song = mpd_recv_song(_connection)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			return ActionResult<[Track]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		return ActionResult<[Track]>(succeeded: true, entity: list)
	}

	func createPlaylist(name: String) -> ActionResult<Void>
	{
		let ret = mpd_run_save(_connection, name)
		if ret
		{
			mpd_run_playlist_clear(_connection, name)
			return ActionResult(succeeded: ret)
		}
		return ActionResult(succeeded: false, message: getLastErrorMessageForConnection())
	}

	func deletePlaylist(name: String) -> ActionResult<Void>
	{
		let ret = mpd_run_rm(_connection, name)
		if ret
		{
			return ActionResult(succeeded: ret)
		}
		return ActionResult(succeeded: false, message: getLastErrorMessageForConnection())
	}

	func renamePlaylist(playlist: Playlist, newName: String) -> ActionResult<Void>
	{
		let ret = mpd_run_rename(_connection, playlist.name, newName)
		if ret
		{
			return ActionResult(succeeded: ret)
		}
		return ActionResult(succeeded: false, message: getLastErrorMessageForConnection())
	}

	func addTrackToPlaylist(playlist: Playlist, track: Track) -> ActionResult<Void>
	{
		let ret = mpd_run_playlist_add(_connection, playlist.name, track.uri)
		if ret
		{
			return ActionResult(succeeded: ret)
		}
		return ActionResult(succeeded: false, message: getLastErrorMessageForConnection())
	}

	func removeTrackFromPlaylist(playlist: Playlist, track: Track) -> ActionResult<Void>
	{
		let ret = mpd_run_playlist_delete(_connection, playlist.name, UInt32(track.trackNumber - 1))
		if ret
		{
			return ActionResult(succeeded: ret)
		}
		return ActionResult(succeeded: false, message: getLastErrorMessageForConnection())
	}

	// MARK: - Play / Queue
	func playAlbum(_ album: Album, shuffle: Bool, loop: Bool) -> ActionResult<Void>
	{
		if let songs = album.tracks
		{
			return playTracks(songs, shuffle: shuffle, loop: loop)
		}
		else
		{
			let result = getTracksForAlbum(album)
			if result.succeeded
			{
				if let tracks = result.entity
				{
					return playTracks(tracks, shuffle: shuffle, loop: loop)
				}
			}
			return ActionResult<Void>(succeeded: false, message: getLastErrorMessageForConnection())
		}
	}

	func playTracks(_ tracks: [Track], shuffle: Bool, loop: Bool) -> ActionResult<Void>
	{
		if mpd_run_clear(_connection) == false
		{
			return ActionResult<Void>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		_ = setRandom(shuffle)
		_ = setRepeat(loop)

		for track in tracks
		{
			if mpd_run_add(_connection, track.uri) == false
			{
				return ActionResult<Void>(succeeded: false, message: getLastErrorMessageForConnection())
			}
		}

		if mpd_run_play_pos(_connection, shuffle ? arc4random_uniform(UInt32(tracks.count)) : 0) == false
		{
			return ActionResult<Void>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		return ActionResult<Void>(succeeded: true)
	}

	func playPlaylist(_ playlist: Playlist, shuffle: Bool, loop: Bool, position: UInt32 = 0) -> ActionResult<Void>
	{
		if mpd_run_clear(_connection) == false
		{
			return ActionResult<Void>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		_ = setRandom(shuffle)
		_ = setRepeat(loop)

		if mpd_run_load(_connection, playlist.name) == false
		{
			return ActionResult<Void>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		if mpd_run_play_pos(_connection, UInt32(position)) == false
		{
			return ActionResult<Void>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		return ActionResult<Void>(succeeded: true)
	}

	func playTrackAtPosition(_ position: UInt32) -> ActionResult<Void>
	{
		let ret = mpd_run_play_pos(_connection, position)
		return ActionResult<Void>(succeeded: ret, message: getLastErrorMessageForConnection())
	}
	
	func addAlbumToQueue(_ album: Album) -> ActionResult<Void>
	{
		if let tracks = album.tracks
		{
			for track in tracks
			{
				if mpd_run_add(_connection, track.uri) == false
				{
					return ActionResult<Void>(succeeded: false, message: getLastErrorMessageForConnection())
				}
			}
		}
		else
		{
			let result = getTracksForAlbum(album)
			if result.succeeded
			{
				if let tracks = result.entity
				{
					for track in tracks
					{
						if mpd_run_add(_connection, track.uri) == false
						{
							return ActionResult<Void>(succeeded: false, message: getLastErrorMessageForConnection())
						}
					}
				}
			}
		}
		return ActionResult<Void>(succeeded: true)
	}

	func togglePause() -> ActionResult<Void>
	{
		let ret = mpd_run_toggle_pause(_connection)
		return ActionResult<Void>(succeeded: ret, message: getLastErrorMessageForConnection())
	}

	func nextTrack() -> ActionResult<Void>
	{
		let ret = mpd_run_next(_connection)
		return ActionResult<Void>(succeeded: ret, message: getLastErrorMessageForConnection())
	}

	func previousTrack() -> ActionResult<Void>
	{
		let ret = mpd_run_previous(_connection)
		return ActionResult<Void>(succeeded: ret, message: getLastErrorMessageForConnection())
	}

	func setRandom(_ random: Bool) -> ActionResult<Void>
	{
		let ret = mpd_run_random(_connection, random)
		return ActionResult<Void>(succeeded: ret, message: getLastErrorMessageForConnection())
	}

	func setRepeat(_ loop: Bool) -> ActionResult<Void>
	{
		let ret = mpd_run_repeat(_connection, loop)
		return ActionResult<Void>(succeeded: ret, message: getLastErrorMessageForConnection())
	}

	func setTrackPosition(_ position: Int, trackPosition: UInt32) -> ActionResult<Void>
	{
		let ret = mpd_run_seek_pos(_connection, trackPosition, UInt32(position))
		return ActionResult<Void>(succeeded: ret, message: getLastErrorMessageForConnection())
	}

	func setVolume(_ volume: UInt32) -> ActionResult<Void>
	{
		let ret = mpd_run_set_volume(_connection, volume)
		return ActionResult<Void>(succeeded: ret, message: getLastErrorMessageForConnection())
	}

	func getVolume() -> ActionResult<Int>
	{
		let result = getStatus()
		if result.succeeded == false
		{
			return ActionResult<Int>(succeeded: false, entity: -1, messages: result.messages)
		}
		return ActionResult<Int>(succeeded: true, entity: Int(mpd_status_get_volume(result.entity!)))
	}

	// MARK: - Player status
	func getStatus() -> ActionResult<OpaquePointer>
	{
		let ret = mpd_run_status(_connection)
		if ret == nil
		{
			return ActionResult<OpaquePointer>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		return ActionResult<OpaquePointer>(succeeded: true, entity: ret)
	}

	func getPlayerInfos() throws -> ActionResult<[String : Any]>
	{
		guard let song = mpd_run_current_song(_connection) else
		{
			return ActionResult<[String : Any]>(succeeded: true, message: Message(content: "No song is currently being played.", type: .information))
		}

		let tmpRet = getStatus()
		if tmpRet.succeeded == false
		{
			return ActionResult<[String : Any]>(succeeded: false, messages: tmpRet.messages)
		}

		let status = tmpRet.entity!
		guard let track = trackFromMPDSongObject(song) else
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		let state = statusFromMPDStateObject(mpd_status_get_state(status)).rawValue
		let elapsed = mpd_status_get_elapsed_time(status)
		let volume = Int(mpd_status_get_volume(status))
		guard let tmpAlbumName = mpd_song_get_tag(song, MPD_TAG_ALBUM, 0) else
		{
			return ActionResult<[String : Any]>(succeeded: false, message: getLastErrorMessageForConnection())
		}
		let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating:tmpAlbumName), count: Int(strlen(tmpAlbumName)), deallocator: .none)
		if let name = String(data: dataTemp, encoding: .utf8)
		{
			if let album = delegate?.albumMatchingName(name)
			{
				return ActionResult<[String : Any]>(succeeded: true, entity: [kPlayerTrackKey : track, kPlayerAlbumKey : album, kPlayerElapsedKey : Int(elapsed), kPlayerStatusKey : state, kPlayerVolumeKey : volume])
			}
		}

		return ActionResult<[String : Any]>(succeeded: false, message: Message(content: "No matching album found.", type: .error))
	}

	func getAudioFormat() -> ActionResult<[String : String]>
	{
		let result = getStatus()
		if result.succeeded == false
		{
			return ActionResult<[String : String]>(succeeded: false, entity: nil, messages: result.messages)
		}

		let status = result.entity!
		guard let audioFormat = mpd_status_get_audio_format(status) else
		{
			return ActionResult<[String : String]>(succeeded: false, entity: nil, messages: result.messages)
		}

		var object = [String : String]()
		object["samplerate"] = "\(audioFormat.pointee.sample_rate)"
		object["bits"] = "\(audioFormat.pointee.bits)"
		object["channels"] = "\(audioFormat.pointee.channels)"

		return ActionResult<[String : String]>(succeeded: true, entity: object, messages: result.messages)
	}

	// MARK: - Outputs
	func getAvailableOutputs() -> ActionResult<[AudioOutput]>
	{
		if mpd_send_outputs(_connection) == false
		{
			return ActionResult<[AudioOutput]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		var ret = [AudioOutput]()
		var output = mpd_recv_output(_connection)
		while output != nil
		{
			guard let tmpName = mpd_output_get_name(output) else
			{
				mpd_output_free(output)
				continue
			}

			let id = Int(mpd_output_get_id(output))

			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmpName), count: Int(strlen(tmpName)), deallocator: .none)
			guard let name = String(data: dataTemp, encoding: .utf8) else
			{
				mpd_output_free(output)
				continue
			}

			let o = AudioOutput(id: id, name: name, enabled: mpd_output_get_enabled(output))
			ret.append(o)
			mpd_output_free(output)
			output = mpd_recv_output(_connection)
		}

		return ActionResult<[AudioOutput]>(succeeded: true, entity: ret)
	}

	func toggleOutput(output: AudioOutput) -> ActionResult<Void>
	{
		if output.enabled
		{
			return ActionResult<Void>(succeeded: mpd_run_disable_output(_connection, UInt32(output.id)))
		}
		else
		{
			return ActionResult<Void>(succeeded: mpd_run_enable_output(_connection, UInt32(output.id)))
		}
	}

	// MARK: - Stats
	func getStats() -> ActionResult<[String : String]>
	{
		guard let ret = mpd_run_stats(_connection) else
		{
			return ActionResult<[String : String]>(succeeded: false, message: getLastErrorMessageForConnection())
		}

		let nalbums = mpd_stats_get_number_of_albums(ret)
		let nartists = mpd_stats_get_number_of_artists(ret)
		let nsongs = mpd_stats_get_number_of_songs(ret)
		let dbplaytime = mpd_stats_get_db_play_time(ret)
		let mpduptime = mpd_stats_get_uptime(ret)
		let mpdplaytime = mpd_stats_get_play_time(ret)
		let mpddbupdate = mpd_stats_get_db_update_time(ret)

		var entity = [String : String]()
		entity["albums"] = String(nalbums)
		entity["artists"] = String(nartists)
		entity["songs"] = String(nsongs)
		entity["dbplaytime"] = String(dbplaytime)
		entity["mpduptime"] = String(mpduptime)
		entity["mpdplaytime"] = String(mpdplaytime)
		entity["mpddbupdate"] = String(mpddbupdate)
		return ActionResult<[String : String]>(succeeded: true, entity: entity)
	}

	func updateDatabase() -> ActionResult<Void>
	{
		let ret = mpd_run_update(_connection, nil)
		return ActionResult(succeeded: ret > 0)
	}

	// MARK: - Private
	private func getLastErrorMessageForConnection() -> Message
	{
		if _connection == nil
		{
			return Message(content: "No connection to MPD", type: .error)
		}

		if mpd_connection_get_error(_connection) == MPD_ERROR_SUCCESS
		{
			return Message(content: "no error", type: .success)
		}

		if let errorMessage = mpd_connection_get_error_message(_connection)
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: errorMessage), count: Int(strlen(errorMessage)), deallocator: .none)
			if let msg = String(data: dataTemp, encoding: .utf8)
			{
				return Message(content: msg, type: .error)
			}
			else
			{
				return Message(content: "unable to get error message", type: .error)
			}
		}

		return Message(content: "no error message", type: .error)
	}

	private func trackFromMPDSongObject(_ song: OpaquePointer) -> Track?
	{
		// URI, should always be available?
		guard let tmpURI = mpd_song_get_uri(song) else
		{
			return nil
		}
		let dataTmp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmpURI), count: Int(strlen(tmpURI)), deallocator: .none)
		guard let uri = String(data: dataTmp, encoding: .utf8) else
		{
			return nil
		}
		// title
		var title = ""
		if let tmpPtr = mpd_song_get_tag(song, MPD_TAG_TITLE, 0)
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmpPtr), count: Int(strlen(tmpPtr)), deallocator: .none)
			let tmpString = String(data: dataTemp, encoding: .utf8)
			title = tmpString ?? ""
		}
		else
		{
			let bla = uri.components(separatedBy: "/")
			if let filename = bla.last
			{
				if let f = filename.components(separatedBy: ".").first
				{
					title = f
				}
			}
		}
		// artist
		var artist = ""
		if let tmpPtr = mpd_song_get_tag(song, MPD_TAG_ARTIST, 0)
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmpPtr), count: Int(strlen(tmpPtr)), deallocator: .none)
			let tmpString = String(data: dataTemp, encoding: .utf8)
			artist = tmpString ?? ""
		}
		// track number
		var trackNumber = "0"
		if let tmpPtr = mpd_song_get_tag(song, MPD_TAG_TRACK, 0)
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmpPtr), count: Int(strlen(tmpPtr)), deallocator: .none)
			if let tmpString = String(data: dataTemp, encoding: .utf8)
			{
				if let number = tmpString.components(separatedBy: "/").first
				{
					trackNumber = number
				}
			}
		}
		// duration
		let duration = mpd_song_get_duration(song)
		// Position in the queue
		let pos = mpd_song_get_pos(song)

		// create track
		let trackNumInt = Int(trackNumber) ?? 1
		let track = Track(name: title, artist: artist, duration: Duration(seconds: UInt(duration)), trackNumber: trackNumInt, uri: uri)
		track.position = pos
		return track
	}

	private func statusFromMPDStateObject(_ state: mpd_state) -> PlayerStatus
	{
		switch state
		{
			case MPD_STATE_PLAY:
				return .playing
			case MPD_STATE_PAUSE:
				return .paused
			case MPD_STATE_STOP:
				return .stopped
			default:
				return .unknown
		}
	}

	private func mpdTagTypeFromDisplayType(_ displayType: DisplayType) -> mpd_tag_type
	{
		switch displayType
		{
			case .albums:
				return MPD_TAG_ALBUM
			case .genres:
				return MPD_TAG_GENRE
			case .artists:
				return MPD_TAG_ARTIST
			case .albumsartists:
				return MPD_TAG_ALBUM_ARTIST
			case .playlists:
				return MPD_TAG_UNKNOWN
		}
	}
}
