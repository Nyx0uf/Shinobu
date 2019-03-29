import UIKit

// MARK: - Notifications name
extension Notification.Name
{
	static let currentPlayingTrack = Notification.Name("CurrentPlayingTrack")
	static let playingTrackChanged = Notification.Name("PlayingTrackChanged")
	static let playerStatusChanged = Notification.Name("PlayerStatusChanged")
	static let miniPlayerViewWillShow = Notification.Name("MiniPlayerViewWillShow")
	static let miniPlayerViewDidShow = Notification.Name("MiniPlayerViewDidShow")
	static let miniPlayerViewWillHide = Notification.Name("MiniPlayerViewWillHide")
	static let miniPlayerViewDidHide = Notification.Name("MiniPlayerViewDidHide")
	static let miniPlayerShouldExpand = Notification.Name("MiniPlayerShouldExpand")
	static let audioServerConfigurationDidChange = Notification.Name("AudioServerConfigurationDidChange")
	static let audioOutputConfigurationDidChange = Notification.Name("AudioOutputConfigurationDidChange")
}

// MARK: - Clamp
public func clamp<T: Comparable>(_ value: T, lower: T, upper: T) -> T
{
	return max(min(value, upper), lower)
}
