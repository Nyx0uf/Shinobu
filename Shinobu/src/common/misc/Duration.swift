import Foundation

struct Duration {
	// MARK: - Public properties
	// Backing value in seconds
	let value: UInt
	// Hours representation
	let hours: UInt
	// Minutes representation
	let minutes: UInt
	// Seconds representation
	let seconds: UInt
	// MM:SS
	lazy var minutesDescription: String = {
		return "\(self.minutes):\(self.seconds < 10 ? "0" : "")\(self.seconds)"
	}()

	// MARK: - Initializers
	init(seconds: UInt) {
		self.value = seconds
		var secs = seconds
		self.hours = secs / 3600
		secs -= hours * 3600
		self.minutes = secs / 60
		secs -= minutes * 60
		self.seconds = secs
	}
}

extension Duration: Equatable {
	static func == (lhs: Duration, rhs: Duration) -> Bool {
		lhs.value == rhs.value
	}
}

extension Duration: Comparable {
	static func < (lhs: Duration, rhs: Duration) -> Bool {
		lhs.value < rhs.value
	}
}

extension Duration: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(value)
	}
}

extension Duration: CustomStringConvertible {
	var description: String {
		String(value)
	}
}

// MARK: - Maths
func + (lhs: Duration, rhs: Duration) -> Duration {
	Duration(seconds: lhs.value + rhs.value)
}

func - (lhs: Duration, rhs: Duration) -> Duration {
	Duration(seconds: lhs.value - rhs.value)
}
