import Foundation


enum LogType: String
{
	case error = "❤️"
	case warning = "💛"
	case information = "💜"
	case success = "💚"
}

private struct Log: CustomStringConvertible
{
	let type: LogType
	let dateString: String
	let message: String
	let file: String
	let function: String
	let line: Int

	init(type t: LogType, date d: String, message m: String, file fi: String, function fu: String, line li: Int)
	{
		type = t
		message = m
		dateString = d
		file = fi
		function = fu
		line = li
	}

	var description: String
	{
		return "[\(type)] [\(dateString)] [\(file)] [\(function)] [\(line)]\n↳ \(message)"
	}
}

final class Logger
{
	// Singletion instance
	static let shared = Logger()
	// Custom date formatter
	private let dateFormatter: DateFormatter
	// Logs list
	private var logs: [Log]
	// Maximum logs countto keep
	private let maxLogsCount = 1024

	// MARK: - Initializers
	init()
	{
		self.dateFormatter = DateFormatter()
		self.dateFormatter.dateFormat = "dd/MM/yy HH:mm:ss"

		self.logs = [Log]()
	}

	// MARK: - Public
	public func log(type: LogType, message: String, file: String = #file, function: String = #function, line: Int = #line)
	{
#if DEBUG
		print("[\(file)]:[\(line)] => \(message)")
#endif

		if Settings.shared.bool(forKey: .pref_enableLogging) == false
		{
			return
		}

		DispatchQueue.global(qos: .background).async { [weak self] in
			guard let strongSelf = self else { return }
			let log = Log(type: type, date: strongSelf.dateFormatter.string(from: Date()), message: message, file: file, function: function, line: line)
			strongSelf.handleLog(log)
		}
	}

	public func log(error: Error)
	{
		log(type: .error, message: error.localizedDescription)
	}

	public func log(string: String)
	{
		log(type: .information, message: string)
	}

	public func log(message: Message)
	{
		log(type: .information, message: message.content)
	}

	public func export() -> Data?
	{
		let str = logs.reduce("") { $0 + $1.description + "\n\n"}
		return str.data(using: .utf8)
	}

	// MARK: - Private
	private func handleLog(_ log: Log)
	{
		logs.append(log)

		if logs.count > maxLogsCount
		{
			logs.removeFirst()
		}
	}
}
