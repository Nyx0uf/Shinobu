import Foundation

struct Duration {
	// MARK: - Public properties
	// Value in seconds
	let seconds: UInt

	// MARK: - Initializers
	init(seconds: UInt) {
		self.seconds = seconds
	}

	init(seconds: Int) {
		self.seconds = UInt(seconds)
	}

	// MARK: - Public
	func minutesRepresentation() -> (minutes: UInt, seconds: UInt) {
		(seconds / 60, seconds % 60)
	}

	func minutesRepresentationAsString(_ delim: String = ":") -> String {
		let tmp = minutesRepresentation()
		return "\(tmp.minutes)\(delim)\(tmp.seconds < 10 ? "0" : "")\(tmp.seconds)"
	}

	func hoursRepresentation() -> (hours: UInt, minutes: UInt, seconds: UInt) {
		var secs = seconds
		let hours = secs / 3600
		secs -= hours * 3600
		let minutes = secs / 60
		secs -= minutes * 60
		return (hours, minutes, secs)
	}

	func daysRepresentation() -> (days: UInt, hours: UInt, minutes: UInt, seconds: UInt) {
		var secs = seconds
		let days = secs / 86400
		secs -= days * 86400
		let hours = secs / 3600
		secs -= hours * 3600
		let minutes = secs / 60
		secs -= minutes * 60
		return (days, hours, minutes, secs)
	}

	func monthsRepresentation() -> (months: UInt, days: UInt, hours: UInt, minutes: UInt, seconds: UInt) {
		var secs = seconds
		let months = secs / 2678400
		secs -= months * 2678400
		let days = secs / 86400
		secs -= days * 86400
		let hours = secs / 3600
		secs -= hours * 3600
		let minutes = secs / 60
		secs -= minutes * 60
		return (months, days, hours, minutes, secs)
	}
}

extension Duration: Equatable {
	static func == (lhs: Duration, rhs: Duration) -> Bool {
		lhs.seconds == rhs.seconds
	}
}

extension Duration: Comparable {
	static func < (lhs: Duration, rhs: Duration) -> Bool {
		lhs.seconds < rhs.seconds
	}
}

extension Duration: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(seconds)
	}
}

extension Duration: CustomStringConvertible {
	var description: String {
		String(seconds)
	}
}

// MARK: - Maths
func + (lhs: Duration, rhs: Duration) -> Duration {
	Duration(seconds: lhs.seconds + rhs.seconds)
}

func - (lhs: Duration, rhs: Duration) -> Duration {
	Duration(seconds: lhs.seconds - rhs.seconds)
}
