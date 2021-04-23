import Foundation
import Defaults

final class ServerManager {
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
			Logger.shared.log(error: error)
		}
	}

	func getServer() -> ShinobuServer? {
		let decoder = JSONDecoder()
		var server: ShinobuServer?
		if let serversAsData = Defaults[.server] {
			do {
				server = try decoder.decode(ShinobuServer.self, from: serversAsData)
			} catch let error {
				Logger.shared.log(type: .information, message: "Failed to decode servers: \(error.localizedDescription)")
			}
		} else {
			Logger.shared.log(type: .information, message: "No servers registered yet")
		}
		return server
	}
}
