import UIKit
import Foundation
import Logging

final class DownloadCoverOperation: Operation {
	// MARK: - Public properties
	// isFinished override
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
	// Downloaded data
	var downloadedData = Data()

	// MARK: - Private properties
	// Session configuration
	private var localURLSessionConfiguration: URLSessionConfiguration {
		let cfg = URLSessionConfiguration.default
		cfg.httpShouldUsePipelining = true
		return cfg
	}
	// Session
	private var localURLSession: Foundation.URLSession {
		Foundation.URLSession(configuration: localURLSessionConfiguration, delegate: self, delegateQueue: nil)
	}
	// URL
	private var coverURL: URL?
	// Server manager
	private let serverManager: ServerManager
	// Album
	private let album: Album
	// Save data flag
	private var save = true
	// Task
	private var sessionTask: URLSessionDataTask?
	// Logger
	private let logger: Logger

	// MARK: - Initializers
	init(logger: Logger, album: Album, save: Bool = true) {
		self.album = album
		self.save = save
		self.serverManager = ServerManager()
		self.logger = logger
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
		guard let path = album.path else {
			logger.error("No path defined for album <\(album.name)>")
			isFinished = true
			return
		}

		// No mpd server configured, abort
		guard let server = serverManager.getServer()?.covers else {
			logger.error("No cover server")
			isFinished = true
			return
		}

		guard let finalURL = server.coverURLForPath(path) else {
			logger.error("Unable to create URL for <\(path)>")
			isFinished = true
			return
		}
		coverURL = finalURL

		var request = URLRequest(url: finalURL)
		request.addValue("image/*", forHTTPHeaderField: "Accept")

		sessionTask = localURLSession.dataTask(with: request)
		sessionTask!.resume()
	}

	// MARK: - Private
	override var description: String {
		"DownloadCoverOperation for <\(album.name)>"
	}
}

// MARK: - NSURLSessionDelegate
extension DownloadCoverOperation: URLSessionDataDelegate {
	func urlSession(_ session: Foundation.URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (Foundation.URLSession.ResponseDisposition) -> Void) {
		if isCancelled {
			sessionTask?.cancel()
			isFinished = true
			return
		}

		completionHandler(.allow)
	}

	func urlSession(_ session: Foundation.URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		if isCancelled {
			sessionTask?.cancel()
			isFinished = true
			return
		}
		downloadedData.append(data)
	}

	func urlSession(_ session: Foundation.URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if isCancelled {
			logger.info("Operation cancelled for <\(album.name)>")
			sessionTask?.cancel()
			isFinished = true
			return
		}

		if let err = error {
			logger.error("Failed to receive response: \(err.localizedDescription)")
		}

		isFinished = true
	}

	internal func urlSession(_ session: Foundation.URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
	}
}
