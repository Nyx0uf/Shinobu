import UIKit


final class Settings
{
	// Preferences keys
	public struct Key : RawRepresentable, Equatable, Hashable, Comparable
	{
		public var rawValue: String

		public static func < (lhs: Settings.Key, rhs: Settings.Key) -> Bool
		{
			return lhs.rawValue < rhs.rawValue
		}

		public init(rawValue: String)
		{
			self.rawValue = rawValue
		}

		public init(_ rawValue: String)
		{
			self.init(rawValue: rawValue)
		}
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
		registerDefaultSettings()
		createDirectories()
	}

	func bool(forKey: Settings.Key) -> Bool
	{
		return defaults.bool(forKey: forKey.rawValue)
	}

	func data(forKey: Settings.Key) -> Data?
	{
		return defaults.data(forKey: forKey.rawValue)
	}

	func integer(forKey: Settings.Key) -> Int
	{
		return defaults.integer(forKey: forKey.rawValue)
	}

	func string(forKey: Settings.Key) -> String?
	{
		return defaults.string(forKey: forKey.rawValue)
	}

	func set(_ value: Bool, forKey: Settings.Key)
	{
		defaults.set(value, forKey: forKey.rawValue)
		defaults.synchronize()
	}

	func set(_ value: Data, forKey: Settings.Key)
	{
		defaults.set(value, forKey: forKey.rawValue)
		defaults.synchronize()
	}

	func set(_ value: Int, forKey: Settings.Key)
	{
		defaults.set(value, forKey: forKey.rawValue)
		defaults.synchronize()
	}

	func set(_ value: String, forKey: Settings.Key)
	{
		defaults.set(value, forKey: forKey.rawValue)
		defaults.synchronize()
	}

	func removeObject(forKey: Settings.Key)
	{
		defaults.removeObject(forKey: forKey.rawValue)
		defaults.synchronize()
	}

	func dictionaryRepresentation() -> [String : Any]
	{
		return defaults.dictionaryRepresentation()
	}

	// MARK: - Private
	private func registerDefaultSettings()
	{
		do
		{
			let coversDirectoryPath = "covers"
			let columns_ios = 2
			let width_ios = CGFloat(180)
			let columns_tvos = CGFloat(5)
			let width_tvos = ceil(((UIScreen.main.bounds.width * (2.0 / 3.0)) / columns_tvos) - (2 * 50))
			let defaultsValues: [String: Any] = try [
				Settings.Key.selectedServerName.rawValue : "",
				Settings.Key.coversDirectory.rawValue : coversDirectoryPath,
				Settings.Key.coversSize.rawValue : NSKeyedArchiver.archivedData(withRootObject: NSValue(cgSize: CGSize(width_ios, width_ios)), requiringSecureCoding: false),
				Settings.Key.coversSize_TVOS.rawValue : NSKeyedArchiver.archivedData(withRootObject: NSValue(cgSize: CGSize(width_tvos, width_tvos)), requiringSecureCoding: false),
				Settings.Key.pref_fuzzySearch.rawValue : false,
				Settings.Key.pref_enableLogging.rawValue : false,
				Settings.Key.pref_shakeToPlayRandom.rawValue : false,
				Settings.Key.pref_numberOfColumns.rawValue : columns_ios,
				Settings.Key.mpd_repeat.rawValue : false,
				Settings.Key.mpd_shuffle.rawValue : false,
				Settings.Key.lastTypeLibrary.rawValue : MusicalEntityType.albums.rawValue,
				Settings.Key.lastTypeGenre.rawValue : MusicalEntityType.albums.rawValue,
			]
			
			defaults.register(defaults: defaultsValues)
			defaults.synchronize()
		}
		catch let error
		{
			Logger.shared.log(error: error)
			fatalError("Failed to register default preferences")
		}
	}

	public func createDirectories()
	{
		do
		{
			guard let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else
			{
				fatalError("Failed to get cache directory")
			}

			guard let coversDirectoryPath = self.string(forKey: .coversDirectory) else
			{
				fatalError("Failed to get covers directory")
			}

			try FileManager.default.createDirectory(at: cachesDirectoryURL.appendingPathComponent(coversDirectoryPath), withIntermediateDirectories: true, attributes: nil)
		}
		catch
		{
			fatalError("Failed to create covers directory")
		}
	}
}

extension Settings.Key
{
	static let servers = Settings.Key("servers")
	static let selectedServerName = Settings.Key("selectedServerName")
	static let coversDirectory = Settings.Key("coversDirectory")
	static let coversSize = Settings.Key("coversSize")
	static let coversSize_TVOS = Settings.Key("coversSize_TVOS")
	static let pref_fuzzySearch = Settings.Key("pref_fuzzySearch")
	static let pref_shakeToPlayRandom = Settings.Key("pref_shakeToPlayRandom")
	static let pref_enableLogging = Settings.Key("pref_enableLogging")
	static let pref_numberOfColumns = Settings.Key("pref_numberOfColumns")
	static let mpd_repeat = Settings.Key("mpd_repeat")
	static let mpd_shuffle = Settings.Key("mpd_shuffle")
	static let lastTypeLibrary = Settings.Key("lastTypeLibrary")
	static let lastTypeGenre = Settings.Key("lastTypeGenre")
}
