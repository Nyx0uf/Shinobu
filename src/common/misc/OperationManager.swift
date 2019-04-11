import Foundation


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
		if operationQueue.operationCount < 16
		{
			operationQueue.addOperation(operation)
		}
		else
		{
			Logger.shared.log(string: "dropping \(operation)")
		}
	}

	func cancelAllOperations()
	{
		operationQueue.cancelAllOperations()
	}
}
