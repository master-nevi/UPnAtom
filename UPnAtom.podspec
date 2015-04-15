Pod::Spec.new do |s|
  s.name         = 'UPnAtom'
  s.version      = '0.0.1.beta.4'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary      = 'An open source Universal Plug and Play library with a focus on media streaming coordination using the UPnP A/V profile.'
  s.homepage     = 'https://github.com/master-nevi/UPnAtom'
  s.authors      = { 'David Robles' => 'master-nevi@users.noreply.github.com' }
  s.source       = { :git => 'https://github.com/master-nevi/UPnAtom.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  
  s.default_subspecs = 'Default'

  s.subspec 'Default' do |ss|
    ss.source_files = 'Source/UPnAtom.swift'
    ss.dependency 'UPnAtom/Core'
    ss.dependency 'UPnAtom/AV Profile'
  end

  s.subspec 'SSDP Explorer' do |ss|
    ss.source_files = 'Source/SSDP/Explorer/*.swift'
    ss.dependency 'CocoaAsyncSocket', '~> 7.4.1' # UPnP object discovery using SSDP
  end  

  s.subspec 'Core' do |ss|
    ss.source_files = 'Source/GlobalLib.swift', 'Source/{HTTP Client Session Managers and Serializers,Logging,Management,Parsers,UPnP Objects}/*.swift', 'Source/SSDP/Discovery Adapter/*.swift'
    ss.dependency 'UPnAtom/SSDP Explorer'
    ss.dependency 'AFNetworking', '~> 2.5.0' # Network calls over HTTP
    ss.dependency 'Ono', '~> 1.2.0' # XML parsing
    ss.dependency 'GCDWebServer', '~> 3.2.2' # UPnP event notification handling
  end

  s.subspec 'AV Profile' do |ss|
    ss.source_files = 'Source/AV Profile/**/*.swift'
    ss.dependency 'UPnAtom/Core'
  end

  s.subspec 'CocoaSSDP Support' do |ss|
    ss.source_files = 'Source/CocoaSSDP Support/*.swift'
    ss.dependency 'UPnAtom/Core'
    ss.dependency 'CocoaSSDP', '~> 0.1.0'
  end
end