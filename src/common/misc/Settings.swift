import UIKit


final class Settings
{
	// Preferences keys
	enum keys
	{
		static let servers = "servers"
		static let selectedServerName = "selectedServerName"
		static let coversDirectory = "coversDirectory"
		static let coversSize = "coversSize"
		static let coversSize_TVOS = "coversSize_TVOS"
		static let pref_fuzzySearch = "pref_fuzzySearch"
		static let pref_shakeToPlayRandom = "pref_shakeToPlayRandom"
		static let pref_enableLogging = "pref_enableLogging"
		static let pref_displayType = "pref_displayType"
		static let pref_layoutLibraryCollection = "pref_layoutLibraryCollection"
		static let pref_layoutArtistsCollection = "pref_layoutArtistsCollection"
		static let pref_layoutAlbumsCollection = "pref_layoutAlbumsCollection"
		static let mpd_repeat = "mpd_repeat"
		static let mpd_shuffle = "mpd_shuffle"
	}
	// Singletion instance
	static let shared = Settings()
	// Prefs
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

	func set(_ value: String, forKey: String)
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
				Settings.keys.selectedServerName : "",
				Settings.keys.coversDirectory : coversDirectoryPath,
				Settings.keys.coversSize : NSKeyedArchiver.archivedData(withRootObject: NSValue(cgSize: CGSize(width_ios, width_ios)), requiringSecureCoding: false),
				Settings.keys.coversSize_TVOS : NSKeyedArchiver.archivedData(withRootObject: NSValue(cgSize: CGSize(width_tvos, width_tvos)), requiringSecureCoding: false),
				Settings.keys.pref_fuzzySearch : false,
				Settings.keys.pref_enableLogging : false,
				Settings.keys.pref_shakeToPlayRandom : false,
				Settings.keys.pref_displayType : DisplayType.albums.rawValue,
				Settings.keys.pref_layoutLibraryCollection : true,
				Settings.keys.pref_layoutAlbumsCollection : false,
				Settings.keys.pref_layoutArtistsCollection : false,
				Settings.keys.mpd_repeat : false,
				Settings.keys.mpd_shuffle : false,
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
