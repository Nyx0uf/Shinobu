// Settings.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


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
	// Singletion instance
	static let shared = Settings()
	//
	private var defaults: UserDefaults

	// MARK: - Initializers
	init()
	{
		self.defaults = UserDefaults(suiteName: "group.mpdremote.settings")!
	}

	// MARK: - Public
	func initialize()
	{
		_registerDefaultPreferences()
		_iCloudInit()
	}

	func synchronize()
	{
		defaults.synchronize()
		NSUbiquitousKeyValueStore.default.synchronize()
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
		NSUbiquitousKeyValueStore.default.set(value, forKey: forKey)
	}

	func set(_ value: Data, forKey: String)
	{
		defaults.set(value, forKey: forKey)
		NSUbiquitousKeyValueStore.default.set(value, forKey: forKey)
	}

	func set(_ value: Int, forKey: String)
	{
		defaults.set(value, forKey: forKey)
		NSUbiquitousKeyValueStore.default.set(value, forKey: forKey)
	}

	func removeObject(forKey: String)
	{
		defaults.removeObject(forKey: forKey)
		NSUbiquitousKeyValueStore.default.removeObject(forKey: forKey)
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

	private func _iCloudInit()
	{
		let store = NSUbiquitousKeyValueStore.default
		NotificationCenter.default.addObserver(self, selector: #selector(_updateKVStoreItems(_:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
		store.synchronize()

		_checkIntegrity()
	}

	private func _checkIntegrity()
	{
		let keys = defaults.dictionaryRepresentation().keys
		for key in keys
		{
			let localValue = defaults.object(forKey: key)
			if NSUbiquitousKeyValueStore.default.object(forKey: key) == nil
			{
				NSUbiquitousKeyValueStore.default.set(localValue, forKey: key)
			}
		}
	}

	// MARK: - Notifications
	@objc private func _updateKVStoreItems(_ aNotification: Notification)
	{
		guard let userInfo = aNotification.userInfo else
		{
			return
		}

		guard let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as! Int? else
		{
			return
		}

		if reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange
		{
			guard let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as! [String]? else
			{
				return
			}

			for key in changedKeys
			{
				guard let value = NSUbiquitousKeyValueStore.default.object(forKey: key) else
				{
					continue
				}

				defaults.set(value, forKey: key);
			}

			defaults.synchronize()
		}
	}
}
