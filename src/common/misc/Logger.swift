// Logger.swift
// Copyright (c) 2017 Nyx0uf
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import Foundation


enum LogType : String
{
	case debug = "💜"
	case success = "💚"
	case warning = "💛"
	case error = "❤️"
}

private struct Log : CustomStringConvertible
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
	private let _dateFormatter: DateFormatter
	// Logs list
	private var _logs: [Log]
	// Maximum logs countto keep
	private let _maxLogsCount = 4096

	// MARK: - Initializers
	init()
	{
		self._dateFormatter = DateFormatter()
		self._dateFormatter.dateFormat = "dd/MM/yy HH:mm:ss"

		self._logs = [Log]()
	}

	// MARK: - Public
	public func log(type: LogType, message: String, file: String = #file, function: String = #function, line: Int = #line)
	{
#if NYX_DEBUG
		print(message)
#endif

		if Settings.shared.bool(forKey: kNYXPrefEnableLogging) == false
		{
			return
		}

		DispatchQueue.global(qos: .background).async { [weak self] in
			guard let strongSelf = self else { return }
			let log = Log(type: type, date: strongSelf._dateFormatter.string(from: Date()), message: message, file: file, function: function, line: line)
			strongSelf.handleLog(log)
		}
	}

	public func log(error: Error)
	{
		self.log(type: .error, message: error.localizedDescription)
	}

	public func log(string: String)
	{
		self.log(type: .debug, message: string)
	}

	public func export() -> Data?
	{
		let str = _logs.reduce("") { $0 + $1.description + "\n\n"}
		return str.data(using: .utf8)
	}

	// MARK: - Private
	private func handleLog(_ log: Log)
	{
		_logs.append(log)

		if _logs.count > _maxLogsCount
		{
			_logs.remove(at: 0)
		}
	}
}
