import UIKit


struct CoverOperations
{
	// MARK: - Private properties
	// Album
	private let album: Album
	// Optional crop size
	private let cropSize: CGSize
	// Save processed image
	private let saveProcessed: Bool
	// Save original file to disk
	private let saveOriginal = false

	init(album: Album, cropSize: CGSize, saveProcessed: Bool)
	{
		self.album = album
		self.cropSize = cropSize
		self.saveProcessed = saveProcessed
	}

	func submit()
	{
		let dop = DownloadCoverOperation(album: album, cropSize: cropSize)
		let pop = ProcessCoverOperation(album: album, cropSize: cropSize)
		let aop = BlockOperation() { [unowned pop, unowned dop] in
			pop.data = dop.incomingData
		}
		aop.addDependency(dop)
		pop.addDependency(aop)
		OperationManager.shared.addOperations([dop, pop, aop], waitUntilFinished: false)
	}
}
