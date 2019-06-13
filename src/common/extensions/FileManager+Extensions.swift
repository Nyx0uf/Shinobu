import Foundation

extension FileManager {
	func sizeOfDirectoryAtURL(_ directoryURL: URL) -> Int {
		var result = 0
		let properties: [URLResourceKey] = [.localizedNameKey, .creationDateKey, .localizedTypeDescriptionKey]

		do {
			let directoryContent = try contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: properties, options: [])
			for url in directoryContent {
				var isDir: ObjCBool = false
				if fileExists(atPath: url.path, isDirectory: &isDir) {
					if isDir.boolValue {
						result += sizeOfDirectoryAtURL(url)
					} else {
						result += try attributesOfItem(atPath: url.path)[.size] as! Int
					}
				}
			}
		} catch let error {
			Logger.shared.log(type: .error, message: "Can't get directory size (\(error.localizedDescription)")
		}

		return result
	}
}
