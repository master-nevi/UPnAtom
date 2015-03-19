![UPnAtom: Modern UPnP in Swift](https://raw.githubusercontent.com/master-nevi/UPnAtom/assets/UPnAtomLogo.png)

An open source Universal Plug and Play library with a focus on media streaming coordination using the UPnP A/V profile; written in Swift but for both Objective-C and Swift apps. Supports only iOS 8 and higher due to iOS 7's limitation of not supporting dynamic libraries via Clang module.

### Requirements:
* iOS 8.0+
* Xcode 6.1

### Install:
Add following to Podfile:
```ruby
pod 'UPnAtom', '~> 0.0.1.beta.3'
```

### Usage:
######  Objective-C
```objective-c
@import UPnAtom;
```

###### Swift
```swift
import UPnAtom
```

### Milestones:
* [x] Usable in both Swift and Objective-C projects via CocoaPod framework
* [x] Create your own service and device object via class registration
* [x] UPnP Version 1 Compliance
* [x] Ability to archive UPnP objects after initial discovery and persist somewhere via NSCoder/NSCoding
* [ ] Swift 1.2
* [ ] In-house implementation of SSDP discovery
* [ ] OS X 10.9+ support
* [ ] Feature parity with upnpx library
* [ ] UPnP Version 2 Compliance

### Tested Support On:
###### UPnP Servers:
* [Kodi](http://kodi.tv/) - Open Source Home Theatre Software (aka XBMC) - [How to enable](http://kodi.wiki/view/UPnP/Server)
* [Universal Media Server](http://www.universalmediaserver.com/) (fork of PS3 Media Server)

###### UPnP Clients:
* [Kodi](http://kodi.tv/) - Open Source Home Theatre Software (aka XBMC) - [How to enable](http://kodi.wiki/view/UPnP/Client)
* [Sony Bravia TV's with DLNA support](http://esupport.sony.com/p/support-info.pl?info_id=884&template_id=1&region_id=8)

### Contribute:
Currently I'm only taking feature requests, bugs, and bug fixes via [Github issue](https://github.com/master-nevi/UPnAtom/issues). Sorry no pull requests for features or major changes until the library is mature enough.

- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
