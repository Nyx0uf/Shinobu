import UIKit

struct AppDefaults {
	fileprivate static var shared: UserDefaults = {
		return UserDefaults(suiteName: "group.shinobu.settings")!
	}()

	private struct Key {
		static let firstRunDate = "firstRunDate"
		static let servers = "servers"
		static let selectedServerName = "selectedServerName"
		static let coversDirectory = "coversDirectory"
		static let coversSize = "coversSize"
		static let pref_fuzzySearch = "pref_fuzzySearch"
		static let pref_shakeToPlayRandom = "pref_shakeToPlayRandom"
		static let pref_browseByDirectory = "pref_browseByDirectory"
		static let pref_numberOfColumns = "pref_numberOfColumns"
		static let pref_tintColor = "pref_tintColor"
		static let pref_usePrettyDB = "pref_usePrettyDB"
		static let pref_contextualSearch = "pref_contextualSearch"
		static let lastTypeLibrary = "lastTypeLibrary"
		static let lastTypeGenre = "lastTypeGenre"
	}

	static let isFirstRun: Bool = {
		if AppDefaults.shared.object(forKey: Key.firstRunDate) != nil {
			return false
		}
		firstRunDate = Date()
		return true
	}()

	static var servers: Data? {
		get {
			return data(for: Key.servers)
		}
		set {
			setData(for: Key.servers, newValue)
		}
	}

	static var selectedServerName: String? {
		get {
			return string(for: Key.selectedServerName)
		}
		set {
			setString(for: Key.selectedServerName, newValue)
		}
	}

	static var coversDirectory: String {
		get {
			return string(for: Key.coversDirectory) ?? "covers"
		}
		set {
			setString(for: Key.coversDirectory, newValue)
		}
	}

	static var coversSize: CGFloat {
		get {
			return cgfloat(for: Key.coversSize)
		}
		set {
			setCGFloat(for: Key.coversSize, newValue)
		}
	}

	static var pref_fuzzySearch: Bool {
		get {
			return bool(for: Key.pref_fuzzySearch)
		}
		set {
			setBool(for: Key.pref_fuzzySearch, newValue)
		}
	}

	static var pref_shakeToPlayRandom: Bool {
		get {
			return bool(for: Key.pref_shakeToPlayRandom)
		}
		set {
			setBool(for: Key.pref_shakeToPlayRandom, newValue)
		}
	}

	static var pref_browseByDirectory: Bool {
		get {
			return bool(for: Key.pref_browseByDirectory)
		}
		set {
			setBool(for: Key.pref_browseByDirectory, newValue)
		}
	}

	static var pref_numberOfColumns: Int {
		get {
			return int(for: Key.pref_numberOfColumns)
		}
		set {
			setInt(for: Key.pref_numberOfColumns, newValue)
		}
	}

	static var pref_tintColor: TintColorType {
		get {
			return tintColorType(for: Key.pref_tintColor)
		}
		set {
			setTintColorType(for: Key.pref_tintColor, newValue)
		}
	}

	static var pref_usePrettyDB: Bool {
		get {
			return bool(for: Key.pref_usePrettyDB)
		}
		set {
			setBool(for: Key.pref_usePrettyDB, newValue)
		}
	}

	static var pref_contextualSearch: Bool {
		get {
			return bool(for: Key.pref_contextualSearch)
		}
		set {
			setBool(for: Key.pref_contextualSearch, newValue)
		}
	}

	static var lastTypeLibrary: MusicalEntityType {
		get {
			return musicalEntityType(for: Key.lastTypeLibrary)
		}
		set {
			setMusicalEntityType(for: Key.lastTypeLibrary, newValue)
		}
	}

	static var lastTypeGenre: MusicalEntityType {
		get {
			return musicalEntityType(for: Key.lastTypeGenre)
		}
		set {
			setMusicalEntityType(for: Key.lastTypeGenre, newValue)
		}
	}

	static func registerDefaults() {
		let defaultsValues: [String: Any] = [
			Key.selectedServerName: "",
			Key.coversDirectory: "",
			Key.coversSize: Double(180),
			Key.lastTypeLibrary: MusicalEntityType.albums.rawValue,
			Key.lastTypeGenre: MusicalEntityType.albums.rawValue,
			Key.pref_fuzzySearch: false,
			Key.pref_shakeToPlayRandom: false,
			Key.pref_browseByDirectory: false,
			Key.pref_numberOfColumns: 2,
			Key.pref_tintColor: TintColorType.orange.rawValue,
			Key.pref_usePrettyDB: true,
			Key.pref_contextualSearch: false
		]

		AppDefaults.shared.register(defaults: defaultsValues)
	}
}

private extension AppDefaults {
	static var firstRunDate: Date? {
		get {
			return date(for: Key.firstRunDate)
		}
		set {
			setDate(for: Key.firstRunDate, newValue)
		}
	}

	static func bool(for key: String) -> Bool {
		return AppDefaults.shared.bool(forKey: key)
	}

	static func setBool(for key: String, _ flag: Bool) {
		AppDefaults.shared.set(flag, forKey: key)
	}

	static func cgfloat(for key: String) -> CGFloat {
		return CGFloat(AppDefaults.shared.double(forKey: key))
	}

	static func setCGFloat(for key: String, _ x: CGFloat) {
		AppDefaults.shared.set(Double(x), forKey: key)
	}

	static func data(for key: String) -> Data? {
		return AppDefaults.shared.data(forKey: key)
	}

	static func setData(for key: String, _ data: Data?) {
		AppDefaults.shared.set(data, forKey: key)
	}

	static func date(for key: String) -> Date? {
		return AppDefaults.shared.object(forKey: key) as? Date
	}

	static func setDate(for key: String, _ date: Date?) {
		AppDefaults.shared.set(date, forKey: key)
	}

	static func int(for key: String) -> Int {
		return AppDefaults.shared.integer(forKey: key)
	}

	static func setInt(for key: String, _ x: Int) {
		AppDefaults.shared.set(x, forKey: key)
	}

	static func string(for key: String) -> String? {
		return UserDefaults.standard.string(forKey: key)
	}

	static func setString(for key: String, _ value: String?) {
		UserDefaults.standard.set(value, forKey: key)
	}

	// MARK: - Custom types
	static func musicalEntityType(for key: String) -> MusicalEntityType {
		let rawInt = int(for: key)
		return MusicalEntityType(rawValue: rawInt)
	}

	static func setMusicalEntityType(for key: String, _ value: MusicalEntityType) {
		setInt(for: key, value.rawValue)
	}

	static func tintColorType(for key: String) -> TintColorType {
		let rawInt = int(for: key)
		guard let val = TintColorType(rawValue: rawInt) else {
			return .blue
		}
		return val
	}

	static func setTintColorType(for key: String, _ value: TintColorType) {
		setInt(for: key, value.rawValue)
	}
}
