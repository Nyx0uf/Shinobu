import Foundation


struct Duration
{
	// MARK: - Public properties
	// Value in seconds
	let seconds: UInt

	// MARK: - Initializers
	init(seconds: UInt)
	{
		self.seconds = seconds
	}

	init(seconds: Int)
	{
		self.seconds = UInt(seconds)
	}

	// MARK: - Public
	func minutesRepresentation() -> (minutes: UInt, seconds: UInt)
	{
		return (seconds / 60, seconds % 60)
	}

	func minutesRepresentationAsString(_ delim: String = ":") -> String
	{
		let tmp = minutesRepresentation()
		return "\(tmp.minutes)\(delim)\(tmp.seconds < 10 ? "0" : "")\(tmp.seconds)"
	}

	func hoursRepresentation() -> (hours: UInt, minutes: UInt, seconds: UInt)
	{
		var s = seconds
		let hours = s / 3600
		s -= hours * 3600
		let minutes = s / 60
		s -= minutes * 60
		return (hours, minutes, s)
	}

	func daysRepresentation() -> (days: UInt, hours: UInt, minutes: UInt, seconds: UInt)
	{
		var s = seconds
		let days = s / 86400
		s -= days * 86400
		let hours = s / 3600
		s -= hours * 3600
		let minutes = s / 60
		s -= minutes * 60
		return (days, hours, minutes, s)
	}

	func monthsRepresentation() -> (months: UInt, days: UInt, hours: UInt, minutes: UInt, seconds: UInt)
	{
		var s = seconds
		let months = s / 2678400
		s -= months * 2678400
		let days = s / 86400
		s -= days * 86400
		let hours = s / 3600
		s -= hours * 3600
		let minutes = s / 60
		s -= minutes * 60
		return (months, days, hours, minutes, s)
	}
}

// MARK: - Equatable
extension Duration : Equatable
{
	static func == (lhs: Duration, rhs: Duration) -> Bool
	{
		return lhs.seconds == rhs.seconds
	}
}

// MARK: - Comparable
extension Duration : Comparable
{
	static func < (lhs: Duration, rhs: Duration) -> Bool
	{
		return lhs.seconds < rhs.seconds
	}
}


extension Duration : Hashable
{
	var hashValue: Int
	{
		return seconds.hashValue
	}
}

extension Duration : CustomStringConvertible
{
	var description: String
	{
		return String(seconds)
	}
}

// MARK: - Maths
func + (lhs: Duration, rhs: Duration) -> Duration
{
	return Duration(seconds: lhs.seconds + rhs.seconds)
}

func - (lhs: Duration, rhs: Duration) -> Duration
{
	return Duration(seconds: lhs.seconds - rhs.seconds)
}
