import UIKit


/* RootVC display type */
enum DisplayType : Int
{
	case albums
	case artists
	case albumsartists
	case genres
	case playlists
}

// MARK: - Notifications name
extension Notification.Name
{
	static let currentPlayingTrack = Notification.Name("kNYXNotificationCurrentPlayingTrack")
	static let playingTrackChanged = Notification.Name("kNYXNotificationPlayingTrackChanged")
	static let playerStatusChanged = Notification.Name("kNYXNotificationPlayerStatusChanged")
	static let miniPlayerViewWillShow = Notification.Name("kNYXNotificationMiniPlayerViewWillShow")
	static let miniPlayerViewDidShow = Notification.Name("kNYXNotificationMiniPlayerViewDidShow")
	static let miniPlayerViewWillHide = Notification.Name("kNYXNotificationMiniPlayerViewWillHide")
	static let miniPlayerViewDidHide = Notification.Name("kNYXNotificationMiniPlayerViewDidHide")
	static let miniPlayerShouldExpand = Notification.Name("kNYXNotificationMiniPlayerShouldExpand")
	static let audioServerConfigurationDidChange = Notification.Name("kNYXNotificationAudioServerConfigurationDidChange")
	static let audioOutputConfigurationDidChange = Notification.Name("kNYXNotificationAudioOutputConfigurationDidChange")
	static let collectionViewsLayoutDidChange = Notification.Name("kNYXNotificationCollectionViewsLayoutDidChange")
}
