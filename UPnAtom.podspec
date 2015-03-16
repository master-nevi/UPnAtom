Pod::Spec.new do |s|
  s.name         = 'UPnAtom'
  s.version      = '0.0.1.beta.2'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary      = 'An open source Universal Plug and Play library with a focus on media streaming coordination using the UPnP A/V profile.'
  s.homepage     = 'https://github.com/master-nevi/UPnAtom'
  s.authors      = { 'David Robles' => 'master-nevi@users.noreply.github.com' }
  s.source       = { :git => 'https://github.com/master-nevi/UPnAtom.git', :tag => s.version.to_s }
  s.source_files = 'Source/**/*.{swift}'
  s.exclude_files = 'Source/SSDP/UPNPXSSDPDiscoveryAdapter.swift' # Available in case upnpx library is used for UPnP discovery using SSDP
  s.requires_arc = true
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.dependency 'CocoaSSDP', '~> 0.1.0' # UPnP object discovery
  s.dependency 'AFNetworking', '~> 2.5.0' # Network calls over HTTP
  s.dependency 'Ono', '~> 1.2.0' # XML parsing
  s.dependency 'GCDWebServer', '~> 3.2.2' # UPnP event notification handling
end