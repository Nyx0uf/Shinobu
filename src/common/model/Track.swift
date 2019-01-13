// Track.swift
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


final class Track : MusicalEntity
{
	// MARK: - Public properties
	// Track artist
	var artist: String
	// Track duration
	var duration: Duration
	// Track number
	var trackNumber: Int
	// Track uri
	var uri: String
	// Position in the queue
	var position: UInt32 = 0

	// MARK: - Initializers
	init(name: String, artist: String, duration: Duration, trackNumber: Int, uri: String)
	{
		self.artist = artist
		self.duration = duration
		self.trackNumber = trackNumber
		self.uri = uri
		super.init(name: name)
	}

	// MARK: - Hashable
	override var hashValue: Int
	{
		get
		{
			return Int(name.djb2()) ^ Int(duration.seconds) ^ trackNumber ^ uri.hashValue
		}
	}
}

extension Track : CustomStringConvertible
{
	var description: String
	{
		return "Title: <\(name)>\nArtist: <\(artist)>\nDuration: <\(duration)>\nTrack: <\(trackNumber)>\nURI: <\(uri)>\nPosition: <\(position)>"
	}
}

// MARK: - Equatable
extension Track
{
	static func ==(lhs: Track, rhs: Track) -> Bool
	{
		return (lhs.name == rhs.name && lhs.artist == rhs.artist && lhs.duration == rhs.duration && lhs.uri == rhs.uri)
	}
}
