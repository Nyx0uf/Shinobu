import Foundation


struct MusicalEntityType : OptionSet
{
	let rawValue: Int

	static let albums = MusicalEntityType(rawValue: 1 << 0)
	static let artists = MusicalEntityType(rawValue: 1 << 1)
	static let albumsartists = MusicalEntityType(rawValue: 1 << 2)
	static let genres = MusicalEntityType(rawValue: 1 << 3)
	static let playlists = MusicalEntityType(rawValue: 1 << 4)
	/*case albums
	case artists
	case albumsartists
	case genres
	case playlists*/
}


class MusicalEntity : Hashable
{
	// MARK: - Public properties
	// Name
	var name: String

	// MARK: - Initializers
	init(name: String)
	{
		self.name = name
	}

	// MARK: - Hashable
	public func hash(into hasher: inout Hasher)
	{
		hasher.combine(name)
	}
}

// MARK: - Equatable
extension MusicalEntity : Equatable
{
	static func ==(lhs: MusicalEntity, rhs: MusicalEntity) -> Bool
	{
		return (lhs.name == rhs.name)
	}
}
