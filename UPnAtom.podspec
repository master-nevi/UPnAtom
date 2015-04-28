Pod::Spec.new do |s|
  s.name         = 'UPnAtom'
  s.version      = '0.6.0'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary      = 'An open source Universal Plug and Play library with a focus on media streaming coordination using the UPnP A/V profile.'
  s.homepage     = 'https://github.com/master-nevi/UPnAtom'
  s.authors      = { 'David Robles' => 'master-nevi@users.noreply.github.com' }
  s.source       = { :git => 'https://github.com/master-nevi/UPnAtom.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'Source/**/*.swift'
  s.exclude_files = 'Source/CocoaSSDP Support/*.swift'
  s.dependency 'CocoaAsyncSocket', '~> 7.4.1' # UPnP object discovery using SSDP
  s.dependency 'AFNetworking', '~> 2.5.2' # HTTP Client
  s.dependency 'Ono', '~> 1.2.0' # XML parsing
  s.dependency 'GCDWebServer', '~> 3.2.2' # UPnP event notification handling

  
  # NOTE: I really did try to be a good pod architect and modularize the library into subspecs, however there are still bugs in the Swift compiler which cause it to crash when building release/archive versions of UPnAtom. Because the problem areas may consistantly or inconsistanly cause the compiler crash, the fewer subspecs or no subspecs the better when it comes to tracking them down (i.e. less hair being pulled out). I look forward to doing it in the future however. Here's a sneak peek:

  # s.default_subspecs = 'Default'

  # s.subspec 'Default' do |ss|
  #   ss.source_files = 'Source/UPnAtom.swift'
  #   ss.dependency 'UPnAtom/AV Profile'
  # end

  # s.subspec 'UPnP Foundation' do |ss|
  #   ss.source_files = 'Source/UPnP Foundation/*.swift'
  # end

  # s.subspec 'SSDP Explorer' do |ss|
  #   ss.source_files = 'Source/SSDP/Explorer/*.swift'
  #   ss.dependency 'UPnAtom/UPnP Foundation'
  #   ss.dependency 'CocoaAsyncSocket', '~> 7.4.1' # UPnP object discovery using SSDP
  #   ss.dependency 'AFNetworking', '~> 2.5.0' # HTTP Client
  # end  

  # s.subspec 'Core' do |ss|
  #   ss.source_files = 'Source/{HTTP Client Session Managers and Serializers,Logging,Management,Parsers,UPnP Objects}/*.swift', 'Source/SSDP/Discovery Adapter/*.swift'
  #   ss.dependency 'UPnAtom/SSDP Explorer'
  #   ss.dependency 'Ono', '~> 1.2.0' # XML parsing
  #   ss.dependency 'GCDWebServer', '~> 3.2.2' # UPnP event notification handling
  # end

  # s.subspec 'AV Profile' do |ss|
  #   ss.source_files = 'Source/AV Profile/**/*.swift'
  #   ss.dependency 'UPnAtom/Core'
  # end

  # s.subspec 'CocoaSSDP Support' do |ss|
  #   ss.source_files = 'Source/CocoaSSDP Support/*.swift'
  #   ss.dependency 'UPnAtom/Core'
  #   ss.dependency 'CocoaSSDP', '~> 0.1.0'
  # end
end
