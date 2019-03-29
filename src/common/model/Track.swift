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
	override public func hash(into hasher: inout Hasher)
	{
		let value = name.djb2() ^ Int32(duration.seconds) ^ Int32(trackNumber) ^ Int32(uri.hashValue)
		hasher.combine(value)
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
