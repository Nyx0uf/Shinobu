import Foundation


extension FileManager
{
	func sizeOfDirectoryAtURL(_ directoryURL: URL) -> Int
	{
		var result = 0
		let props = [URLResourceKey.localizedNameKey, URLResourceKey.creationDateKey, URLResourceKey.localizedTypeDescriptionKey]

		do
		{
			let ar = try self.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: props, options: [])
			for url in ar
			{
				var isDir: ObjCBool = false
				self.fileExists(atPath: url.path, isDirectory: &isDir)
				if isDir.boolValue
				{
					result += self.sizeOfDirectoryAtURL(url)
				}
				else
				{
					result += try self.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as! Int
				}
			}
		}
		catch let error
		{
			Logger.shared.log(type: .error, message: "Can't get directory size (\(error.localizedDescription)")
		}

		return result
	}
}
