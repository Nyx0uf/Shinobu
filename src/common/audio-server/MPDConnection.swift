import MPDCLIENT
import UIKit


public let PLAYER_TRACK_KEY = "track"
public let PLAYER_ALBUM_KEY = "album"
public let PLAYER_ELAPSED_KEY = "elapsed"
public let PLAYER_STATUS_KEY = "status"
public let PLAYER_VOLUME_KEY = "volume"


enum PlayerStatus: Int
{
	case playing = 0
	case paused = 1
	case stopped = 2
	case unknown = -1
}

struct AudioOutput
{
	let id: Int
	let name: String
	let enabled: Bool
}


protocol MPDConnectionDelegate: class
{
	func albumMatchingName(_ name: String) -> Album?
}


struct MPDConnectionError: Error
{
	enum Kind
	{
		case invalidServerParameters
		case invalidPassword
		case connectionFailure
		case outOfMemory
		case searchError
		case clearError
		case addError
		case removeError
		case playError
		case createPlaylistError
		case deletePlaylistError
		case renamePlaylistError
		case loadPlaylistError
		case togglePlayPauseError
		case toggleRandomError
		case toggleRepeatError
		case changeTrackError
		case changePositionError
		case changeVolumeError
		case getStatusError
		case updateError
		case notPlaying
		case getOutputsError
		case toggleOutput
	}

	let kind: Kind
	let message: Message

	init(_ kind: Kind, _ message: Message)
	{
		self.message = message
		self.kind = kind
	}

	public var localizedDescription: String
	{
		return message.description
	}
}


final class MPDConnection
{
	// MARK: - Public properties
	// mpd server
	let server: MPDServer
	// Delegate
	weak var delegate: MPDConnectionDelegate?
	// Connected flag
	private(set) var isConnected = false

	// MARK: - Private properties
	// mpd_connection object
	private var connection: OpaquePointer? = nil
	// Timeout in seconds
	private let timeout = UInt32(10)

	// MARK: - Initializers
	init(_ server: MPDServer)
	{
		self.server = server
	}

	deinit
	{
		self.disconnect()
	}

	// MARK: - Connection
	func connect() -> Result<Bool, MPDConnectionError>
	{
		// Open connection
		connection = mpd_connection_new(server.hostname, UInt32(server.port), timeout * 1000)
		if connection == nil
		{
			return .failure(MPDConnectionError(.outOfMemory, Message(content: "Out of memory", type: .error)))
		}
		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS
		{
			let message = getLastErrorMessageForConnection()
			connection = nil
			return .failure(MPDConnectionError(.connectionFailure, message))
		}

		// Set password if needed
		if server.password.count > 0
		{
			if mpd_run_password(connection, server.password) == false
			{
				let message = getLastErrorMessageForConnection()
				mpd_connection_free(connection)
				connection = nil
				return .failure(MPDConnectionError(.invalidPassword, message))
			}
		}

		isConnected = true
		return .success(true)
	}

	func disconnect()
	{
		if connection != nil
		{
			mpd_connection_free(connection)
			connection = nil
		}
		isConnected = false
	}

	// MARK: - Get infos about tracks / albums / etc…
	func getListForMusicalEntityType(_ displayType: MusicalEntityType) -> Result<[MusicalEntity], MPDConnectionError>
	{
		if displayType == .playlists
		{
			return getPlaylists()
		}

		let tagType = mpdTagMatchingMusicalEntityType(displayType)

		var list = [MusicalEntity]()
		if mpd_search_db_tags(connection, tagType) == false || mpd_search_commit(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var pair = mpd_recv_pair_tag(connection, tagType)
		while pair != nil
		{
			guard let value = pair?.pointee.value else
			{
				mpd_return_pair(connection, pair)
				pair = mpd_recv_pair_tag(connection, tagType)
				continue
			}
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: value), count: Int(strlen(value)), deallocator: .none)
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
					default:
						raise(0)
				}
			}

			mpd_return_pair(connection, pair)
			pair = mpd_recv_pair_tag(connection, tagType)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func getAlbumsForGenre(_ genre: Genre, firstOnly: Bool) -> Result<[Album], MPDConnectionError>
	{
		if mpd_search_db_tags(connection, MPD_TAG_ALBUM) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Album]()
		var pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
		while pair != nil
		{
			guard let value = pair?.pointee.value else
			{
				mpd_return_pair(connection, pair)
				pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
				continue
			}
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: value), count: Int(strlen(value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				if let album = delegate?.albumMatchingName(name)
				{
					list.append(album)
				}
			}

			mpd_return_pair(connection, pair)

			if firstOnly && list.count >= 1
			{
				break
			}

			pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func getAlbumsForArtist(_ artist: Artist, isAlbumArtist: Bool = false) -> Result<[Album], MPDConnectionError>
	{
		if mpd_search_db_tags(connection, MPD_TAG_ALBUM) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, isAlbumArtist ? MPD_TAG_ALBUM_ARTIST : MPD_TAG_ARTIST, artist.name) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Album]()
		var pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
		while pair != nil
		{
			guard let value = pair?.pointee.value else
			{
				mpd_return_pair(connection, pair)
				pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
				continue
			}
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: value), count: Int(strlen(value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				if let album = delegate?.albumMatchingName(name)
				{
					list.append(album)
				}
			}

			mpd_return_pair(connection, pair)
			pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func getArtistsForGenre(_ genre: Genre, isAlbumArtist: Bool = false) -> Result<[Artist], MPDConnectionError>
	{
		if mpd_search_db_tags(connection, isAlbumArtist ? MPD_TAG_ALBUM_ARTIST : MPD_TAG_ARTIST) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Artist]()
		var pair = mpd_recv_pair_tag(connection, isAlbumArtist ? MPD_TAG_ALBUM_ARTIST : MPD_TAG_ARTIST)
		while pair != nil
		{
			guard let value = pair?.pointee.value else
			{
				mpd_return_pair(connection, pair)
				pair = mpd_recv_pair_tag(connection, isAlbumArtist ? MPD_TAG_ALBUM_ARTIST : MPD_TAG_ARTIST)
				continue
			}
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: value), count: Int(strlen(value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				list.append(Artist(name: name))
			}
			
			mpd_return_pair(connection, pair)
			pair = mpd_recv_pair_tag(connection, isAlbumArtist ? MPD_TAG_ALBUM_ARTIST : MPD_TAG_ARTIST)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func getPathForAlbum(_ album: Album) -> Result<String, MPDConnectionError>
	{
		if mpd_search_db_songs(connection, true) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var path: String? = nil
		if let song = mpd_recv_song(connection)
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

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(path ?? "")
	}

	func getTracksForAlbum(_ album: Album) -> Result<[Track], MPDConnectionError>
	{
		if mpd_search_db_songs(connection, true) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if album.artist.count > 0
		{
			if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM_ARTIST, album.artist) == false
			{
				return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
			}
		}
		if mpd_search_commit(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Track]()
		var song = mpd_recv_song(connection)
		while song != nil
		{
			if let track = trackFromMPDSongObject(song!)
			{
				list.append(track)
			}
			song = mpd_recv_song(connection)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func getTracksForPlaylist(_ playlist: Playlist) -> Result<[Track], MPDConnectionError>
	{
		if mpd_send_list_playlist(connection, playlist.name) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Track]()
		var entity = mpd_recv_entity(connection)
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
			entity = mpd_recv_entity(connection)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		for track in list
		{
			if mpd_search_db_songs(connection, true) == false
			{
				Logger.shared.log(type: .error, message: getLastErrorMessageForConnection().description)
				continue
			}
			if mpd_search_add_uri_constraint(connection, MPD_OPERATOR_DEFAULT, track.uri) == false
			{
				Logger.shared.log(type: .error, message: getLastErrorMessageForConnection().description)
				continue
			}

			if mpd_search_commit(connection) == false
			{
				Logger.shared.log(type: .error, message: getLastErrorMessageForConnection().description)
				continue
			}

			var song = mpd_recv_song(connection)
			while song != nil
			{
				if let t = trackFromMPDSongObject(song!)
				{
					track.artist = t.artist
					track.duration = t.duration
					track.position = t.position
					track.name = t.name
				}
				song = mpd_recv_song(connection)
			}

			if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
			{
				return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
			}
		}

		return .success(list)
	}

	func getMetadatasForAlbum(_ album: Album) throws -> Result<[String : Any], MPDConnectionError>
	{
		// Find album artist
		if mpd_search_db_tags(connection, MPD_TAG_ALBUM_ARTIST) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var metadatas = [String : Any]()
		let tmpArtist = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM_ARTIST)
		if tmpArtist != nil
		{
			if let value = tmpArtist?.pointee.value
			{
				let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: value), count: Int(strlen(value)), deallocator: .none)
				if let name = String(data: dataTemp, encoding: .utf8)
				{
					metadatas["artist"] = name
				}
			}
			mpd_return_pair(connection, tmpArtist)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		// Find album year
		if mpd_search_db_tags(connection, MPD_TAG_DATE) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		let tmpDate = mpd_recv_pair_tag(connection, MPD_TAG_DATE)
		if tmpDate != nil
		{
			if let value = tmpDate?.pointee.value
			{
				var l = Int(strlen(value))
				if l > 4
				{
					l = 4
				}
				let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: value), count: l, deallocator: .none)
				if let year = String(data: dataTemp, encoding: .utf8)
				{
					metadatas["year"] = year
				}
			}

			mpd_return_pair(connection, tmpDate)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		// Find album genre
		if mpd_search_db_tags(connection, MPD_TAG_GENRE) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		let tmpGenre = mpd_recv_pair_tag(connection, MPD_TAG_GENRE)
		if tmpGenre != nil
		{
			if let value = tmpGenre?.pointee.value
			{
				let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: value), count: Int(strlen(value)), deallocator: .none)
				if let genre = String(data: dataTemp, encoding: .utf8)
				{
					metadatas["genre"] = genre
				}
			}

			mpd_return_pair(connection, tmpGenre)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
		{
			Logger.shared.log(type: .error, message: getLastErrorMessageForConnection().description)
		}

		return .success(metadatas)
	}

	// MARK: - Playlists
	func getPlaylists() -> Result<[MusicalEntity], MPDConnectionError>
	{
		if mpd_send_list_playlists(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Playlist]()
		var playlist = mpd_recv_playlist(connection)
		while playlist != nil
		{
			if let tmpPath = mpd_playlist_get_path(playlist)
			{
				if let name = String(cString: tmpPath, encoding: .utf8)
				{
					list.append(Playlist(name: name))
				}
			}

			playlist = mpd_recv_playlist(connection)
		}

		return .success(list)
	}

	func getSongsOfCurrentQueue() -> Result<[Track], MPDConnectionError>
	{
		if mpd_send_list_queue_meta(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Track]()
		var song = mpd_recv_song(connection)
		while song != nil
		{
			if let track = trackFromMPDSongObject(song!)
			{
				list.append(track)
			}
			song = mpd_recv_song(connection)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false
		{
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func createPlaylist(named name: String) -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_save(connection, name)
		if ret
		{
			mpd_run_playlist_clear(connection, name)
			return .success(true)
		}
		return .failure(MPDConnectionError(.createPlaylistError, getLastErrorMessageForConnection()))
	}

	func deletePlaylist(named name: String) -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_rm(connection, name)
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.deletePlaylistError, getLastErrorMessageForConnection()))
	}

	func renamePlaylist(_ playlist: Playlist, withNewName newName: String) -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_rename(connection, playlist.name, newName)
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.renamePlaylistError, getLastErrorMessageForConnection()))
	}

	func addTrack(_ track: Track, toPlaylist playlist: Playlist) -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_playlist_add(connection, playlist.name, track.uri)
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.addError, getLastErrorMessageForConnection()))
	}

	func removeTrack(_ track: Track, fromPlaylist playlist: Playlist) -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_playlist_delete(connection, playlist.name, UInt32(track.trackNumber - 1))
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.removeError, getLastErrorMessageForConnection()))
	}

	// MARK: - Play / Queue
	func playAlbum(_ album: Album, shuffle: Bool, loop: Bool) -> Result<Bool, MPDConnectionError>
	{
		if let songs = album.tracks
		{
			return playTracks(songs, shuffle: shuffle, loop: loop)
		}
		else
		{
			let result = getTracksForAlbum(album)
			switch result
			{
				case .failure(let error):
					return .failure(error)
				case .success(let tracks):
					return playTracks(tracks, shuffle: shuffle, loop: loop)
			}
		}
	}

	func playTracks(_ tracks: [Track], shuffle: Bool, loop: Bool) -> Result<Bool, MPDConnectionError>
	{
		if mpd_run_clear(connection) == false
		{
			return .failure(MPDConnectionError(.clearError, getLastErrorMessageForConnection()))
		}

		_ = setRandom(shuffle)
		_ = setRepeat(loop)

		for track in tracks
		{
			if mpd_run_add(connection, track.uri) == false
			{
				return .failure(MPDConnectionError(.addError, getLastErrorMessageForConnection()))
			}
		}

		if mpd_run_play_pos(connection, shuffle ? UInt32.random(in: 0 ..< UInt32(tracks.count)) : 0) == false
		{
			return .failure(MPDConnectionError(.playError, getLastErrorMessageForConnection()))
		}

		return .success(true)
	}

	func playPlaylist(_ playlist: Playlist, shuffle: Bool, loop: Bool, position: UInt32 = 0) -> Result<Bool, MPDConnectionError>
	{
		if mpd_run_clear(connection) == false
		{
			return .failure(MPDConnectionError(.clearError, getLastErrorMessageForConnection()))
		}

		_ = setRandom(shuffle)
		_ = setRepeat(loop)

		if mpd_run_load(connection, playlist.name) == false
		{
			return .failure(MPDConnectionError(.loadPlaylistError, getLastErrorMessageForConnection()))
		}

		if mpd_run_play_pos(connection, UInt32(position)) == false
		{
			return .failure(MPDConnectionError(.playError, getLastErrorMessageForConnection()))
		}

		return .success(true)
	}

	func playTrackAtPosition(_ position: UInt32) -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_play_pos(connection, position)
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.playError, getLastErrorMessageForConnection()))
	}
	
	func addAlbumToQueue(_ album: Album) -> Result<Bool, MPDConnectionError>
	{
		if let tracks = album.tracks
		{
			for track in tracks
			{
				if mpd_run_add(connection, track.uri) == false
				{
					return .failure(MPDConnectionError(.addError, getLastErrorMessageForConnection()))
				}
			}
		}
		else
		{
			let result = getTracksForAlbum(album)
			switch result
			{
				case .failure(let error):
					return .failure(error)
				case.success(let tracks):
					for track in tracks
					{
						if mpd_run_add(connection, track.uri) == false
						{
							return .failure(MPDConnectionError(.addError, getLastErrorMessageForConnection()))
						}
					}
			}
		}
		return .success(true)
	}

	func togglePause() -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_toggle_pause(connection)
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.togglePlayPauseError, getLastErrorMessageForConnection()))
	}

	func nextTrack() -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_next(connection)
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.changeTrackError, getLastErrorMessageForConnection()))
	}

	func previousTrack() -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_previous(connection)
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.changeTrackError, getLastErrorMessageForConnection()))
	}

	func setRandom(_ random: Bool) -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_random(connection, random)
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.toggleRandomError, getLastErrorMessageForConnection()))
	}

	func setRepeat(_ loop: Bool) -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_repeat(connection, loop)
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.toggleRepeatError, getLastErrorMessageForConnection()))
	}

	func setTrackPosition(_ position: Int, trackPosition: UInt32) -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_seek_pos(connection, trackPosition, UInt32(position))
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.changePositionError, getLastErrorMessageForConnection()))
	}

	func setVolume(_ volume: UInt32) -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_set_volume(connection, volume)
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.changePositionError, getLastErrorMessageForConnection()))
	}

	func getVolume() -> Result<Int, MPDConnectionError>
	{
		let result = getStatus()
		switch result
		{
			case .failure(let error):
				return .failure(error)
			case .success(let status):
				return .success(Int(mpd_status_get_volume(status)))
		}
	}

	// MARK: - Player status
	func getStatus() -> Result<OpaquePointer, MPDConnectionError>
	{
		if let ret = mpd_run_status(connection)
		{
			return .success(ret)
		}
		else
		{
			return .failure(MPDConnectionError(.getStatusError, getLastErrorMessageForConnection()))
		}
	}

	func getPlayerInfos() throws -> Result<[String : Any]?, MPDConnectionError>
	{
		guard let song = mpd_run_current_song(connection) else
		{
			return .success(nil)
		}

		let tmpRet = getStatus()
		switch tmpRet
		{
			case .failure(let error):
				return .failure(error)
			case.success(let status):
				guard let track = trackFromMPDSongObject(song) else
				{
					return .failure(MPDConnectionError(.getStatusError, getLastErrorMessageForConnection()))
				}
				let state = statusFromMPDStateObject(mpd_status_get_state(status)).rawValue
				let elapsed = mpd_status_get_elapsed_time(status)
				let volume = Int(mpd_status_get_volume(status))
				guard let tmpAlbumName = mpd_song_get_tag(song, MPD_TAG_ALBUM, 0) else
				{
					return .failure(MPDConnectionError(.getStatusError, getLastErrorMessageForConnection()))
				}
				let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmpAlbumName), count: Int(strlen(tmpAlbumName)), deallocator: .none)
				if let name = String(data: dataTemp, encoding: .utf8)
				{
					if let album = delegate?.albumMatchingName(name)
					{
						return .success([PLAYER_TRACK_KEY : track, PLAYER_ALBUM_KEY : album, PLAYER_ELAPSED_KEY : Int(elapsed), PLAYER_STATUS_KEY : state, PLAYER_VOLUME_KEY : volume])
					}
				}

				return .failure(MPDConnectionError(.getStatusError, Message(content: "No matching album found.", type: .error)))
		}
	}

	// MARK: - Outputs
	func getAvailableOutputs() -> Result<[AudioOutput], MPDConnectionError>
	{
		if mpd_send_outputs(connection) == false
		{
			return .failure(MPDConnectionError(.getOutputsError, getLastErrorMessageForConnection()))
		}

		var ret = [AudioOutput]()
		var output = mpd_recv_output(connection)
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
			output = mpd_recv_output(connection)
		}

		return .success(ret)
	}

	func toggleOutput(_ output: AudioOutput) -> Result<Bool, MPDConnectionError>
	{
		let ret = output.enabled ? mpd_run_disable_output(connection, UInt32(output.id)) : mpd_run_enable_output(connection, UInt32(output.id))
		if ret
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.toggleOutput, getLastErrorMessageForConnection()))
	}

	// Database
	func updateDatabase() -> Result<Bool, MPDConnectionError>
	{
		let ret = mpd_run_update(connection, nil)
		if ret > 0
		{
			return .success(true)
		}
		return .failure(MPDConnectionError(.updateError, getLastErrorMessageForConnection()))
	}

	// MARK: - Private
	private func getLastErrorMessageForConnection() -> Message
	{
		if connection == nil
		{
			return Message(content: "No connection to MPD", type: .error)
		}

		if mpd_connection_get_error(connection) == MPD_ERROR_SUCCESS
		{
			return Message(content: "no error", type: .success)
		}

		if let errorMessage = mpd_connection_get_error_message(connection)
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

	private func mpdTagMatchingMusicalEntityType(_ type: MusicalEntityType) -> mpd_tag_type
	{
		switch type
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
			default:
				return MPD_TAG_UNKNOWN
		}
	}

	public static func isValid(_ connection: MPDConnection?) -> Bool
	{
		if let cnn = connection
		{
			return cnn.isConnected
		}
		return false
	}
}
