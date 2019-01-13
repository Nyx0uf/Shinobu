import Foundation


final class Message : CustomStringConvertible
{
	public enum MessageType
	{
		case error
		case warning
		case information
		case success
	}

	// Message content
	let content: String
	// Message type
	let type: MessageType

	init(content: String, type: MessageType)
	{
		self.content = content
		self.type = type
	}

	public var description: String
	{
		return "[\(self.type)] \(self.content)"
	}
}

public final class ActionResult<T>
{
	// Success flag
	let succeeded: Bool
	// Messages (error, infos…)
	let messages: [Message]
	// Associated entity
	let entity: T?

	init(succeeded: Bool)
	{
		self.succeeded = succeeded
		self.messages = []
		self.entity = nil
	}

	init(succeeded: Bool, entity: T?)
	{
		self.succeeded = succeeded
		self.messages = []
		self.entity = entity
	}

	init(succeeded: Bool, entity: T?, message: Message)
	{
		self.succeeded = succeeded
		self.messages = [message]
		self.entity = entity
	}

	init(succeeded: Bool, entity: T?, messages: [Message])
	{
		self.succeeded = succeeded
		self.messages = messages
		self.entity = entity
	}

	init(succeeded: Bool, message: Message)
	{
		self.succeeded = succeeded
		self.messages = [message]
		self.entity = nil
	}

	init(succeeded: Bool, messages: [Message])
	{
		self.succeeded = succeeded
		self.messages = messages
		self.entity = nil
	}
}
