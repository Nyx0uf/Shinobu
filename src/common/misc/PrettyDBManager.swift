import Foundation

struct PrettyDBAlbum
{
	let name: String
	let path: String
}

final class PrettyDBManager
{
	static func albums() -> [Album]
	{
		let serversManager = ServersManager()
		guard let server = serversManager.getSelectedServer()?.covers else
		{
			return []
		}

		guard let url = server.URLWithPath("_mpd.json") else
		{
			return []
		}

		var data: Data?
		var response: HTTPURLResponse?
		var error: Error?

		let semaphore = DispatchSemaphore(value: 0)

		let dataTask = URLSession.shared.dataTask(with: url) {
			data = $0
			response = $1 as? HTTPURLResponse
			error = $2

			semaphore.signal()
		}
		dataTask.resume()

		_ = semaphore.wait(timeout: .distantFuture)

		guard let resp = response, resp.statusCode == 200 else
		{
			return []
		}

		if let _ = error
		{
			return []
		}

		guard let json = data else
		{
			return []
		}

		let a = try! JSONSerialization.jsonObject(with: json, options: [])
		guard let alb = a as? [[String: String]] else {
			return []
		}

		var albums = [Album]()
		for album in alb
		{
			let x = Album(name: album["name"] ?? "")
			x.path = album["path"]
			albums.append(x)
		}

		return albums
	}
}
