import UIKit
import Foundation


final class CoverOperation : Operation
{
	// MARK: - Private properties
	// isFinished override
	private var junk = false
	override var isFinished: Bool {
		get {
			return junk
		}
		set (newAnswer) {
			#if os(iOS)
			NetworkActivityIndicator.shared.end()
			#endif
			willChangeValue(forKey: "isFinished")
			junk = newAnswer
			didChangeValue(forKey: "isFinished")
		}
	}

	// Downloaded data
	var incomingData = Data()
	// Task
	var sessionTask: URLSessionTask?
	// Session configuration
	private var localURLSessionConfiguration: URLSessionConfiguration {
		let cfg = URLSessionConfiguration.default
		cfg.httpShouldUsePipelining = true
		return cfg
	}
	// Session
	private var localURLSession: Foundation.URLSession {
		return Foundation.URLSession(configuration: localURLSessionConfiguration, delegate: self, delegateQueue: nil)
	}
	// URL
	private var coverURL: URL? = nil

	// MARK : Public properties
	// Album
	let album: Album
	// Size of the thumbnail to create
	let cropSize: CGSize
	// Custom completion block
	var callback: ((UIImage, UIImage) -> Void)? = nil

	// MARK: - Initializers
	init(album: Album, cropSize: CGSize)
	{
		self.album = album
		self.cropSize = cropSize
	}

	// MARK: - Override
	override func start()
	{
		// Operation is cancelled, abort
		if isCancelled
		{
			Logger.shared.log(type: .debug, message: "Operation cancelled for <\(album.name)>")
			isFinished = true
			return
		}

		// No path for album, abort
		guard let path = album.path else
		{
			Logger.shared.log(type: .error, message: "No path defined for album <\(album.name)>")
			isFinished = true
			return
		}
		/*if path.first != Character("/")
		{
			path = "/" + path
		}*/

		// No mpd server configured, abort
		guard let server = ServersManager.shared.getSelectedServer()?.covers else
		{
			Logger.shared.log(type: .error, message: "No cover server")
			isFinished = true
			return
		}

		guard let finalURL = server.coverURLForPath(path) else
		{
			Logger.shared.log(type: .error, message: "Unable to create URL for <\(path)>")
			isFinished = true
			return
		}
		self.coverURL = finalURL

		var request = URLRequest(url: finalURL)
		request.addValue("image/*", forHTTPHeaderField: "Accept")

		sessionTask = localURLSession.dataTask(with: request)
		sessionTask!.resume()
	}

	// MARK: - Private
	private func processData()
	{
		guard let cover = UIImage(data: incomingData) else
		{
			Logger.shared.log(type: .error, message: "Invalid cover data for <\(album.name)> (\(incomingData.count)b) [\(String(describing: coverURL))]")
			return
		}
		guard let thumbnail = cover.smartCropped(toSize: cropSize) else
		{
			Logger.shared.log(type: .error, message: "Failed to create thumbnail for <\(album.name)>")
			return
		}
		guard let saveURL = album.localCoverURL else
		{
			Logger.shared.log(type: .error, message: "Invalid cover url for <\(album.name)>")
			return
		}

		if thumbnail.save(url: saveURL) == false
		{
			Logger.shared.log(type: .error, message: "Failed to save cover for <\(album.name)>")
		}

		if let block = callback
		{
			block(cover, thumbnail)
		}
	}

	override var description: String
	{
		return "CoverOperation for <\(album.name)>"
	}
}

// MARK: - NSURLSessionDelegate
extension CoverOperation : URLSessionDataDelegate
{
	func urlSession(_ session: Foundation.URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (Foundation.URLSession.ResponseDisposition) -> Void)
	{
		if isCancelled
		{
			Logger.shared.log(type: .debug, message: "Cancelled")
			sessionTask?.cancel()
			isFinished = true
			return
		}

		#if os(iOS)
		NetworkActivityIndicator.shared.start()
		#endif

		completionHandler(.allow)
	}

	func urlSession(_ session: Foundation.URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
	{
		if isCancelled
		{
			Logger.shared.log(type: .debug, message: "Cancelled")
			sessionTask?.cancel()
			isFinished = true
			return
		}
		incomingData.append(data)
	}

	func urlSession(_ session: Foundation.URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
	{
		if isCancelled
		{
			Logger.shared.log(type: .debug, message: "Cancelled")
			sessionTask?.cancel()
			isFinished = true
			return
		}

		if let err = error
		{
			Logger.shared.log(type: .error, message: "Failed to receive response: \(err.localizedDescription)")
			isFinished = true
			return
		}
		processData()
		isFinished = true
	}

	internal func urlSession(_ session: Foundation.URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
	{
		completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
	}
}
