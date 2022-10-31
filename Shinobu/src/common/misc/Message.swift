import Foundation

struct Message: CustomStringConvertible {
	public enum MessageType {
		case error
		case warning
		case information
		case success
	}

	// Message content
	let content: String
	// Message type
	let type: MessageType

	init(content: String, type: MessageType) {
		self.content = content
		self.type = type
	}

	public var description: String {
		"[\(type)] \(content)"
	}
}
