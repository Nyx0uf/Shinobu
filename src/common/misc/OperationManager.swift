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

	func addOperations(_ operations: [Operation], waitUntilFinished: Bool = false)
	{
		operationQueue.addOperations(operations, waitUntilFinished: waitUntilFinished)

	}

	func cancelAllOperations()
	{
		operationQueue.cancelAllOperations()
	}
}
