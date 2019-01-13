import Foundation


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
	var hashValue: Int
	{
		get
		{
			return name.hashValue
		}
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
