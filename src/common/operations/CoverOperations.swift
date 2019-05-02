import UIKit


struct CoverOperations
{
	//
	var downloadCallback: ((Data) -> Void)? = nil
	//
	var processCallback: ((UIImage, UIImage) -> Void)? = nil
	// MARK: - Private properties
	// Album
	private let album: Album
	// Optional crop size
	private let cropSize: CGSize
	// Save processed image
	private let saveProcessed: Bool
	// Save original file to disk
	private let saveOriginal = false
	//
	private var downloadOperation: DownloadCoverOperation
	private var bridgeOperation: BlockOperation
	private var processOperation: ProcessCoverOperation

	init(album: Album, cropSize: CGSize, saveProcessed: Bool)
	{
		self.album = album
		self.cropSize = cropSize
		self.saveProcessed = saveProcessed

		self.downloadOperation = DownloadCoverOperation(album: album)
		self.processOperation = ProcessCoverOperation(album: album, cropSize: cropSize, save: saveProcessed)
		self.bridgeOperation = BlockOperation() { [weak processOperation, weak downloadOperation] in
			processOperation?.data = downloadOperation?.downloadedData
		}

		bridgeOperation.addDependency(downloadOperation)
		processOperation.addDependency(bridgeOperation)
	}

	func submit()
	{
		processOperation.callback = processCallback

		OperationManager.shared.addOperations([downloadOperation, processOperation, bridgeOperation], waitUntilFinished: false)
	}

	func cancel()
	{
		downloadOperation.cancel()
		bridgeOperation.cancel()
		processOperation.cancel()
	}
}
