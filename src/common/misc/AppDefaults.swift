import UIKit
import Defaults

let APP_GROUP_NAME = "group.shinobu.settings"
let extensionDefaults = UserDefaults(suiteName: APP_GROUP_NAME)!

extension Defaults.Keys {
	static let firstRunDate = Key<Date?>("firstRunDate", default: nil, suite: extensionDefaults)
	static let server = Key<Data?>("server", default: nil, suite: extensionDefaults)
	static let coversDirectory = Key<String>("coversDirectory", default: "covers", suite: extensionDefaults)
	static let coversSize = Key<CGFloat>("coversSize", default: 180, suite: extensionDefaults)
	static let pref_fuzzySearch = Key<Bool>("pref_fuzzySearch", default: false, suite: extensionDefaults)
	static let pref_shakeToPlayRandom = Key<Bool>("pref_shakeToPlayRandom", default: false, suite: extensionDefaults)
	static let pref_browseByDirectory = Key<Bool>("pref_browseByDirectory", default: false, suite: extensionDefaults)
	static let pref_numberOfColumns = Key<Int>("pref_numberOfColumns", default: 2, suite: extensionDefaults)
	static let pref_tintColor = Key<TintColorType>("pref_tintColor", default: TintColorType.orange, suite: extensionDefaults)
	static let pref_usePrettyDB = Key<Bool>("pref_usePrettyDB", default: true, suite: extensionDefaults)
	static let pref_contextualSearch = Key<Bool>("pref_contextualSearch", default: false, suite: extensionDefaults)
	static let lastTypeLibrary = Key<MusicalEntityType>("lastTypeLibrary", default: MusicalEntityType.albums, suite: extensionDefaults)
	static let lastTypeGenre = Key<MusicalEntityType>("lastTypeGenre", default: MusicalEntityType.albums, suite: extensionDefaults)
}

extension Defaults {
	static let isFirstRun: Bool = {
		if Defaults[.firstRunDate] != nil {
			return false
		}
		Defaults[.firstRunDate] = Date()
		return true
	}()
}
