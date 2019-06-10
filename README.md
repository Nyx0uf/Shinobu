[![Twitter: @Nyx0uf](https://img.shields.io/badge/contact-@Nyx0uf-blue.svg?style=flat)](https://twitter.com/Nyx0uf) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/Nyx0uf/shinobu/blob/master/LICENSE) [![Swift Version](https://img.shields.io/badge/Swift-5.0-orange.svg)]() [![Build Status](https://travis-ci.com/Nyx0uf/shinobu.svg?token=B17m6ZTXBssj71u81LbU&branch=master)](https://travis-ci.com/Nyx0uf/shinobu)

**Shinobu** is an iOS application to control a [MPD](http://www.musicpd.org/) server and requires *iOS 12.2*. It is designed to be fast (loading my 3000 albums library happens in an instant).

I develop this app for my personal need, you can ask for features but if I don't see the point I won't implement it.

I won't submit it to the App Store because I don't have 100€ to spare nor the time to deal with Apple's validation process. So if you want to use this app you will have to download the code and build it yourself.

# FEATURES

- Multi-server support (Can register many servers but control one at a time)
- Browse (*albums*, *artists*, *albums artists*, *genres*, *playlists*)
- Search (*normal* / *fuzzy*)
- Playback control (*Play/Pause*, *Shuffle*, *Repeat*, *Track position*)
- Volume control
- Playlists management
- VoiceOver compliant
- Automatically find MPD server with Bonjour/Zeroconf
- MPD Audio output selection
- Widget
- Normal & Dark modes, 5 tint colors
- 🇬🇧 and 🇫🇷 localized


# TODO

- iPad version
- Apple TV version


![screenshot](https://static.whine.fr/images/2019/shinobu1.gif)


# INSTALLATION

To install **Shinobu** you will need macOS, so you have two choices, either you have access to a Mac, or you run macOS on a Virtual Machine.

1. Install the latest [Xcode version](https://itunes.apple.com/fr/app/xcode/id497799835?l=en&mt=12)
2. Clone this project
3. Open *shinobu.xcodeproj*
4. Plug your iPhone and hit the Build & Run button


# MPD PRETTY DB

**pretty_mpd_db.py** is a python 3 script which generate a JSON file containing all the albums (*name* and *path*) of your mpd library.
It allows loading covers faster because all the albums paths will be known. Otherwise to have an album path, the app needs to query the songs of the album to get the path, this is due to the design of the mpd api.

Usage :

    mpd_pretty_db.py -d mpd_music_directory_in_your_mpd_conf

# LICENSE

**Shinobu** is released under the MIT License, see LICENSE file.
