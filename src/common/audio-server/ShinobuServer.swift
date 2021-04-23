import Foundation

struct ShinobuServer: Codable, Equatable {
	// Coding keys
	private enum ShinobuServerCodingKeys: String, CodingKey {
		case name
		case mpd
		case covers
	}

	// MARK: - Public properties
	// Server name
	var name: String
	//  MPD server
	var mpd: MPDServer
	// Covers server
	var covers: CoverServer?

	// MARK: - Initializers
	init(name: String, mpd: MPDServer) {
		self.name = name
		self.mpd = mpd
		self.covers = nil
	}

	init(name: String, mpd: MPDServer, covers: CoverServer) {
		self.name = name
		self.mpd = mpd
		self.covers = covers
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: ShinobuServerCodingKeys.self)
		let na = try values.decode(String.self, forKey: .name)
		let mp = try values.decode(MPDServer.self, forKey: .mpd)
		let co = try values.decode(CoverServer?.self, forKey: .covers)

		if co == nil {
			self.init(name: na, mpd: mp)
		} else {
			self.init(name: na, mpd: mp, covers: co!)
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: ShinobuServerCodingKeys.self)
		try container.encode(name, forKey: .name)
		try container.encode(mpd, forKey: .mpd)
		try container.encode(covers, forKey: .covers)
	}
}

extension ShinobuServer: CustomStringConvertible {
	var description: String {
		name
	}
}

func == (lhs: ShinobuServer, rhs: ShinobuServer) -> Bool {
	lhs.mpd == rhs.mpd && lhs.covers == rhs.covers
}
