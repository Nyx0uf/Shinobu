import Foundation
import Defaults
import Logging

final class ServerManager {
	// Logger
	private let logger = Logger(label: "logger.servermanager")

	// MARK: - Public
	func handleServer(_ server: ShinobuServer) {
		let current = getServer()
		if current == server {
			return
		}

		let encoder = JSONEncoder()
		do {
			let newServersAsData = try encoder.encode(server)
			Defaults[.server] = newServersAsData
		} catch let error {
			logger.error(Logger.Message(stringLiteral: error.localizedDescription))
		}
	}

	func getServer() -> ShinobuServer? {
		let decoder = JSONDecoder()
		var server: ShinobuServer?
		if let serversAsData = Defaults[.server] {
			do {
				server = try decoder.decode(ShinobuServer.self, from: serversAsData)
			} catch let error {
				logger.info("Failed to decode servers: \(error.localizedDescription)")
			}
		} else {
			logger.info("No servers registered yet")
		}
		return server
	}
}
