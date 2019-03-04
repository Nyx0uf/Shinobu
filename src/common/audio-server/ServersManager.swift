import Foundation


final class ServersManager
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = ServersManager()

	// MARK: - Initializers
	init()
	{

	}

	// MARK: - Public
	func getServersList() -> [ShinobuServer]
	{
		let decoder = JSONDecoder()
		var servers = [ShinobuServer]()
		if let serversAsData = Settings.shared.data(forKey: Settings.keys.servers)
		{
			do
			{
				servers = try decoder.decode([ShinobuServer].self, from: serversAsData)
			}
			catch let error
			{
				Logger.shared.log(type: .debug, message: "Failed to decode servers: \(error.localizedDescription)")
			}
		}
		else
		{
			Logger.shared.log(type: .debug, message: "No servers registered yet")
		}

		return servers
	}

	func handleServer(_ server: ShinobuServer)
	{
		var servers = self.getServersList()
		let exist = servers.firstIndex{$0 == server}
		var serverToAdd = server
		if let index = exist
		{
			// Ensure unique name
			for server in servers
			{
				if server != serverToAdd && server.name == serverToAdd.name
				{
					serverToAdd.name += "-\(String.random(length: 4))"
				}
			}
			servers[index] = serverToAdd
		}
		else
		{
			// Ensure unique name
			for server in servers
			{
				if server.name == serverToAdd.name
				{
					serverToAdd.name += "-\(String.random(length: 4))"
				}
			}
			servers.append(serverToAdd)
		}

		let encoder = JSONEncoder()
		do
		{
			let newServersAsData = try encoder.encode(servers)
			Settings.shared.set(newServersAsData, forKey: Settings.keys.servers)
			Settings.shared.synchronize()
		}
		catch let error
		{
			Logger.shared.log(error: error)
		}
	}

	func removeServerByName(_ serverNameToRemove: String) -> Bool
	{
		var ret = true
		do
		{
			var shinobuServers = self.getServersList()
			if let idx = shinobuServers.firstIndex(where: { $0.name == serverNameToRemove})
			{
				shinobuServers.remove(at: idx)

				if self.getSelectedServerName() == serverNameToRemove
				{
					self.setSelectedServerName("")
				}

				let encoder = JSONEncoder()
				let newServersAsData = try encoder.encode(shinobuServers)
				Settings.shared.set(newServersAsData, forKey: Settings.keys.servers)
				Settings.shared.synchronize()
			}
			else
			{
				ret = false
			}
		}
		catch let error
		{
			Logger.shared.log(type: .error, message: error.localizedDescription)
			ret = false
		}
		return ret
	}

	func setSelectedServerName(_ serverName: String)
	{
		Settings.shared.set(serverName, forKey: Settings.keys.selectedServerName)
		Settings.shared.synchronize()
	}

	func getSelectedServerName() -> String
	{
		if let name = Settings.shared.string(forKey: Settings.keys.selectedServerName)
		{
			return name
		}
		return ""
	}

	func getSelectedServer() -> ShinobuServer?
	{
		let name = self.getSelectedServerName()
		if String.isNullOrWhiteSpace(name)
		{
			return nil
		}

		let servers = self.getServersList()
		return servers.filter({$0.name == name}).first
	}
}
