import Foundation

struct PrettyDBManager {
	static func albums() -> [Album] {
		let serversManager = ServersManager()
		guard let server = serversManager.getSelectedServer()?.covers else {
			return []
		}

		guard let url = server.URLWithPath("_mpd.json") else {
			return []
		}

		var data: Data?
		var response: HTTPURLResponse?
		var error: Error?

		let semaphore = DispatchSemaphore(value: 0)

		let config = URLSessionConfiguration.default
		config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
		config.urlCache = nil
		let session = URLSession.init(configuration: config)

		let dataTask = session.dataTask(with: url) {
			data = $0
			response = $1 as? HTTPURLResponse
			error = $2

			semaphore.signal()
		}
		dataTask.resume()

		_ = semaphore.wait(timeout: .distantFuture)

		guard let resp = response, resp.statusCode == 200, let jsonData = data else {
			Logger.shared.log(error: error!)
			return []
		}

		do {
			let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
			guard let albumsJson = json as? [[String: String]] else {
				return []
			}

			var albums = [Album]()
			for albumJson in albumsJson {
				guard let name = albumJson["name"], let path = albumJson["path"] else { continue }
				let year = albumJson["year"] ?? ""
				let artist = albumJson["artist"] ?? ""
				let genre = albumJson["genre"] ?? ""
				let album = Album(name: name, path: path, artist: artist, genre: genre, year: year)
				albums.append(album)
			}

			return albums
		} catch {
			return []
		}
	}
}
