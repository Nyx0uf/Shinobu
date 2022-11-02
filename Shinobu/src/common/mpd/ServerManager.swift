import Foundation
import Defaults
import Logging

final class ServerManager {
	// MARK: - Private properties
	/// Logger
	private let logger = Logger(label: "logger.servermanager")

	// MARK: - Public methods
	func handleServer(_ server: MPDServer) {
		let current = getServer()
		if current == server {
			return
		}

		let newServer = server
		if String.isNullOrWhiteSpace(newServer.name) {
			newServer.name = NYXLocalizedString("lbl_unnamed_server")
		}

		let encoder = JSONEncoder()
		do {
			let newServersAsData = try encoder.encode(newServer)
			Defaults[.server] = newServersAsData
		} catch let error {
			logger.error(Logger.Message(stringLiteral: error.localizedDescription))
		}
	}

	func getServer() -> MPDServer {
		let decoder = JSONDecoder()
		let server: MPDServer?
		do {
			server = try decoder.decode(MPDServer.self, from: Defaults[.server])
		} catch let error {
			// Should not happen
			fatalError("server configuration error \(error)")
		}

		return server!
	}
}
