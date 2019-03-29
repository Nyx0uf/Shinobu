import Foundation


enum MusicalEntityType : Int
{
	case albums
	case artists
	case albumsartists
	case genres
	case playlists
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
