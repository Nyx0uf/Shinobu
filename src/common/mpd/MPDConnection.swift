import MPDCLIENT
import UIKit
import Logging

public let PLAYER_TRACK_KEY = "track"
public let PLAYER_ALBUM_KEY = "album"
public let PLAYER_ELAPSED_KEY = "elapsed"
public let PLAYER_STATUS_KEY = "status"
public let PLAYER_VOLUME_KEY = "volume"
public let PLAYER_RANDOM_KEY = "random"
public let PLAYER_REPEAT_KEY = "repeat"

enum PlayerStatus: Int {
	case playing = 0
	case paused = 1
	case stopped = 2
	case unknown = -1
}

struct PlayerState {
	let status: PlayerStatus
	let isRandom: Bool
	let isRepeat: Bool
}

struct MPDOutput {
	let id: Int
	let name: String
	var isEnabled: Bool
}

enum MPDEntityType: Int {
	case unknown = 0
	case directory = 1
	case song = 2
	case playlist = 3
	case image = 4
}
struct MPDEntity {
	let name: String
	let type: MPDEntityType
}

protocol MPDConnectionDelegate: AnyObject {
	func albumMatchingName(_ name: String) -> Album?
}

struct MPDConnectionError: Error {
	enum Kind {
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
		case toggleStopError
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
		case getRootDirectoryListError
		case getDirectoryCoverError
	}

	let kind: Kind
	let message: Message

	init(_ kind: Kind, _ message: Message) {
		self.message = message
		self.kind = kind
	}

	public var localizedDescription: String {
		message.description
	}
}

final class MPDConnection {
	// MARK: - Public properties
	// mpd server
	let server: MPDServer
	// Delegate
	weak var delegate: MPDConnectionDelegate?
	// Connected flag
	private(set) var isConnected = false

	// MARK: - Private properties
	// mpd_connection object
	private(set) var connection: OpaquePointer?
	// Timeout in seconds
	private let timeout = UInt32(10)
	// Logger
	private let logger = Logger(label: "logger.mpdconnection")

	// MARK: - Initializers
	init(_ server: MPDServer) {
		self.server = server
	}

	deinit {
		self.disconnect()
	}

	// MARK: - Connection
	func connect() -> Result<Bool, MPDConnectionError> {
		// Open connection
		connection = mpd_connection_new(server.hostname, UInt32(server.port), timeout * 1000)
		if connection == nil {
			return .failure(MPDConnectionError(.outOfMemory, Message(content: "Out of memory", type: .error)))
		}
		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS {
			let message = getLastErrorMessageForConnection()
			connection = nil
			return .failure(MPDConnectionError(.connectionFailure, message))
		}

		// Set password if needed
		if server.password.count > 0 {
			if mpd_run_password(connection, server.password) == false {
				let message = getLastErrorMessageForConnection()
				mpd_connection_free(connection)
				connection = nil
				return .failure(MPDConnectionError(.invalidPassword, message))
			}
		}

		mpd_connection_set_keepalive(connection, true)

		isConnected = true
		return .success(true)
	}

	func disconnect() {
		if connection != nil {
			mpd_connection_free(connection)
			connection = nil
		}
		isConnected = false
	}

	// MARK: - Get infos about tracks / albums / etc…
	func getListForMusicalEntityType(_ displayType: MusicalEntityType) -> Result<[MusicalEntity], MPDConnectionError> {
		if displayType == .playlists {
			return getPlaylists()
		}

		let tagType = mpdTagMatchingMusicalEntityType(displayType)

		var list = [MusicalEntity]()
		if mpd_search_db_tags(connection, tagType) == false || mpd_search_commit(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var pair = mpd_recv_pair_tag(connection, tagType)
		while pair != nil {
			guard let value = pair?.pointee.value else {
				mpd_return_pair(connection, pair)
				pair = mpd_recv_pair_tag(connection, tagType)
				continue
			}
			let name = String(cString: value)

			switch displayType {
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

			mpd_return_pair(connection, pair)
			pair = mpd_recv_pair_tag(connection, tagType)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func getAlbumsForGenre(_ genre: Genre, firstOnly: Bool) -> Result<[Album], MPDConnectionError> {
		if mpd_search_db_tags(connection, MPD_TAG_ALBUM) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Album]()
		var pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
		while pair != nil {
			guard let value = pair?.pointee.value else {
				mpd_return_pair(connection, pair)
				pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
				continue
			}

			let name = String(cString: value)
			if let album = delegate?.albumMatchingName(name) {
				list.append(album)
			}

			mpd_return_pair(connection, pair)

			if firstOnly && list.count >= 1 {
				break
			}

			pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func getAlbumsForArtist(_ artist: Artist, isAlbumArtist: Bool = false) -> Result<[Album], MPDConnectionError> {
		if mpd_search_db_tags(connection, MPD_TAG_ALBUM) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, isAlbumArtist ? MPD_TAG_ALBUM_ARTIST : MPD_TAG_ARTIST, artist.name) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Album]()
		var pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
		while pair != nil {
			guard let value = pair?.pointee.value else {
				mpd_return_pair(connection, pair)
				pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
				continue
			}

			let name = String(cString: value)
			if let album = delegate?.albumMatchingName(name) {
				list.append(album)
			}

			mpd_return_pair(connection, pair)
			pair = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func getArtistsForGenre(_ genre: Genre, isAlbumArtist: Bool = false) -> Result<[Artist], MPDConnectionError> {
		if mpd_search_db_tags(connection, isAlbumArtist ? MPD_TAG_ALBUM_ARTIST : MPD_TAG_ARTIST) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Artist]()
		var pair = mpd_recv_pair_tag(connection, isAlbumArtist ? MPD_TAG_ALBUM_ARTIST : MPD_TAG_ARTIST)
		while pair != nil {
			guard let value = pair?.pointee.value else {
				mpd_return_pair(connection, pair)
				pair = mpd_recv_pair_tag(connection, isAlbumArtist ? MPD_TAG_ALBUM_ARTIST : MPD_TAG_ARTIST)
				continue
			}
			list.append(Artist(name: String(cString: value)))

			mpd_return_pair(connection, pair)
			pair = mpd_recv_pair_tag(connection, isAlbumArtist ? MPD_TAG_ALBUM_ARTIST : MPD_TAG_ARTIST)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func getPathForAlbum(_ album: Album) -> Result<String, MPDConnectionError> {
		if mpd_search_db_songs(connection, true) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var path = ""
		if let song = mpd_recv_song(connection) {
			if let uri = mpd_song_get_uri(song) {
				let tmp = String(cString: uri)
				path = URL(fileURLWithPath: tmp).deletingLastPathComponent().path
			}
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(path)
	}

	func getTracksForAlbum(_ album: Album) -> Result<[Track], MPDConnectionError> {
		if mpd_search_db_songs(connection, true) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if album.artist.count > 0 {
			if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM_ARTIST, album.artist) == false {
				return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
			}
		}
		if mpd_search_commit(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Track]()
		var song = mpd_recv_song(connection)
		while song != nil {
			if let track = trackFromMPDSongObject(song!) {
				list.append(track)
			}
			song = mpd_recv_song(connection)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func getTracksForPlaylist(_ playlist: Playlist) -> Result<[Track], MPDConnectionError> {
		if mpd_send_list_playlist(connection, playlist.name) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Track]()
		var entity = mpd_recv_entity(connection)
		var trackNumber = 1
		while entity != nil {
			if let song = mpd_entity_get_song(entity) {
				if let track = trackFromMPDSongObject(song) {
					track.trackNumber = trackNumber
					list.append(track)
					trackNumber += 1
				}
			}
			entity = mpd_recv_entity(connection)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		for track in list {
			if mpd_search_db_songs(connection, true) == false {
				logger.error(Logger.Message(stringLiteral: getLastErrorMessageForConnection().description))
				continue
			}
			if mpd_search_add_uri_constraint(connection, MPD_OPERATOR_DEFAULT, track.uri) == false {
				logger.error(Logger.Message(stringLiteral: getLastErrorMessageForConnection().description))
				continue
			}

			if mpd_search_commit(connection) == false {
				logger.error(Logger.Message(stringLiteral: getLastErrorMessageForConnection().description))
				continue
			}

			var song = mpd_recv_song(connection)
			while song != nil {
				if let t = trackFromMPDSongObject(song!) {
					track.artist = t.artist
					track.duration = t.duration
					track.position = t.position
					track.name = t.name
				}
				song = mpd_recv_song(connection)
			}

			if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
				return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
			}
		}

		return .success(list)
	}

	func getMetadatasForAlbum(_ album: Album) throws -> Result<[String: Any], MPDConnectionError> {
		// Find album artist
		if mpd_search_db_tags(connection, MPD_TAG_ALBUM_ARTIST) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var metadatas = [String: Any]()
		let tmpArtist = mpd_recv_pair_tag(connection, MPD_TAG_ALBUM_ARTIST)
		if tmpArtist != nil {
			if let value = tmpArtist?.pointee.value {
				metadatas["artist"] = String(cString: value)
			}
			mpd_return_pair(connection, tmpArtist)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		// Find album year
		if mpd_search_db_tags(connection, MPD_TAG_DATE) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		let tmpDate = mpd_recv_pair_tag(connection, MPD_TAG_DATE)
		if tmpDate != nil {
			if let value = tmpDate?.pointee.value {
				var l = Int(strlen(value))
				if l > 4 {
					l = 4
				}
				let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: value), count: l, deallocator: .none)
				if let year = String(data: dataTemp, encoding: .utf8) {
					metadatas["year"] = year
				} else {
					metadatas["year"] = "0000"
				}
			}

			mpd_return_pair(connection, tmpDate)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		// Find album genre
		if mpd_search_db_tags(connection, MPD_TAG_GENRE) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_add_tag_constraint(connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		if mpd_search_commit(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}
		let tmpGenre = mpd_recv_pair_tag(connection, MPD_TAG_GENRE)
		if tmpGenre != nil {
			if let value = tmpGenre?.pointee.value {
				metadatas["genre"] = String(cString: value)
			}

			mpd_return_pair(connection, tmpGenre)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			logger.error(Logger.Message(stringLiteral: getLastErrorMessageForConnection().description))
		}

		return .success(metadatas)
	}

	// MARK: - Playlists
	func getPlaylists() -> Result<[MusicalEntity], MPDConnectionError> {
		if mpd_send_list_playlists(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Playlist]()
		var playlist = mpd_recv_playlist(connection)
		while playlist != nil {
			if let tmpPath = mpd_playlist_get_path(playlist) {
				let name = String(cString: tmpPath)
				list.append(Playlist(name: name))
			}

			playlist = mpd_recv_playlist(connection)
		}

		return .success(list)
	}

	func getSongsOfCurrentQueue() -> Result<[Track], MPDConnectionError> {
		if mpd_send_list_queue_meta(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		var list = [Track]()
		var song = mpd_recv_song(connection)
		while song != nil {
			if let track = trackFromMPDSongObject(song!) {
				list.append(track)
			}
			song = mpd_recv_song(connection)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			return .failure(MPDConnectionError(.searchError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func createPlaylist(named name: String) -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_save(connection, name)
		if ret {
			mpd_run_playlist_clear(connection, name)
			return .success(true)
		}
		return .failure(MPDConnectionError(.createPlaylistError, getLastErrorMessageForConnection()))
	}

	func deletePlaylist(named name: String) -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_rm(connection, name)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.deletePlaylistError, getLastErrorMessageForConnection()))
	}

	func renamePlaylist(_ playlist: Playlist, withNewName newName: String) -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_rename(connection, playlist.name, newName)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.renamePlaylistError, getLastErrorMessageForConnection()))
	}

	func addTrack(_ track: Track, toPlaylist playlist: Playlist) -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_playlist_add(connection, playlist.name, track.uri)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.addError, getLastErrorMessageForConnection()))
	}

	func removeTrack(_ track: Track, fromPlaylist playlist: Playlist) -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_playlist_delete(connection, playlist.name, UInt32(track.trackNumber - 1))
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.removeError, getLastErrorMessageForConnection()))
	}

	// MARK: - Play / Queue
	func playAlbum(_ album: Album, shuffle: Bool, loop: Bool) -> Result<Bool, MPDConnectionError> {
		if let songs = album.tracks {
			return playTracks(songs, shuffle: shuffle, loop: loop)
		} else {
			let result = getTracksForAlbum(album)
			switch result {
			case .failure(let error):
				return .failure(error)
			case .success(let tracks):
				return playTracks(tracks, shuffle: shuffle, loop: loop)
			}
		}
	}

	func playTracks(_ tracks: [Track], shuffle: Bool, loop: Bool) -> Result<Bool, MPDConnectionError> {
		if mpd_run_clear(connection) == false {
			return .failure(MPDConnectionError(.clearError, getLastErrorMessageForConnection()))
		}

		_ = setRandom(shuffle)
		_ = setRepeat(loop)

		for track in tracks {
			if mpd_run_add(connection, track.uri) == false {
				return .failure(MPDConnectionError(.addError, getLastErrorMessageForConnection()))
			}
		}

		if mpd_run_play_pos(connection, shuffle ? UInt32.random(in: 0 ..< UInt32(tracks.count)) : 0) == false {
			return .failure(MPDConnectionError(.playError, getLastErrorMessageForConnection()))
		}

		return .success(true)
	}

	func playPlaylist(_ playlist: Playlist, shuffle: Bool, loop: Bool, position: UInt32 = 0) -> Result<Bool, MPDConnectionError> {
		if mpd_run_clear(connection) == false {
			return .failure(MPDConnectionError(.clearError, getLastErrorMessageForConnection()))
		}

		_ = setRandom(shuffle)
		_ = setRepeat(loop)

		if mpd_run_load(connection, playlist.name) == false {
			return .failure(MPDConnectionError(.loadPlaylistError, getLastErrorMessageForConnection()))
		}

		if mpd_run_play_pos(connection, UInt32(position)) == false {
			return .failure(MPDConnectionError(.playError, getLastErrorMessageForConnection()))
		}

		return .success(true)
	}

	func playTrackAtPosition(_ position: UInt32) -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_play_pos(connection, position)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.playError, getLastErrorMessageForConnection()))
	}

	func play() -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_play(connection)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.playError, getLastErrorMessageForConnection()))
	}

	func addAlbumToQueue(_ album: Album) -> Result<Bool, MPDConnectionError> {
		if let tracks = album.tracks {
			for track in tracks {
				if mpd_run_add(connection, track.uri) == false {
					return .failure(MPDConnectionError(.addError, getLastErrorMessageForConnection()))
				}
			}
		} else {
			let result = getTracksForAlbum(album)
			switch result {
			case .failure(let error):
				return .failure(error)
			case.success(let tracks):
				for track in tracks {
					if mpd_run_add(connection, track.uri) == false {
						return .failure(MPDConnectionError(.addError, getLastErrorMessageForConnection()))
					}
				}
			}
		}
		return .success(true)
	}

	func togglePause() -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_toggle_pause(connection)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.togglePlayPauseError, getLastErrorMessageForConnection()))
	}

	func stop() -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_stop(connection)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.toggleStopError, getLastErrorMessageForConnection()))
	}

	func nextTrack() -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_next(connection)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.changeTrackError, getLastErrorMessageForConnection()))
	}

	func previousTrack() -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_previous(connection)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.changeTrackError, getLastErrorMessageForConnection()))
	}

	func setRandom(_ random: Bool) -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_random(connection, random)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.toggleRandomError, getLastErrorMessageForConnection()))
	}

	func setRepeat(_ loop: Bool) -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_repeat(connection, loop)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.toggleRepeatError, getLastErrorMessageForConnection()))
	}

	func setTrackPosition(_ position: Int, trackPosition: UInt32) -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_seek_pos(connection, trackPosition, UInt32(position))
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.changePositionError, getLastErrorMessageForConnection()))
	}

	func setVolume(_ volume: UInt32) -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_set_volume(connection, volume)
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.changePositionError, getLastErrorMessageForConnection()))
	}

	func getVolume() -> Result<Int, MPDConnectionError> {
		let result = getStatus()
		switch result {
		case .failure(let error):
			return .failure(error)
		case .success(let status):
			return .success(Int(mpd_status_get_volume(status)))
		}
	}

	// MARK: - Player status
	func getStatus() -> Result<OpaquePointer, MPDConnectionError> {
		if let ret = mpd_run_status(connection) {
			return .success(ret)
		} else {
			return .failure(MPDConnectionError(.getStatusError, getLastErrorMessageForConnection()))
		}
	}

	func getPlayerInfos(matchAlbum: Bool) throws -> Result<[String: Any]?, MPDConnectionError> {
		guard let song = mpd_run_current_song(connection) else {
			return .success(nil)
		}

		let tmpRet = getStatus()
		switch tmpRet {
		case .failure(let error):
			return .failure(error)
		case.success(let status):
			guard let track = trackFromMPDSongObject(song) else {
				return .failure(MPDConnectionError(.getStatusError, getLastErrorMessageForConnection()))
			}
			let state = statusFromMPDStateObject(mpd_status_get_state(status)).rawValue
			let elapsed = mpd_status_get_elapsed_time(status)
			let volume = Int(mpd_status_get_volume(status))
			let random = mpd_status_get_random(status)
			let loop = mpd_status_get_repeat(status)
			guard let tmpAlbumName = mpd_song_get_tag(song, MPD_TAG_ALBUM, 0) else {
				return .failure(MPDConnectionError(.getStatusError, getLastErrorMessageForConnection()))
			}

			let name = String(cString: tmpAlbumName)
			if matchAlbum == true {
				if let album = delegate?.albumMatchingName(name) {
					return .success([PLAYER_TRACK_KEY: track, PLAYER_ALBUM_KEY: album, PLAYER_ELAPSED_KEY: Int(elapsed), PLAYER_STATUS_KEY: state, PLAYER_VOLUME_KEY: volume, PLAYER_REPEAT_KEY: loop, PLAYER_RANDOM_KEY: random])
				}
				return .failure(MPDConnectionError(.getStatusError, Message(content: "No matching album found.", type: .error)))
			} else {
				let album = Album(name: name)
				return .success([PLAYER_TRACK_KEY: track, PLAYER_ALBUM_KEY: album, PLAYER_ELAPSED_KEY: Int(elapsed), PLAYER_STATUS_KEY: state, PLAYER_VOLUME_KEY: volume, PLAYER_REPEAT_KEY: loop, PLAYER_RANDOM_KEY: random])
			}
		}
	}

	// MARK: - Outputs
	func getAvailableOutputs() -> Result<[MPDOutput], MPDConnectionError> {
		if mpd_send_outputs(connection) == false {
			return .failure(MPDConnectionError(.getOutputsError, getLastErrorMessageForConnection()))
		}

		var ret = [MPDOutput]()
		var output = mpd_recv_output(connection)
		while output != nil {
			guard let tmpName = mpd_output_get_name(output) else {
				mpd_output_free(output)
				continue
			}

			let id = Int(mpd_output_get_id(output))
			let name = String(cString: tmpName)

			let o = MPDOutput(id: id, name: name, isEnabled: mpd_output_get_enabled(output))
			ret.append(o)
			mpd_output_free(output)
			output = mpd_recv_output(connection)
		}

		return .success(ret)
	}

	func toggleOutput(_ output: MPDOutput) -> Result<Bool, MPDConnectionError> {
		let ret = output.isEnabled ? mpd_run_disable_output(connection, UInt32(output.id)) : mpd_run_enable_output(connection, UInt32(output.id))
		if ret {
			return .success(true)
		}
		return .failure(MPDConnectionError(.toggleOutput, getLastErrorMessageForConnection()))
	}

	// Database
	func updateDatabase() -> Result<Bool, MPDConnectionError> {
		let ret = mpd_run_update(connection, nil)
		if ret > 0 {
			return .success(true)
		}
		return .failure(MPDConnectionError(.updateError, getLastErrorMessageForConnection()))
	}

	// MARK: - Directories
	func getDirectoryListAtPath(_ path: String?) -> Result<[MPDEntity], MPDConnectionError> {
		if mpd_send_list_files(connection, path) == false {
			return .failure(MPDConnectionError(.getRootDirectoryListError, getLastErrorMessageForConnection()))
		}

		var list = [MPDEntity]()

		var entity = mpd_recv_entity(connection)
		while entity != nil {
			let ent_type = mpd_entity_get_type(entity)
			if ent_type == MPD_ENTITY_TYPE_DIRECTORY {
				if let dir = mpd_entity_get_directory(entity) {
					if let tmp = mpd_directory_get_path(dir) {
						let name = String(cString: tmp)
						list.append(MPDEntity(name: name, type: mpdEntityTypeToEntityType(ent_type, name)))
					}
				}
			} else if ent_type == MPD_ENTITY_TYPE_SONG {
				if let tmp = mpd_entity_get_song(entity) {
					if let track = trackFromMPDSongObject(tmp) {
						if track.uri != ".DS_Store" {
							list.append(MPDEntity(name: track.uri, type: mpdEntityTypeToEntityType(ent_type, track.uri)))
						}
					}
				}
			}

			entity = mpd_recv_entity(connection)
		}

		if mpd_connection_get_error(connection) != MPD_ERROR_SUCCESS || mpd_response_finish(connection) == false {
			return .failure(MPDConnectionError(.getRootDirectoryListError, getLastErrorMessageForConnection()))
		}

		return .success(list)
	}

	func getCoverForDirectoryAtPath(_ path: String) -> Result<Data, MPDConnectionError> {
		var buf: UnsafeMutablePointer<UInt8>?
		let ret = mpd_run_albumart(connection, path, &buf)
		if ret == -1 {
			return .failure(MPDConnectionError(.getDirectoryCoverError, getLastErrorMessageForConnection()))
		}

		let data = Data(bytes: buf!, count: Int(ret))
		free(buf)

		return .success(data)
	}

	// MARK: - Private
	private func getLastErrorMessageForConnection() -> Message {
		if connection == nil {
			return Message(content: "No connection to MPD", type: .error)
		}

		if mpd_connection_get_error(connection) == MPD_ERROR_SUCCESS {
			return Message(content: "no error", type: .success)
		}

		if let errorMessage = mpd_connection_get_error_message(connection) {
			let msg = String(cString: errorMessage)
			return Message(content: msg, type: .error)
		}

		return Message(content: "no error message", type: .error)
	}

	private func trackFromMPDSongObject(_ song: OpaquePointer) -> Track? {
		// URI, should always be available?
		guard let tmpURI = mpd_song_get_uri(song) else {
			return nil
		}
		let uri = String(cString: tmpURI)
		// title
		var title = ""
		if let tmpPtr = mpd_song_get_tag(song, MPD_TAG_TITLE, 0) {
			title = String(cString: tmpPtr)
		} else {
			let bla = uri.components(separatedBy: "/")
			if let filename = bla.last {
				if let f = filename.components(separatedBy: ".").first {
					title = f
				}
			}
		}
		// artist
		var artist = ""
		if let tmpPtr = mpd_song_get_tag(song, MPD_TAG_ARTIST, 0) {
			artist = String(cString: tmpPtr)
		}
		// album name
		var albumName = ""
		if let tmpPtr = mpd_song_get_tag(song, MPD_TAG_ALBUM, 0) {
			albumName = String(cString: tmpPtr)
		}
		// track number
		var trackNumber = "0"
		if let tmpPtr = mpd_song_get_tag(song, MPD_TAG_TRACK, 0) {
			if let number = String(cString: tmpPtr).components(separatedBy: "/").first {
				trackNumber = number
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
		track.albumName = albumName
		return track
	}

	private func statusFromMPDStateObject(_ state: mpd_state) -> PlayerStatus {
		switch state {
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

	private func mpdTagMatchingMusicalEntityType(_ type: MusicalEntityType) -> mpd_tag_type {
		switch type {
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

	private func mpdEntityTypeToEntityType(_ type: mpd_entity_type, _ name: String) -> MPDEntityType {
		let imgSuffixes = ["bmp", "gif", "jpeg", "jpg", "png", "tif", "tiff"]
		if imgSuffixes.contains(where: name.contains) {
			return .image
		}
		switch type {
		case MPD_ENTITY_TYPE_DIRECTORY:
			return .directory
		case MPD_ENTITY_TYPE_UNKNOWN:
			return .unknown
		case MPD_ENTITY_TYPE_PLAYLIST:
			return .playlist
		case MPD_ENTITY_TYPE_SONG:
			return .song
		default:
			return .unknown
		}
	}

	public static func isValid(_ connection: MPDConnection?) -> Bool {
		if let cnn = connection {
			return cnn.isConnected
		}
		return false
	}
}
