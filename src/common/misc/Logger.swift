import Foundation

enum LogType: String {
	case error = "❤️"
	case warning = "💛"
	case information = "💜"
	case success = "💚"
}

private struct Log: CustomStringConvertible {
	let type: LogType
	let dateString: String
	let message: String
	let file: String
	let function: String
	let line: Int

	init(type: LogType, date: String, message: String, file: String, function: String, line: Int) {
		self.type = type
		self.message = message
		self.dateString = date
		self.file = file
		self.function = function
		self.line = line
	}

	var description: String {
		return "[\(type)] [\(dateString)] [\(file)] [\(function)] [\(line)]\n↳ \(message)"
	}
}

final class Logger {
	// Singletion instance
	static let shared = Logger()
	// Custom date formatter
	private var dateFormatter: DateFormatter!
	// Logs list
	private var logs: [Log]! = nil
	// Maximum logs countto keep
	private let maxLogsCount = 1024
	// Log queue
	private let queue: DispatchQueue

	// MARK: - Initializers
	init() {
		self.queue = DispatchQueue(label: "fr.whine.shinobu.queue.log", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
	}

	public func initialize() {
		queue.sync { [weak self] in
			guard let strongSelf = self else { return }
			if strongSelf.logs == nil {
				strongSelf.logs = []
			}

			if strongSelf.dateFormatter == nil {
				strongSelf.dateFormatter = DateFormatter()
				strongSelf.dateFormatter.dateFormat = "dd/MM/yy HH:mm:ss"
			}
		}
	}

	// MARK: - Public
	public func log(type: LogType, message: String, file: String = #file, function: String = #function, line: Int = #line) {
#if DEBUG
		print("[\(file)]:[\(line)] => \(message)")
#endif

		queue.async { [weak self] in
			guard let strongSelf = self else { return }
			let log = Log(type: type, date: strongSelf.dateFormatter.string(from: Date()), message: message, file: file, function: function, line: line)
			strongSelf.handleLog(log)
		}
	}

	public func log(error: Error) {
		log(type: .error, message: error.localizedDescription)
	}

	public func log(string: String) {
		log(type: .information, message: string)
	}

	public func log(message: Message) {
		log(type: .information, message: message.content)
	}

	// MARK: - Private
	private func handleLog(_ log: Log) {
		logs.append(log)

		if logs.count > maxLogsCount {
			logs.removeFirst()
		}
	}
}
