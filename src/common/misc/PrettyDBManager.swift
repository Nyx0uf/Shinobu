import Foundation

final class PrettyDBManager {
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

		guard let resp = response, resp.statusCode == 200 else {
			return []
		}

		if error != nil {
			return []
		}

		guard let json = data else {
			return []
		}

		do {
			let data2 = try JSONSerialization.jsonObject(with: json, options: [])
			guard let albs = data2 as? [[String: String]] else {
				return []
			}

			var albums = [Album]()
			for album in albs {
				guard let name = album["name"], let path = album["path"] else { continue }
				let year = album["year"] ?? ""
				let artist = album["artist"] ?? ""
				let genre = album["genre"] ?? ""
				let alo = Album(name: name, path: path, artist: artist, genre: genre, year: year)
				albums.append(alo)
			}

			return albums
		} catch {
			return []
		}
	}
}
