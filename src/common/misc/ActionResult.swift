// ActionResult.swift
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
