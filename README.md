UPnAtom
=========

An open source Universal Plug & Play library with a focus on local media streaming coordination; written in Swift but for both Objective-C and Swift apps. Supports only iOS 8 and higher due to iOS 7's limitation of not supporting dynamic libraries via Clang module.

#### Install:
Add following to Podfile (Currently not submitted to public PodSpec repo however if there's a demand I could):
```ruby
pod 'UPnAtom'
```

#### Usage:
######  Objective-C
```objective-c
#import <UPnAtom/UPnAtom-Swift.h>
```

###### Swift
```swift
import UPnAtom
```

#### Contribute:
Currently I'm only taking feature requests and bug fixes via [Github issue](https://github.com/master-nevi/UPnAtom/issues). Sorry no pull requests until the library is mature enough.

#### Milestones:
* Swift 1.2
* 3rd Party UPnP service & object class registration
* Integrate LumberJack for better logging
