![UPnAtom: Modern UPnP in Swift](https://raw.githubusercontent.com/master-nevi/UPnAtom/assets/UPnAtomLogo.png)
[![Version](http://img.shields.io/cocoapods/v/UPnAtom.svg)](http://cocoapods.org/?q=UPnAtom)
[![Platform](http://img.shields.io/cocoapods/p/UPnAtom.svg)](https://github.com/master-nevi/UPnAtom/blob/master/UPnAtom.podspec)
[![License](http://img.shields.io/cocoapods/l/UPnAtom.svg)](https://github.com/master-nevi/UPnAtom/blob/master/LICENSE)
[![Build Status](https://img.shields.io/travis/master-nevi/UPnAtom/master.svg)](https://travis-ci.org/master-nevi/UPnAtom)

An open source Universal Plug and Play library with a focus on media streaming coordination using the UPnP A/V profile; written in Swift but for both Objective-C and Swift apps. Supports only iOS 8 and higher due to iOS 7's limitation of not supporting dynamic libraries via Clang module.

### Requirements:
* iOS 8.0+
* OSX 10.9+
* Xcode 7.2

### Install:
Add following to Podfile:
```ruby
pod 'UPnAtom'
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

###### More documentation is on the way.
For now, it is highly recommended you check out the [example projects](https://github.com/master-nevi/UPnAtom/tree/master/Examples). They are exactly the same app however one is in Swift, and the other is in Objective-C. They demonstrate almost all of the library's features minus the ability to add your own UPnP service/device classes. If you create your own service/device classes simply register them following  [UPnAtom.swift](https://github.com/master-nevi/UPnAtom/blob/master/Source/UPnAtom.swift) as an example.

Note: On iOS, transport security has blocked cleartext HTTP (http://) resource loads since it is insecure. Since many, if not most, UPnP devices serve resources over http, temporary exceptions can be configured via your app's Info.plist file. Remove this restriction at your own risk.

### Milestones:
* [x] Usable in both Swift and Objective-C projects via CocoaPod framework
* [x] Create your own service and device object via class registration
* [x] UPnP Version 1 Compliance
* [x] Ability to archive UPnP objects after initial discovery and persist somewhere via NSCoder/NSCoding
* [x] OSX 10.9+ support
* [ ] Swift 2.0
* [x] In-house implementation of SSDP discovery
* [x] A/V Profile Feature parity with upnpx library
* [ ] Documentation (Until then please check out the [example projects](https://github.com/master-nevi/UPnAtom/tree/master/Examples))
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
