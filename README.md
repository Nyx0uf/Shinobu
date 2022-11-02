# Shinobu

[![Swift Version](https://img.shields.io/badge/Swift-5.7-orange.svg)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/Nyx0uf/shinobu/blob/master/LICENSE)

**Shinobu** is an iOS application to control a [MPD](http://www.musicpd.org/) server and requires *iOS 15.1*. It is designed to be fast (loading my 3000 albums library happens in an instant).

I develop this app on my free time and for my personal need, you can ask for a feature but if I don't see the point I won't implement it.

**Shinobu** is available on the App Store at the price of [5,99€](https://apps.apple.com/us/app/shinobu/id6443788422), because putting it on the App Store cost 100€. If you prefer you can build it yourself, see below.

## FEATURES

- iPhone / iPad
- Browsing by *albums*, *artists*, *albums artists*, *genres*, *playlists*, or directly browsing the filesystem (your MPD directory).
- Search
- Playback control (*Play/Pause*, *Shuffle*, *Repeat*, *Track position*)
- Volume control
- Playlists management (Create / Delete / Add to / Remove from)
- VoiceOver compliant
- Automatically find MPD server with Bonjour/Zeroconf
- MPD outputs selection
- 🇬🇧 and 🇫🇷 localized

## SCREENSHOTS

![screenshot-iphone](https://static.whine.fr/images/2019/shinobu-iphone.jpg)![screenshot-ipad](https://static.whine.fr/images/2019/shinobu-ipad.jpg)

## TODO

- Rewrite the libmpdclient bridge, because it is ugly
- Apple TV version (probably never)
- An nice app icon. I have absolutely no design skills, if someone wants to help

## MANUAL INSTALLATION

To install **Shinobu** you will need macOS, so you have two choices, either you have access to a Mac, or you run macOS on a Virtual Machine.

1. Install the latest [Xcode version](https://itunes.apple.com/fr/app/xcode/id497799835?l=en&mt=12).
2. Clone this repository.
3. Open *shinobu.xcodeproj*.
4. Plug your iPhone and hit the Build & Run button.
5. Head to the [wiki](https://github.com/Nyx0uf/shinobu/wiki) for app settings and configuration help.

## ISSUES

Please open an [issue](https://github.com/Nyx0uf/shinobu/issues).

## LICENSE

**Shinobu** is released under the MIT License, see LICENSE file.
