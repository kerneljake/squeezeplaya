# squeezeplaya

macOS fork of Squeezeplay

## Description

This fork of Squeezeplay is focused on bug fixes and usability enhancements for the macOS build.

The three primary areas of focus are:
1. multi-media key support :heavy_check_mark:
2. cooperative device management with other programs like VLC
3. proper handling of high VBR FLAC files

It's really a laboratory for me to learn Core Audio, PortAudio, and Objective-C.

I'm happy to fold this back upstream when it is sufficiently stable.

## TODO

- [x] clean compilation on x86\_64 and M1 with arbitrary SDK versions
- [x] version number from git instead of svn in About as well as Settings -> Advanced -> About
- [x] ⌘-H and ⌘-Q hide and quit, respectively
- [x] multi-media key support (next/prev/pause/stop) in conjunction with [noTunes](https://github.com/tombonez/noTunes)
- [ ] tray icon menu items for controlling playback
- [ ] double click NowPlaying applet to rotate skin instead of single click
- [ ] move volume slider quickly by clicking in the grey empty space area
- [ ] handle runtime changes in default output device like unplugging headphone jack, changing Sound Output, etc.
- [ ] don't clobber VLC's output device on startup
- [ ] handle high VBR FLAC files

## Compiling

1. Install XCode command line tools, if not already installed: `xcode-select --install`
1. Copy (or symlink) either Makefile.osx-x86\_64 or Makefile.osx-M1 to a file called `Makefile`, depending on your architecture.
   This is really for convenience; that way, you don't have to keep passing the `-f` flag to `make` every time.
1. Perform the steps listed at the top of the Makefile entitled, "user specific stuff", like cloning and patching portaudio\_v19.
1. Build with `make`.
