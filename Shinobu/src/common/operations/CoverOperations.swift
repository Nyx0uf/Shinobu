import UIKit
import Defaults
import Logging

struct CoverOperations {
	// MARK: - Public properties
	// Download operation callback
	var downloadCallback: ((Data) -> Void)?
	// Process image callback
	var processCallback: ((UIImage?, UIImage?, UIImage?) -> Void)?
	// MARK: - Private properties
	// Album
	private let album: Album
	// Flag: Save original file to disk
	private let saveOriginal = false
	// Operations
	private var downloadOperation: DownloadCoverOperation
	private var bridgeOperation: BlockOperation
	private var processOperation: ProcessCoverOperation
	// Logger
	private let logger = Logger(label: "logger.coveroperations")

	init(album: Album, mpdBridge: MPDBridge) {
		self.album = album

		self.downloadOperation = DownloadCoverOperation(logger: logger, mpdBridge: mpdBridge, album: album)
		self.processOperation = ProcessCoverOperation(logger: logger, album: album, cropSizes: CoverOperations.cropSizes())
		self.bridgeOperation = BlockOperation { [weak processOperation, weak downloadOperation] in
			processOperation?.data = downloadOperation?.downloadedData
		}

		bridgeOperation.addDependency(downloadOperation)
		processOperation.addDependency(bridgeOperation)
	}

	func submit() {
		processOperation.callback = processCallback

		OperationManager.shared.addOperations([downloadOperation, processOperation, bridgeOperation], waitUntilFinished: false)
	}

	func cancel() {
		downloadOperation.cancel()
		bridgeOperation.cancel()
		processOperation.cancel()
	}

	public static func cropSizes() -> [AssetSize: CGSize] {
		let smallSize = CGSize(48, 48)
		let mediumSize = CGSize(Defaults[.coversSize], Defaults[.coversSize])
		let w = UIDevice.current.isPad() ? ceil(UIScreen.main.bounds.width) - 64 : ceil(UIScreen.main.bounds.width * 0.333) - 32
		let largeSize = CGSize(w, w)
		return [.small: smallSize, .medium: mediumSize, .large: largeSize]
	}
}
