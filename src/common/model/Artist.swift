import Foundation


final class Artist: MusicalEntity
{
	// MARK: - Public properties
	// Albums list reference
	var albums = [Album]()

	// MARK: - Initializers
	override init(name: String)
	{
		super.init(name: name)
	}
}

extension Artist: CustomStringConvertible
{
	var description: String
	{
		return "Name: <\(name)>\nNumber of albums: <\(albums.count)>"
	}
}

// MARK: - Equatable
extension Artist
{
	static func ==(lhs: Artist, rhs: Artist) -> Bool
	{
		return (lhs.name == rhs.name)
	}
}
