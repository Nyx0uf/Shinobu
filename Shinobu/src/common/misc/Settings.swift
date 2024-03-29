import UIKit
import Defaults

let APP_GROUP_NAME = "group.fr.whine.shinobu.app"
let extensionDefaults = UserDefaults(suiteName: APP_GROUP_NAME)!

extension Defaults.Keys {
	static let isFirstRun = Key<Bool>("isFirstRun", default: true, suite: extensionDefaults)
	static let server = Key<Data>("server", default: createInitialServer(), suite: extensionDefaults)
	static let coversDirectory = Key<String>("coversDirectory", default: "covers", suite: extensionDefaults)
	static let coversSize = Key<CGFloat>("coversSize", default: 180, suite: extensionDefaults)
	static let pref_fuzzySearch = Key<Bool>("pref_fuzzySearch", default: false, suite: extensionDefaults)
	static let pref_shakeToPlayRandom = Key<Bool>("pref_shakeToPlayRandom", default: false, suite: extensionDefaults)
	static let pref_browseByDirectory = Key<Bool>("pref_browseByDirectory", default: false, suite: extensionDefaults)
	static let pref_numberOfColumns = Key<Int>("pref_numberOfColumns", default: UIDevice.current.isPad() ? 4 : 2, suite: extensionDefaults)
	static let lastTypeLibrary = Key<MusicalEntityType>("lastTypeLibrary", default: MusicalEntityType.albums, suite: extensionDefaults)
	static let lastTypeGenre = Key<MusicalEntityType>("lastTypeGenre", default: MusicalEntityType.albums, suite: extensionDefaults)
}

fileprivate func createInitialServer() -> Data {
	let server = MPDServer(id: 0, name: "", hostname: "", port: 6600)

	let encoder = JSONEncoder()
	do {
		let serverAsData = try encoder.encode(server)
		return serverAsData
	} catch {
		// Should not happen
		fatalError("server error")
	}
}
