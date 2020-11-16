import UIKit

enum AssetSize: String {
	case small = "s"
	case medium = "m"
	case large = "l"
}

final class Album: MusicalEntity {
	// MARK: - Public properties
	// Album artist
	var artist: String = ""
	// Album genre
	var genre: String = ""
	// Album release date
	var year: String = ""
	// Album path
	var path: String?
	// Album tracks
	var tracks: [Track]?
	// Album UUID
	private(set) var uniqueIdentifier: String
	// Local URL for the cover
	private(set) lazy var localCoverURL: URL = {
		let cachesDirectoryURL = FileManager.default.cachesDirectory()
		let coversDirectoryURL = cachesDirectoryURL.appendingPathComponent(AppDefaults.coversDirectory, isDirectory: true).appendingPathComponent(self.uniqueIdentifier)
		if FileManager.default.fileExists(atPath: coversDirectoryURL.absoluteString) == false {
			try! FileManager.default.createDirectory(at: coversDirectoryURL, withIntermediateDirectories: true, attributes: nil)
		}
		return coversDirectoryURL
	}()

	// MARK: - Initializers
	override init(name: String) {
		self.uniqueIdentifier = name.sha256()
		super.init(name: name)
	}

	init(name: String, path: String, artist: String, genre: String, year: String) {
		self.artist = artist
		self.genre = genre
		self.year = year
		self.path = path
		self.uniqueIdentifier = path.sha256()
		// below also yield an unique string since an album path is unique, and is almost 10x faster
		//self.uniqueIdentifier = path.unicodeScalars.map { .init($0.value, radix: 16) } .joined()
		super.init(name: name)
	}

	// MARK: - Hashable
	override public func hash(into hasher: inout Hasher) {
		let value = name.djb2() ^ Int32(genre.hashValue) ^ Int32(year.hashValue)
		hasher.combine(value)
	}

	// MARK: - Public
	func asset(ofSize size: AssetSize) -> UIImage? {
		let assetUrl = self.localCoverURL.appendingPathComponent("\(size.rawValue).jpg")
		return UIImage.loadFromFileURL(assetUrl)
	}
}

extension Album: CustomStringConvertible {
	var description: String {
		"\nName: \(name)\nArtist: \(artist)\nGenre: \(genre)\nYear: \(year)\nPath: \(String(describing: path))\n"
	}
}

extension Album {
	static func == (lhs: Album, rhs: Album) -> Bool {
		lhs.name == rhs.name && lhs.artist == rhs.artist && lhs.year == rhs.year && lhs.genre == rhs.genre
	}
}
