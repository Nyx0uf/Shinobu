import UIKit

struct CoverOperations {
	//
	var downloadCallback: ((Data) -> Void)?
	//
	var processCallback: ((UIImage?, UIImage?, UIImage?) -> Void)?
	// MARK: - Private properties
	// Album
	private let album: Album
	// Save original file to disk
	private let saveOriginal = false
	//
	private var downloadOperation: DownloadCoverOperation
	private var bridgeOperation: BlockOperation
	private var processOperation: ProcessCoverOperation

	init(album: Album) {
		self.album = album

		self.downloadOperation = DownloadCoverOperation(album: album)
		self.processOperation = ProcessCoverOperation(album: album, cropSizes: CoverOperations.cropSizes())
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

	private static func cropSizes() -> [AssetSize: CGSize] {
		return [.small: CGSize(48, 48),
				.medium: CGSize(AppDefaults.coversSize, AppDefaults.coversSize),
				.large: CGSize(UIScreen.main.bounds.width - 64, UIScreen.main.bounds.width - 64)]

	}
}
