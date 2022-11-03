import Foundation

final class MPDServer: ObservableObject, Equatable, Identifiable, Hashable, Codable {
	private enum CodingKeys: String, CodingKey {
		case name
		case hostname
		case port
		case password
	}

	// MARK: - Public properties
	/// Only used for list display
	@Published var id: Int
	/// Server name
	@Published var name: String
	/// Server IP / hostname
	@Published var hostname: String {
		didSet {
			changed = true
		}
	}
	/// Server port
	@Published var port: UInt16 {
		didSet {
			changed = true
		}
	}
	/// Server password
	@Published var password: String
	///
	var changed = false

	// MARK: - Initializers
	init(id: Int, name: String, hostname: String, port: UInt16, password: String = "") {
		self.id = id
		self.name = name
		self.hostname = hostname
		self.port = port
		self.password = password
	}

	convenience init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let na = try values.decode(String.self, forKey: .name)
		let ho = try values.decode(String.self, forKey: .hostname)
		let po = try values.decode(UInt16.self, forKey: .port)
		let pa = try values.decode(String.self, forKey: .password)

		self.init(id: 0, name: na, hostname: ho, port: po, password: pa)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(name, forKey: .name)
		try container.encode(hostname, forKey: .hostname)
		try container.encode(port, forKey: .port)
		try container.encode(password, forKey: .password)
	}

	static func == (lhs: MPDServer, rhs: MPDServer) -> Bool {
		lhs.name == rhs.name && lhs.hostname == rhs.hostname && lhs.port == rhs.port
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(hostname)
		hasher.combine(port)
	}
}
