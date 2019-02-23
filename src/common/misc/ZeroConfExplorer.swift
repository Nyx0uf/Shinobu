import Foundation


protocol ZeroConfExplorerDelegate : class
{
	func didFindServer(_ server: MPDServer)
}


final class ZeroConfExplorer : NSObject
{
	// MARK: - Public properties
	// Is searching flag
	private(set) var isSearching = false
	// Services list
	private(set) var services = [NetService : MPDServer]()
	// Delegate
	weak var delegate: ZeroConfExplorerDelegate?

	// MARK: - Private properties
	// Zeroconf browser
	private var _serviceBrowser: NetServiceBrowser!

	// MARK: - Initializer
	override init()
	{
		super.init()

		self._serviceBrowser = NetServiceBrowser()
		self._serviceBrowser.delegate = self
	}

	deinit
	{
		self._serviceBrowser.delegate = nil
		self._serviceBrowser = nil
	}

	// MARK: - Public
	func searchForServices(type: String, domain: String = "")
	{
		if isSearching
		{
			stopSearch()
		}

		services.removeAll()
		_serviceBrowser.searchForServices(ofType: type, inDomain: domain)
	}

	func stopSearch()
	{
		_serviceBrowser.stop()
	}

	// MARK: - Private
	private func resolvZeroconfService(service: NetService)
	{
		if let server = services[service] , isResolved(server)
		{
			return
		}

		service.delegate = self
		service.resolve(withTimeout: 5)
	}

	private func isResolved(_ server: MPDServer) -> Bool
	{
		return String.isNullOrWhiteSpace(server.hostname) == false && server.port != 0
	}
}

// MARK: - NetServiceBrowserDelegate
extension ZeroConfExplorer : NetServiceBrowserDelegate
{
	func netServiceBrowserWillSearch(_ browser: NetServiceBrowser)
	{
		isSearching = true
	}

	func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser)
	{
		isSearching = false
	}

	func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber])
	{
		Logger.shared.log(type: .error, message: "ZeroConf didNotSearch : \(errorDict)")
	}

	func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool)
	{
		services[service] = MPDServer(name: service.name, hostname: "", port: 0)
		resolvZeroconfService(service: service)
	}

	func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool)
	{
		services[service] = nil
	}
}

// MARK: - NetServiceDelegate
extension ZeroConfExplorer : NetServiceDelegate
{
	func netServiceDidResolveAddress(_ sender: NetService)
	{
		guard let addresses = sender.addresses else {return}

		var found = false
		var tmpIP = ""
		for addressBytes in addresses where found == false
		{
			let inetAddressPointer = (addressBytes as NSData).bytes.assumingMemoryBound(to: sockaddr_in.self)
			var inetAddress = inetAddressPointer.pointee
			if inetAddress.sin_family == sa_family_t(AF_INET)
			{
				let ipStringBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
				let ipString = inet_ntop(Int32(inetAddress.sin_family), &inetAddress.sin_addr, ipStringBuffer, UInt32(INET6_ADDRSTRLEN))
				if let ip = String(validatingUTF8: ipString!)
				{
					tmpIP = ip
					found = true
				}
				//ipStringBuffer.deallocate(capacity: Int(INET6_ADDRSTRLEN))
				ipStringBuffer.deallocate()
			}
			else if inetAddress.sin_family == sa_family_t(AF_INET6)
			{
				let inetAddressPointer6 = (addressBytes as NSData).bytes.assumingMemoryBound(to: sockaddr_in6.self)
				var inetAddress6 = inetAddressPointer6.pointee
				let ipStringBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
				let ipString = inet_ntop(Int32(inetAddress6.sin6_family), &inetAddress6.sin6_addr, ipStringBuffer, UInt32(INET6_ADDRSTRLEN))
				if let ip = String(validatingUTF8: ipString!)
				{
					tmpIP = ip
					found = true
				}
				ipStringBuffer.deallocate()
				//ipStringBuffer.deallocate(capacity: Int(INET6_ADDRSTRLEN))
			}

			if found
			{
				let server = MPDServer(name: sender.name, hostname: tmpIP, port: UInt16(sender.port))
				services[sender] = server
				delegate?.didFindServer(server)
			}
		}
	}

	func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber])
	{
	}

	func netServiceDidStop(_ sender: NetService)
	{
	}
}
