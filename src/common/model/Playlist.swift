import Foundation


final class Playlist : MusicalEntity
{
	// MARK: - Public properties
	// Album tracks
	var tracks: [Track]? = nil

	// MARK: - Initializers
	override init(name: String)
	{
		super.init(name: name)
	}
}

// MARK: - Equatable
extension Playlist
{
	static func ==(lhs: Playlist, rhs: Playlist) -> Bool
	{
		return (lhs.name == rhs.name)
	}
}
