Pod::Spec.new do |s|
  s.name         = 'UPnAtom'
  s.version      = '0.0.1'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary      = 'A reimplementation of the upnpx library written in Swift.'
  s.homepage     = 'https://github.com/master-nevi/UPnAtom'
  s.authors      = { 'David Robles' => 'master-nevi@users.noreply.github.com' }
  s.source       = { :git => 'git@github.com:master-nevi/UPnAtom.git', :tag => s.version.to_s } # TODO: switch out to https on release
  s.source_files = 'Source/**/*.{swift,h,m}'
  s.private_header_files = 'Source/Obj-C Tools/*.{h,m}'
  s.resources = 'Source/*.modulemap'

  s.xcconfig = { 'SWIFT_INCLUDE_PATHS' => '../../../Source'} # TODO: verify the non dev pod path
  s.requires_arc = true
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.dependency 'upnpx', '~> 1.3.1'
  s.dependency 'AFNetworking', '~> 2.5.0'
  s.dependency 'CocoaHTTPServer', '~> 2.3'
  s.dependency 'Ono', '~> 1.2.0'
end