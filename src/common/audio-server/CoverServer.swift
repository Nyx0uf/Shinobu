import Foundation


fileprivate let SLASH = Character("/")


struct CoverServer: Codable, Equatable
{
	// Coding keys
	private enum CoverServerCodingKeys: String, CodingKey
	{
		case hostname
		case port
		case coverName
	}

	// MARK: - Public properties
	// Server IP / hostname
	let hostname: String
	// Server port
	let port: UInt16
	// Name of the cover files
	let coverName: String

	// MARK: - Initializers
	init(hostname: String, port: UInt16, coverName: String)
	{
		self.hostname = CoverServer.sanitizeHostname(hostname, port)
		self.port = port
		self.coverName = coverName
	}

	init(from decoder: Decoder) throws
	{
		let values = try decoder.container(keyedBy: CoverServerCodingKeys.self)
		let ho = try values.decode(String.self, forKey: .hostname)
		let po = try values.decode(UInt16.self, forKey: .port)
		let co = try values.decode(String.self, forKey: .coverName)

		self.init(hostname: ho, port: po, coverName: co)
	}

	// MARK: - Public
	public func coverURLForPath(_ path: String) -> URL?
	{
		if String.isNullOrWhiteSpace(hostname) || String.isNullOrWhiteSpace(coverName)
		{
			Logger.shared.log(type: .error, message: "The web server configured is invalid. hostname = \(hostname) coverName = \(coverName)")
			return nil
		}

		guard var urlComponents = URLComponents(string: hostname) else
		{
			Logger.shared.log(type: .error, message: "Unable to create URL components for <\(hostname)>")
			return nil
		}
		urlComponents.port = Int(port)

		guard let urlHostname = URL(string: hostname) else
		{
			Logger.shared.log(type: .error, message: "Unable to create URL hostname for <\(hostname)>")
			return nil
		}
		var urlPath = urlHostname.path
		if String.isNullOrWhiteSpace(urlPath) || urlPath == "/"
		{
			urlPath = path
		}
		else
		{
			if let first = urlPath.first, first != SLASH
			{
				urlPath = "/" + urlPath
			}
			urlPath = urlPath + path
		}

		guard let tmp = urlPath.last else
		{
			return nil
		}

		if tmp != "/"
		{
			urlPath = urlPath + "/" + coverName
		}
		else
		{
			urlPath = urlPath + coverName
		}

		urlComponents.path = urlPath

		guard let tmpURL = urlComponents.url else
		{
			Logger.shared.log(type: .error, message: "URL error <\(urlComponents.description)>")
			return nil
		}

		// Fix grapheme cluster encode
		var aaa = tmpURL.absoluteString.replacingOccurrences(of: "e%CC%81", with: "%C3%A9") // é
		aaa = aaa.replacingOccurrences(of: "e%CC%88", with: "%C3%AB") // ë
		aaa = aaa.replacingOccurrences(of: "a%CC%80", with: "%C3%A0") // à
		aaa = aaa.replacingOccurrences(of: "a%CC%8A", with: "%C3%A5") // å
		aaa = aaa.replacingOccurrences(of: "a%CC%81", with: "%C3%A1") // á
		aaa = aaa.replacingOccurrences(of: "c%CC%A7", with: "%C3%A7") // ç
		aaa = aaa.replacingOccurrences(of: "o%CC%88", with: "%C3%B6") // ö

		let finalURL = URL(string: aaa)

		return finalURL
	}

	public func URLWithPath(_ path: String) -> URL?
	{
		if String.isNullOrWhiteSpace(hostname) || String.isNullOrWhiteSpace(coverName)
		{
			Logger.shared.log(type: .error, message: "The web server configured is invalid. hostname = \(hostname) coverName = \(coverName)")
			return nil
		}

		guard var urlComponents = URLComponents(string: hostname) else
		{
			Logger.shared.log(type: .error, message: "Unable to create URL components for <\(hostname)>")
			return nil
		}
		urlComponents.port = Int(port)
		urlComponents.path = "\(path.first != nil && path.first! != "/" ? "/" : "")\(path)"

		guard let tmpURL = urlComponents.url else
		{
			Logger.shared.log(type: .error, message: "URL error <\(urlComponents.description)>")
			return nil
		}

		return tmpURL
	}

	// MARK: - Private
	private static func sanitizeHostname(_ hostname: String, _ port: UInt16) -> String
	{
		var h: String
		if hostname.hasPrefix("http://") || hostname.hasPrefix("https://")
		{
			h = hostname
		}
		else
		{
			if port == 443
			{
				h = "https://" + hostname
			}
			else
			{
				h = "http://" + hostname
			}
		}

		if let last = h.last, last == SLASH
		{
			h.removeLast()
		}

		return h
	}
}

extension CoverServer: CustomStringConvertible
{
	var description: String
	{
		return "\(hostname):\(port) [\(coverName)]"
	}
}

func == (lhs: CoverServer, rhs: CoverServer) -> Bool
{
	return (lhs.hostname == rhs.hostname && lhs.port == rhs.port && lhs.coverName == rhs.coverName)
}
