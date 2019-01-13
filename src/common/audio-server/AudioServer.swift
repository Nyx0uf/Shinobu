import Foundation


struct AudioServer : Codable, Equatable
{
	// Coding keys
	private enum AudioServerCodingKeys: String, CodingKey
	{
		case name
		case hostname
		case port
		case password
	}

	// MARK: - Public properties
	// Server name
	let name: String
	// Server IP / hostname
	let hostname: String
	// Server port
	let port: UInt16
	// Server password
	let password: String

	// MARK: - Initializers
	init(name: String, hostname: String, port: UInt16, password: String = "")
	{
		self.name = name
		self.hostname = hostname
		self.port = port
		self.password = password
	}

	init(from decoder: Decoder) throws
	{
		let values = try decoder.container(keyedBy: AudioServerCodingKeys.self)
		let na = try values.decode(String.self, forKey: .name)
		let ho = try values.decode(String.self, forKey: .hostname)
		let po = try values.decode(UInt16.self, forKey: .port)
		let pa = try values.decode(String.self, forKey: .password)

		self.init(name: na, hostname: ho, port: po, password: pa)
	}

	public func publicDescription() -> String
	{
		return "\(self.hostname)\n\(self.port)\n"
	}
}

// MARK: - Operators
func == (lhs: AudioServer, rhs: AudioServer) -> Bool
{
	return (lhs.name == rhs.name && lhs.hostname == rhs.hostname && lhs.port == rhs.port && lhs.password == rhs.password)
}
