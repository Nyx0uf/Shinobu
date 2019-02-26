import UIKit


public let kNYXPrefCoversDirectory = "app-covers-directory"
public let kNYXPrefCoversSize = "app-covers-size"
public let kNYXPrefCoversSizeTVOS = "app-covers-size-tvos"
public let kNYXPrefDisplayType = "app-display-type"
public let kNYXPrefFuzzySearch = "app-search-fuzzy"
public let kNYXPrefShakeToPlayRandomAlbum = "app-shake-to-play"
public let kNYXPrefMPDServer = "mpd-server2"
public let kNYXPrefMPDShuffle = "mpd-shuffle"
public let kNYXPrefMPDRepeat = "mpd-repeat"
public let kNYXPrefWEBServer = "web-server2"
public let kNYXPrefEnableLogging = "app-enable-logging"
public let kNYXPrefLastKnownVersion = "app-last-version"
public let kNYXPrefLayoutLibraryCollection = "app-layout-library-collection"
public let kNYXPrefLayoutArtistsCollection = "app-layout-artists-collection"
public let kNYXPrefLayoutAlbumsCollection = "app-layout-albums-collection"


final class Settings
{
	enum keys
	{
		static let servers = "servers"
	}
	// Singletion instance
	static let shared = Settings()
	//
	private var defaults: UserDefaults

	// MARK: - Initializers
	init()
	{
		self.defaults = UserDefaults(suiteName: "group.shinobu.settings")!
	}

	// MARK: - Public
	func initialize()
	{
		_registerDefaultPreferences()
	}

	func synchronize()
	{
		defaults.synchronize()
	}

	func bool(forKey: String) -> Bool
	{
		return defaults.bool(forKey: forKey)
	}

	func data(forKey: String) -> Data?
	{
		return defaults.data(forKey: forKey)
	}

	func integer(forKey: String) -> Int
	{
		return defaults.integer(forKey: forKey)
	}

	func string(forKey: String) -> String?
	{
		return defaults.string(forKey: forKey)
	}

	func set(_ value: Bool, forKey: String)
	{
		defaults.set(value, forKey: forKey)
	}

	func set(_ value: Data, forKey: String)
	{
		defaults.set(value, forKey: forKey)
	}

	func set(_ value: Int, forKey: String)
	{
		defaults.set(value, forKey: forKey)
	}

	func removeObject(forKey: String)
	{
		defaults.removeObject(forKey: forKey)
	}

	// MARK: - Private
	private func _registerDefaultPreferences()
	{
		do
		{
			let coversDirectoryPath = "covers"
			let columns_ios = CGFloat(3)
			let width_ios = ceil((UIScreen.main.bounds.width / columns_ios) - (2 * 10))
			let columns_tvos = CGFloat(5)
			let width_tvos = ceil(((UIScreen.main.bounds.width * (2.0 / 3.0)) / columns_tvos) - (2 * 50))
			let defaultsValues: [String: Any] = try [
				kNYXPrefCoversDirectory : coversDirectoryPath,
				kNYXPrefCoversSize : NSKeyedArchiver.archivedData(withRootObject: NSValue(cgSize: CGSize(width_ios, width_ios)), requiringSecureCoding: false),
				kNYXPrefCoversSizeTVOS : NSKeyedArchiver.archivedData(withRootObject: NSValue(cgSize: CGSize(width_tvos, width_tvos)), requiringSecureCoding: false),
				kNYXPrefFuzzySearch : false,
				kNYXPrefMPDShuffle : false,
				kNYXPrefMPDRepeat : false,
				kNYXPrefDisplayType : DisplayType.albums.rawValue,
				kNYXPrefShakeToPlayRandomAlbum : false,
				kNYXPrefEnableLogging : false,
				kNYXPrefLayoutLibraryCollection : true,
				kNYXPrefLayoutAlbumsCollection : false,
				kNYXPrefLayoutArtistsCollection : false,
				kNYXPrefLastKnownVersion : Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
			]

			let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!

			try FileManager.default.createDirectory(at: cachesDirectoryURL.appendingPathComponent(coversDirectoryPath), withIntermediateDirectories: true, attributes: nil)
			
			defaults.register(defaults: defaultsValues)
			defaults.synchronize()
		}
		catch let error
		{
			Logger.shared.log(error: error)
			fatalError("Failed to create covers directory")
		}
	}
}
