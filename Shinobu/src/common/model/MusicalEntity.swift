import Foundation
import Defaults

struct MusicalEntityType: OptionSet, Defaults.Serializable {
	let rawValue: Int

	static let albums = MusicalEntityType(rawValue: 1 << 0)
	static let artists = MusicalEntityType(rawValue: 1 << 1)
	static let albumsartists = MusicalEntityType(rawValue: 1 << 2)
	static let genres = MusicalEntityType(rawValue: 1 << 3)
	static let playlists = MusicalEntityType(rawValue: 1 << 4)

	func cellIdentifier() -> String {
		switch self {
		case .albums:
			return "fr.whine.shinobu.cell.musicalentity.album"
		case .artists:
			return "fr.whine.shinobu.cell.musicalentity.artist"
		case .albumsartists:
			return "fr.whine.shinobu.cell.musicalentity.albumartist"
		case .genres:
			return "fr.whine.shinobu.cell.musicalentity.genre"
		case .playlists:
			return "fr.whine.shinobu.cell.musicalentity.playlist"
		default:
			return "fr.whine.shinobu.cell.musicalentity.default"
		}
	}
}

extension MusicalEntityType: CustomStringConvertible {
	var description: String {
		switch self {
		case .albums:
			return NYXLocalizedString("lbl_albums")
		case .artists:
			return NYXLocalizedString("lbl_artists")
		case .albumsartists:
			return NYXLocalizedString("lbl_albumartists")
		case .genres:
			return NYXLocalizedString("lbl_genres")
		case .playlists:
			return NYXLocalizedString("lbl_playlists")
		default:
			return ""
		}
	}
}

extension MusicalEntityType: Codable {
}

class MusicalEntity: Hashable {
	// MARK: - Public properties
	// Name
	var name: String

	// MARK: - Initializers
	init(name: String) {
		self.name = name
	}

	// MARK: - Hashable
	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
}

extension MusicalEntity: Equatable {
	static func == (lhs: MusicalEntity, rhs: MusicalEntity) -> Bool {
		lhs.name == rhs.name
	}
}
