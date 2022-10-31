import Foundation
import Logging

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
			Logger(label: "logger.filemanager").error(Logger.Message(stringLiteral: error.localizedDescription))
		}

		return result
	}

	func cachesDirectory() -> URL {
		// That's ok cachesDirectory should always return smth
		// return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
		let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: APP_GROUP_NAME)!
		return containerURL
	}
}
