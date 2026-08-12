-----------------------------------
# mpv.snad for [Windows](https://github.com/thisisshihan/mpv.snad) / Linux / Mac
_[mpv](https://mpv.io/) a free, open source, and cross-platform media player._

![https://mpv.io/](https://github.com/thisisshihan/screenshots/blob/master/mpv.icon256.png)

## About mpv.snad:
_(This repository contain optimized configs for mpv player focused on fast, efficient & minimalist look. No bs scripts which will reduce speed of loading/opening a file.)_

#### Download Latest Windows Version:
* Download the latest version from sourceforge.net [mpv.snad](https://sourceforge.net/projects/mpv-snad/files/) (this file contain all the config files) 
* _(AMD FSR and NVIDIA Image Scaling added (CTRL+A/N/Z) added to v35.1 +)_

#### How to install:
* Extract the files.
* Move the folder to required destination.
* Go to **_`.../installer`_** folder
* Run **_`mpv-install.bat`_** as admin

#### Other Downloads
* Windows / ubuntu / linux / macos / Android stable cahnnel official: [mpv.io](http://mpv.io/installation)
* Windows beta channel official: [sourceforge.net](https://sourceforge.net/projects/mpv-player-windows/files)
* Android stable official: [play.google.com](https://play.google.com/store/apps/details?id=is.xyz.mpv&hl=en)
* Android test builds official: [github.com](https://github.com/mpv-android/mpv-android/releases)
* Config files by snad for Windows / ubuntu / linux / macos: [mpv.snad](https://goo.gl/7Mphpk)

#### Config For Windows (not required if you download the player from this repository):
* Download [_All Settings From Here_](https://goo.gl/7Mphpk) and extract them to a folder.
* copy / overwrite extracted files to **_`...AppData\Roaming\mpv`_** <br/>_or_
* create a folder as **_`portable_config`_** in the folder where mpv.exe exist and,
* copy extracted files to **_`...portable_config`_**

#### Config For Linux:
* Download [_All Settings From Here_](https://goo.gl/7Mphpk) and extract them to a folder.
* copy / overwrite extracted files to **_`...etc/mpv`_** _(you need root access to this folder)_

#### **Basic key guide -->** [<kbd>key-guide</kbd>](https://github.com/thisisshihan/mpv-player-config-snad/blob/mpv-config-snad-windows-ubuntu-linux-macos/KEY_basic.md)
#### **A Complete key guide -->** [<kbd>key-guide</kbd>](https://github.com/thisisshihan/mpv-player-config-snad/blob/mpv-config-snad-windows-ubuntu-linux-macos/KEY.md)
-------------------------------------
**Simple Interface**<br/>
<kbd>![s2](https://github.com/thisisshihan/screenshots/blob/master/mpv.interface2.png)</kbd>
##
**Touchpad Gesture**<br/>
![s2](https://github.com/thisisshihan/screenshots/blob/master/touchpadGesture2.png)
##
**Advanced Playlist Manager**<br/>
_Navigate_ <kbd> UP </kbd> / <kbd>DOWN</kbd> / <kbd>    SPACE    </kbd> / <kbd> < </kbd> / <kbd> > </kbd> <br/>_A Complete key guide -->_ [<kbd>key-guide</kbd>](https://github.com/thisisshihan/mpv-player-config-snad/blob/mpv-config-snad-windows-ubuntu-linux-macos/KEY.md)<br/>
<kbd>![s1](https://github.com/thisisshihan/screenshots/blob/master/mpv.playlist.png)</kbd>
##
**Podcast RSS Feed Support**<br/>
_Podcast Menu_ <kbd> ALT </kbd> + <kbd>P</kbd>
<kbd>![s2](https://github.com/thisisshihan/screenshots/blob/master/Podcast.png)</kbd>
<details>
<summary>Sample format of podcast feed (.pcst/.snad) file</summary>
One RSS feed URL per line. Lines starting with > # are ignored.
Drag the feed.pcst file onto the mpv window (or open the feed.pcst file with mpv.exe)
Feed file could be just link or with options

> filter: full

> exclude: promo, ad break

> remove-duplicates: yes

> start: 3:00

> https://snad.fm/shows/snad-on-demand/playlists/podcast
</details>

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
