Pod::Spec.new do |s|
  s.name         = 'UPnAtom'
  s.version      = '0.0.1.beta.4'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary      = 'An open source Universal Plug and Play library with a focus on media streaming coordination using the UPnP A/V profile.'
  s.homepage     = 'https://github.com/master-nevi/UPnAtom'
  s.authors      = { 'David Robles' => 'master-nevi@users.noreply.github.com' }
  s.source       = { :git => 'https://github.com/master-nevi/UPnAtom.git', :tag => s.version.to_s }
  s.source_files = 'Source/**/*.{swift}'
  s.requires_arc = true
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.dependency 'CocoaAsyncSocket', '~> 7.4.1' # UPnP object discovery using SSDP
  s.dependency 'AFNetworking', '~> 2.5.0' # Network calls over HTTP
  s.dependency 'Ono', '~> 1.2.0' # XML parsing
  s.dependency 'GCDWebServer', '~> 3.2.2' # UPnP event notification handling
end