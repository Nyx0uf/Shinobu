import Foundation
import Logging

struct PrettyDBManager {
	static func albums() -> [Album] {
		let serverManager = ServerManager()
		guard let server = serverManager.getServer()?.covers else {
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
			if let err = error {
				Logger(label: "logger.prettydbmanager").error(Logger.Message(stringLiteral: err.localizedDescription))
			}
			return []
		}

		do {
			guard let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
				return []
			}

			// let start = CFAbsoluteTimeGetCurrent()
			var albums = [Album]()
			for albumJson in json {
				guard let name = albumJson["n"] as? String, let path = albumJson["p"] as? String else { continue }
				let year = albumJson["y"] as? String ?? ""
				let artist = albumJson["a"] as? String ?? ""
				let genre = albumJson["g"] as? String ?? ""
				let album = Album(name: name, path: path, artist: artist, genre: genre, year: year)
				albums.append(album)
			}
			// let end = CFAbsoluteTimeGetCurrent()
			// print("\(end - start)s")

//			var albums = [Album]()
//			var lock = os_unfair_lock_s()
//			_ = DispatchQueue.global(qos: .userInitiated)
//			DispatchQueue.concurrentPerform(iterations: json.count) { idx in
//				let albumJson = json[idx]
//				guard let name = albumJson["n"] as? String, let path = albumJson["p"] as? String else { return }
//				let year = albumJson["y"] as? String ?? ""
//				let artist = albumJson["a"] as? String ?? ""
//				let genre = albumJson["g"] as? String ?? ""
//				let album = Album(name: name, path: path, artist: artist, genre: genre, year: year)
//				os_unfair_lock_lock(&lock)
//				albums.append(album)
//				os_unfair_lock_unlock(&lock)
//			}

			return albums
		} catch {
			return []
		}
	}
}
