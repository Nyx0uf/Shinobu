import Foundation
import UIKit


final class OperationManager
{
	// Singletion instance
	static let shared = OperationManager()
	// Global operation queue
	private var operationQueue: OperationQueue! = nil

	// MARK: - Initializers
	init()
	{
		operationQueue = OperationQueue()
		operationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
	}

	// MARK: - Public
	func addOperation(_ operation: Operation)
	{
		operationQueue.addOperation(operation)
	}

	func cancelAllOperations()
	{
		operationQueue.cancelAllOperations()
	}

	func start(album: Album, cropSize: CGSize)
	{
		let dop = DownloadCoverOperation(album: album, cropSize: cropSize)
		let pop = ProcessCoverOperation(album: album, cropSize: cropSize)
		let aop = BlockOperation() { [unowned pop, unowned dop] in
			pop.data = dop.incomingData
		}
		aop.addDependency(dop)
		pop.addDependency(aop)
		operationQueue.addOperations([dop, pop, aop], waitUntilFinished: false)
	}
}
