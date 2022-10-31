import Foundation

final class Playlist: MusicalEntity {
	// MARK: - Public properties
	// Album tracks
	var tracks: [Track]?

	// MARK: - Initializers
	override init(name: String) {
		super.init(name: name)
	}
}

extension Playlist {
	static func == (lhs: Playlist, rhs: Playlist) -> Bool {
		lhs.name == rhs.name
	}
}
