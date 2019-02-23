import Foundation


struct Server : Codable, Equatable
{
	// Coding keys
	private enum ServerCodingKeys: String, CodingKey
	{
		case id
		case mpd
		case covers
	}

	// MARK: - Public properties
	// UID
	let id: UUID
	//  MPD server
	var mpd: MPDServer
	// Covers server
	var covers: CoverWebServer?

	// MARK: - Initializers
	init(mpd: MPDServer)
	{
		self.id = UUID()
		self.mpd = mpd
		self.covers = nil
	}

	init(mpd: MPDServer, covers: CoverWebServer)
	{
		self.id = UUID()
		self.mpd = mpd
		self.covers = covers
	}

	init(id: UUID, mpd: MPDServer, covers: CoverWebServer)
	{
		self.id = id
		self.mpd = mpd
		self.covers = covers
	}

	init(from decoder: Decoder) throws
	{
		let values = try decoder.container(keyedBy: ServerCodingKeys.self)
		let id = try values.decode(UUID.self, forKey: .id)
		let mp = try values.decode(MPDServer.self, forKey: .mpd)
		let co = try values.decode(CoverWebServer.self, forKey: .covers)

		self.init(id: id, mpd: mp, covers: co)
	}

	public func publicDescription() -> String
	{
		return "\(self.mpd)\n"
	}
}

// MARK: - Operators
func == (lhs: Server, rhs: Server) -> Bool
{
	return (lhs.mpd == rhs.mpd && lhs.covers == rhs.covers)
}
