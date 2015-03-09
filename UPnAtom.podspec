Pod::Spec.new do |s|
  s.name         = 'UPnAtom'
  s.version      = '0.0.1.beta.1'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary      = 'An open source Universal Plug & Play library with a focus on media streaming coordination (UPnP A/V Profile).'
  s.homepage     = 'https://github.com/master-nevi/UPnAtom'
  s.authors      = { 'David Robles' => 'master-nevi@users.noreply.github.com' }
  s.source       = { :git => 'https://github.com/master-nevi/UPnAtom.git', :tag => s.version.to_s }
  s.source_files = 'Source/**/*.{swift,h,m}'
  s.exclude_files = 'Source/SSDP/UPNPXSSDPDiscoveryAdapter.swift' # Available in case upnpx library is used for UPnP discovery using SSDP
  s.private_header_files = 'Source/Obj-C Tools/*.h'
  s.resources = 'Source/*.modulemap'
  s.xcconfig = { 'SWIFT_INCLUDE_PATHS' => '"../../../Source" "UPnAtom/Source"'} # First path is for development using example project, second is for pod in general
  s.requires_arc = true
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.dependency 'CocoaSSDP', '~> 0.1.0'
  s.dependency 'AFNetworking', '~> 2.5.0'
  s.dependency 'CocoaHTTPServer', '~> 2.3'
  s.dependency 'Ono', '~> 1.2.0'
  s.dependency 'CocoaLumberjack', '~> 2.0.0-rc2'
end