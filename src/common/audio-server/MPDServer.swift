import Foundation

struct MPDServer: Codable, Equatable {
	// Coding keys
	private enum MPDServerCodingKeys: String, CodingKey {
		case hostname
		case port
		case password
	}

	// MARK: - Public properties
	// Server IP / hostname
	let hostname: String
	// Server port
	let port: UInt16
	// Server password
	let password: String

	// MARK: - Initializers
	init(hostname: String, port: UInt16, password: String = "") {
		self.hostname = hostname
		self.port = port
		self.password = password
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: MPDServerCodingKeys.self)
		let ho = try values.decode(String.self, forKey: .hostname)
		let po = try values.decode(UInt16.self, forKey: .port)
		let pa = try values.decode(String.self, forKey: .password)

		self.init(hostname: ho, port: po, password: pa)
	}
}

extension MPDServer: CustomStringConvertible {
	var description: String {
		return "\(hostname):\(port)\n"
	}
}

func == (lhs: MPDServer, rhs: MPDServer) -> Bool {
	return (lhs.hostname == rhs.hostname && lhs.port == rhs.port && lhs.password == rhs.password)
}
