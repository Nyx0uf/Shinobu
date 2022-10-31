import Foundation

protocol ReuseIdentifying {
	static var reuseIdentifier: String { get }
}

extension ReuseIdentifying {
	static var reuseIdentifier: String {
		return String(describing: Self.self)
	}
}
