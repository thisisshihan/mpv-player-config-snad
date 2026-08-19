-----------------------------------
### About mpv.snad:
[<img src="https://github.com/thisisshihan/screenshots/blob/master/mpv.icon256.png" width="100">](https://mpv.io/)\
[mpv](https://mpv.io/) Player is a free, open source, and cross-platform media player.
This repository contain optimized configs for mpv player focused on fast, efficient & minimalist look. No bs scripts which will reduce speed of loading/opening a file.

#### Download Latest Windows Version:
* Download the latest version from sourceforge.net [mpv.snad](https://sourceforge.net/projects/mpv-snad/files/) (this file contain all the config files) 
* _(AMD FSR and NVIDIA Image Scaling added (CTRL+A/N/Z) added to v35.1 +)_

#### Major ✨ Features of mpv.snad configs:
* Fast, efficient & minimalist look (Osc updated to latest native Floating Design)
* AMD FSR and NVIDIA Image Scaling (CTRL+A/N/Z)
* Optimized Touchpad Gesture
* Enabled native Advanced Playlist (P)
* Podcast RSS Feed Support

#### How to install:
* Download latest mpv player from official [github](https://github.com/zhongfly/mpv-winbuild)
* Download mpv.snad config files from [Here](https://github.com/thisisshihan/mpv-player-config-snad/archive/refs/heads/mpv-config-snad-windows-ubuntu-linux-macos.zip)
* Extract the files.
* Move the folder to required destination.
* Go to **_`.../installer`_** folder
* Run **_`mpv-install.bat`_** as admin
* The configuration can be kept together with MPV instead of being installed into the user's system configuration directory.
```text
mpv/
├── mpv.exe
├── installer/
│   ├── mpv-install.bat
│   ├── mpv-icon.ico
│   └── ...
├── portable_config/
│   ├── mpv.conf
│   ├── input.conf
│   ├── shaders/
|   ├── scripts/
│   └── ...
```

#### Other Downloads
* Windows / ubuntu / linux / macos / Android stable cahnnel official: [mpv.io](http://mpv.io/installation)
* Android stable official: [play.google.com](https://play.google.com/store/apps/details?id=is.xyz.mpv&hl=en)
* Android test builds official: [github.com](https://github.com/mpv-android/mpv-android/releases)
* Config For Windows not required if you download the player mpv.snad [sourceforge](https://sourceforge.net/projects/mpv-snad/files/)

#### Config For Windows:
* Download All Settings From [Here](https://github.com/thisisshihan/mpv-player-config-snad/archive/refs/heads/mpv-config-snad-windows-ubuntu-linux-macos.zip) and extract them to a folder.
* copy / overwrite extracted files to **_`...AppData\Roaming\mpv`_** <br/>_or_
* create a folder as **_`portable_config`_** in the folder where mpv.exe exist and,
* copy extracted files to **_`...portable_config`_**

#### Config For Linux:
* Download All Settings From [Here](https://github.com/thisisshihan/mpv-player-config-snad/archive/refs/heads/mpv-config-snad-windows-ubuntu-linux-macos.zip) and extract them to a folder.
* copy / overwrite extracted files to **_`...etc/mpv`_** _(you need root access to this folder)_

#### **Basic key guide -->** [<kbd>key-guide</kbd>](https://github.com/thisisshihan/mpv-player-config-snad/blob/mpv-config-snad-windows-ubuntu-linux-macos/KEY_basic.md)
#### **A Complete key guide -->** [<kbd>key-guide</kbd>](https://github.com/thisisshihan/mpv-player-config-snad/blob/mpv-config-snad-windows-ubuntu-linux-macos/KEY.md)
-------------------------------------
**Simple Interface**<br/>
<img src="https://github.com/thisisshihan/screenshots/blob/master/mpv.interface2.png" width="800">

##
**Touchpad Gesture**<br/>
<img src="https://github.com/thisisshihan/screenshots/blob/master/touchpadGesture2.png" width="300">

##
**Advanced Playlist Manager**<br/>
_Navigate_ <kbd> UP </kbd> / <kbd>DOWN</kbd> / <kbd>    SPACE    </kbd> / <kbd> < </kbd> / <kbd> > </kbd> <br/>_A Complete key guide -->_ [<kbd>key-guide</kbd>](https://github.com/thisisshihan/mpv-player-config-snad/blob/mpv-config-snad-windows-ubuntu-linux-macos/KEY.md)<br/>\
<img src="https://github.com/thisisshihan/screenshots/blob/master/mpv.playlist.png" width="800">

##
**Podcast RSS Feed Support**<br/>
_Podcast Menu_ <kbd> ALT </kbd> + <kbd>P</kbd>\
<img src="https://github.com/thisisshihan/screenshots/blob/master/Podcast.png" width="600">

```text
# Podcast feed list for podcast.lua
# One RSS feed URL per line. Lines starting with # are ignored.
# Drag this file onto the mpv window (or run: mpv.exe feeds.pcst)
# Recognized extensions: .pcst and .snad
#
# FILTERING (optional):
#   filter: keyword1, keyword2   -> only load episodes whose title
#                                   contains at least one keyword
#   exclude: keyword1, keyword2  -> skip episodes whose title contains
#                                   any of these keywords
#
# REMOVE DUPLICATE TITLES (optional, off by default):
#   remove-duplicates: yes       -> drop episodes with a title already
#                                   seen earlier in this load
#
# SKIP INTRO / ADS (optional):
#   start: 180        -> start every episode below 180s in
#   start: 3:00       -> same thing, mm:ss format also accepted
#   start: 0          -> turn it back off
#
# YT-DLP (optional, off by default):
#   ytdl: yes         -> allow yt-dlp for feeds below (rarely needed)
#   ytdl: no          -> back to default (mpv opens the file directly)
#
# All of the above are "sticky" - they apply to every feed URL below
# them until changed again. You can also set any of them inline for a
# single feed only:
#   https://example.com/feed.rss | filter=keyword1, keyword2 | start=45

filter: FULL_SHOW, full show
exclude: promo, ad break
remove-duplicates: yes
start: 3:00
https://example.com/shows/sample-podcast/feed.rss
```

##
**Visualizer**<br/>
A perfect visualizer for audios with no album-art or for Internet Radios
<kbd>![s2](https://github.com/thisisshihan/screenshots/blob/master/mpv_visualizer.PNG)</kbd>
##
**Improved Video Filter for Best Video Experience**<br/>
_Apply Video Filter_ <kbd> V </kbd>, <kbd> CTRL </kbd> + <kbd> 1 -> 9 </kbd> <br/>_A Complete key guide -->_ [<kbd>key-guide</kbd>](https://github.com/thisisshihan/mpv-player-config-snad/blob/mpv-config-snad-windows-ubuntu-linux-macos/KEY.md)<br/>_(Pic1-without filter, Pic2-with filter)_<br/>
<kbd>![s1](https://github.com/thisisshihan/screenshots/blob/master/mpv.adv.color.png)</kbd>

-------------------------------------
## About MPV Player:
**Overview:**
> mpv is a fork of [mplayer2](http://www.mplayerhq.hu/design7/info.html) and [MPlayer](http://www.mplayerhq.hu/design7/info.html). It shares some features with the former projects while introducing many more.

**Streamlined CLI options:**
> MPlayer's options parser was improved to behave more like other CLI programs, and many option names and semantics were reworked to make them more intuitive and memorable.

**On Screen Controller:**
> While mpv has no official GUI, it has a small controller that is triggered by mouse movement.

**High quality video output:**
> mpv has an OpenGL based video output that is capable of many features loved by videophiles, such as video scaling with popular high quality algorithms, color management, frame timing, interpolation, HDR, and more.

**GPU video decoding:**
> mpv leverages the FFmpeg hwaccel APIs to support VDPAU, VAAPI, DXVA2, VDA and VideoToolbox video decoding acceleration.

**Embeddable:**
> A straightforward C API was designed from the ground up to make mpv usable as a library and facilitate easy integration into other applications.

**Active development:**
> mpv is under active development, focusing on code refactoring and cleanups as well as adding features. Want a feature?

-------------------------------------------
