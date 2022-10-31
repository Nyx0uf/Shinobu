import Foundation
import Logging

final class DownloadCoverOperation: Operation {
	// MARK: - Public properties
	/// isFinished override
	private var junk = false
	override var isFinished: Bool {
		get {
			return junk
		}
		set (newAnswer) {
			willChangeValue(forKey: "isFinished")
			junk = newAnswer
			didChangeValue(forKey: "isFinished")
		}
	}
	/// Downloaded data
	var downloadedData = Data()

	// MARK: - Private properties
	/// Album
	private let album: Album
	/// Save data flag
	private var save = true
	/// Logger
	private let logger: Logger
	/// Mpd bridge
	private let mpdBridge: MPDBridge

	// MARK: - Initializers
	init(logger: Logger, mpdBridge: MPDBridge, album: Album, save: Bool = true) {
		self.logger = logger
		self.mpdBridge = mpdBridge
		self.album = album
		self.save = save
	}

	// MARK: - Override
	override func start() {
		// Operation is cancelled, abort
		if isCancelled {
			logger.info("Operation cancelled for <\(album.name)>")
			isFinished = true
			return
		}

		// No path for album, abort
		guard let path = album.randomSongPath else {
			logger.error("No path defined for album <\(album.name)>")
			isFinished = true
			return
		}

		self.mpdBridge.getCoverForDirectoryAtPath(path) { [weak self] (data: Data) in
			guard let strongSelf = self else { return }

			strongSelf.downloadedData.append(data)

			strongSelf.isFinished = true
		}
	}

	// MARK: - Private
	override var description: String {
		"DownloadCoverOperation for <\(album.name)>"
	}
}
