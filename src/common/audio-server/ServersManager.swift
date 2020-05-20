import Foundation

final class ServersManager {
	// MARK: - Public
	func getServersList() -> [ShinobuServer] {
		let decoder = JSONDecoder()
		var servers = [ShinobuServer]()
		if let serversAsData = AppDefaults.servers {
			do {
				servers = try decoder.decode([ShinobuServer].self, from: serversAsData)
			} catch let error {
				Logger.shared.log(type: .information, message: "Failed to decode servers: \(error.localizedDescription)")
			}
		} else {
			Logger.shared.log(type: .information, message: "No servers registered yet")
		}

		return servers
	}

	func handleServer(_ server: ShinobuServer) {
		var servers = getServersList()
		let exist = servers.firstIndex { $0 == server }
		var serverToAdd = server
		if let index = exist {
			// Ensure unique name
			for server in servers {
				if server != serverToAdd && server.name == serverToAdd.name {
					serverToAdd.name += "-\(String.random(length: 4))"
				}
			}
			servers[index] = serverToAdd
		} else {
			// Ensure unique name
			for server in servers where server.name == serverToAdd.name {
				serverToAdd.name += "-\(String.random(length: 4))"
			}
			servers.append(serverToAdd)
		}

		let encoder = JSONEncoder()
		do {
			let newServersAsData = try encoder.encode(servers)
			AppDefaults.servers = newServersAsData
		} catch let error {
			Logger.shared.log(error: error)
		}
	}

	func removeServerByName(_ serverNameToRemove: String) -> Bool {
		var ret = true
		do {
			var shinobuServers = getServersList()
			if let idx = shinobuServers.firstIndex(where: { $0.name == serverNameToRemove }) {
				shinobuServers.remove(at: idx)

				if getSelectedServerName() == serverNameToRemove {
					setSelectedServerName("")
				}

				let encoder = JSONEncoder()
				let newServersAsData = try encoder.encode(shinobuServers)
				AppDefaults.servers = newServersAsData
			} else {
				ret = false
			}
		} catch let error {
			Logger.shared.log(type: .error, message: error.localizedDescription)
			ret = false
		}
		return ret
	}

	func setSelectedServerName(_ serverName: String) {
		AppDefaults.selectedServerName = serverName
	}

	func getSelectedServerName() -> String {
		if let name = AppDefaults.selectedServerName {
			return name
		}
		return ""
	}

	func getSelectedServer() -> ShinobuServer? {
		let name = getSelectedServerName()
		if String.isNullOrWhiteSpace(name) {
			return nil
		}

		let servers = getServersList()
		return servers.filter { $0.name == name }.first
	}
}
