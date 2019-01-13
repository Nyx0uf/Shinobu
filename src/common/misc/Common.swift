// Common.swift
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
