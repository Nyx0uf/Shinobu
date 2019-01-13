// Duration.swift
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
