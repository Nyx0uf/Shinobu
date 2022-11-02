import Foundation
import Network

final class BonjourExplorer: ObservableObject {
	// MARK: - Private properties
	/// Network browser to find bonjour services
	private var netBrowser: NWBrowser?

	// MARK: - Public properties
	/// Bonjour servers found
	@Published private(set) var services = [NWEndpoint: MPDServer]()
	/// Is currently resolving a service ?
	@Published private(set) var isResolving = false
}

// MARK: - Public
extension BonjourExplorer {
	func search() {
		netBrowser = NWBrowser(for: .bonjour(type: "_mpd._tcp.", domain: "local."), using: NWParameters())

		netBrowser?.browseResultsChangedHandler = { (results, _) in
			var id = 1
			var allServices = [NWEndpoint: MPDServer]()
			for result in results {
				switch result.endpoint {
				case .service(name: let name, _, _, _):
					let model = MPDServer(id: id, name: name, hostname: "", port: 6600, password: "")
					allServices[result.endpoint] = model
				case .hostPort:
					break
				case .unix:
					break
				case .url:
					break
				case .opaque:
					break
				@unknown default:
					break
				}

				id += 1
			}

			DispatchQueue.main.async {
				self.services = allServices
			}
		}

		netBrowser?.start(queue: .global(qos: .utility))
	}

	func resolve(mpdServerModel: MPDServer, callback: @escaping ((MPDServer) -> Void)) {
		guard isResolving == false else { return }

		// Get endpoint for mpdserver
		var endpoint: NWEndpoint?
		let model = mpdServerModel
		for (key, val) in services {
			if mpdServerModel == val {
				endpoint = key
			}
		}

		guard let endpoint else { return }

		isResolving = true
		let connection = NWConnection(to: endpoint, using: .tcp)
		connection.stateUpdateHandler = { state in
			switch state {
			case .ready:
				if let innerEndpoint = connection.currentPath?.remoteEndpoint,
				   case .hostPort(let host, let port) = innerEndpoint {
					var hostname: String?
					switch host {
					case .ipv4(let ipv4addr):
						hostname = "\(ipv4addr)".components(separatedBy: "%").first
						//print("ipv4 \(ipv4addr.interface.)")
					case .name(let name, _):
						hostname = name
						//print("name \(name)")
					case .ipv6(let ipv6addr):
						hostname = "\(ipv6addr)".components(separatedBy: "%").first
						//print("ipv6 \(ipv6addr)")
					@unknown default:
							break
					}
					DispatchQueue.main.async {
						self.isResolving = false
						model.hostname = hostname ?? ""
						model.port = port.rawValue
						callback(model)
					}
				}
			case .cancelled, .failed:
				DispatchQueue.main.async {
					self.isResolving = false
				}
			default:
				break
			}
		}
		connection.start(queue: .global(qos: .utility))
	}
}
