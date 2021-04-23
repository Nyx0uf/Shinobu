[![Twitter: @Nyx0uf](https://img.shields.io/badge/contact-@Nyx0uf-blue.svg?style=flat)](https://twitter.com/Nyx0uf) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/Nyx0uf/shinobu/blob/master/LICENSE) [![Swift Version](https://img.shields.io/badge/Swift-5.3-orange.svg)]()

**Shinobu** is an iOS application to control a [MPD](http://www.musicpd.org/) server and requires *iOS 14.1*. It is designed to be fast (loading my 3000 albums library happens in an instant).

I develop this app on my free time and for my personal need, you can ask for a feature but if I don't see the point I won't implement it.

I won't submit it to the App Store because I don't have 100€ to spare nor the time to deal with Apple's validation process. So if you want to use this app you will have to download the code and build it yourself.

# FEATURES

- Multi-server support (only on the branch **feat/multi-servers**)
- Browsing by *albums*, *artists*, *albums artists*, *genres*, *playlists*, or directly browsing the filesystem (your MPD directory).
- Search, *global* or *contextual*, *normal* or *fuzzy*
- Playback control (*Play/Pause*, *Shuffle*, *Repeat*, *Track position*)
- Volume control
- Playlists management (Create / Delete / Add to / Remove from)
- VoiceOver compliant
- Automatically find MPD server with Bonjour/Zeroconf
- MPD outputs selection
- Widgets (small and medium)
- Normal & Dark modes, 5 tint colors (blue, green, pink, orange, yellow)
- 🇬🇧 and 🇫🇷 localized

# TODO

- iPad version
- Apple TV version
- An App icon, I have 0 design skills, if someone wants to help

![screenshot](https://static.whine.fr/images/2019/shinobu2.gif)

# INSTALLATION

To install **Shinobu** you will need macOS, so you have two choices, either you have access to a Mac, or you run macOS on a Virtual Machine.

1. Install the latest [Xcode version](https://itunes.apple.com/fr/app/xcode/id497799835?l=en&mt=12).
2. Clone this repository.
3. Open *shinobu.xcodeproj*.
4. Plug your iPhone and hit the Build & Run button.
5. Head to the [wiki](https://github.com/Nyx0uf/shinobu/wiki) for app settings and configuration help.

# ISSUES

Please open an [issue](https://github.com/Nyx0uf/shinobu/issues).

# LICENSE

**Shinobu** is released under the MIT License, see LICENSE file.
