UPnAtom
=========

An open source Universal Plug & Play library with a focus on local media streaming coordination; written in Swift but for both Objective-C and Swift apps. Supports only iOS 8 and higher due to iOS 7's limitation of not supporting dynamic libraries via Clang module.

### Install:
Add following to Podfile:
```ruby
pod 'UPnAtom'
```

### Requirements:
* iOS 8.0+
* Xcode 6.1

### Usage:
######  Objective-C
```objective-c
#import <UPnAtom/UPnAtom-Swift.h>
```

###### Swift
```swift
import UPnAtom
```

### Contribute:
Currently I'm only taking feature requests and bug fixes via [Github issue](https://github.com/master-nevi/UPnAtom/issues). Sorry no pull requests until the library is mature enough.

- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.

### Milestones:
* [x] Usable in both Objective-C and Swift projects via CocoaPod framework
* [x] Create your own service and device object via class registration
* [x] Integrate LumberJack for better logging
* [x] UPnP Version 1 Compliance
* [ ] Swift 1.2
* [ ] OS X 10.9+ support
* [ ] Feature parity with upnpx library
* [ ] UPnP Version 2 Compliance
