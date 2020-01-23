import UIKit

// MARK: - Notifications name
extension Notification.Name {
	static let currentPlayingTrack = Notification.Name("CurrentPlayingTrack")
	static let playingTrackChanged = Notification.Name("PlayingTrackChanged")
	static let playerStatusChanged = Notification.Name("PlayerStatusChanged")
	static let audioServerConfigurationDidChange = Notification.Name("AudioServerConfigurationDidChange")
	static let audioOutputConfigurationDidChange = Notification.Name("AudioOutputConfigurationDidChange")
	static let collectionViewLayoutShouldChange = Notification.Name("CollectionViewLayoutShouldChange")
	static let showArtistNotification = Notification.Name("showArtistNotification")
	static let showAlbumNotification = Notification.Name("showAlbumNotification")
	static let changeBrowsingTypeNotification = Notification.Name("changeBrowsingTypeNotification")
}
