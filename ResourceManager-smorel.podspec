Pod::Spec.new do |s|

  s.name         = "ResourceManager-smorel"
  s.version      = "1.3.0"
  s.summary      = "Synchronize your application resources from dropbox to the app and experience dynamic reload on simulator and devices."
  s.homepage     = "https://github.com/smorel/ResourceManager"
  s.license      = { :type => 'Apache Licence 2.0', :file => 'LICENSE.txt' }
  s.author       = { 'Sebastien Morel' => 'morel.sebastien@gmail.com' }
  s.source       = { :git => 'https://github.com/smorel/ResourceManager.git', :tag => 'v1.3.0' }
  s.platform     = :ios, '7.0'

  s.description = 'ResourceManager allows you to synchronize your resource in the app running on a device or emulator while your editing them on your Mac. Whether it is an image, a sound, a nib, an AppCoreKit stylesheet or layout and even string files, the ResourceManager let your see the changes you''re making in your assets live on your devices. Connect several devices with different form factor or idiom simultaneously with one or several resource managers. This is useful when you''re working in team and want to get your UI up-to-date while other are working on it. Or only connect your Mac with your devices if you don''t trust your colleagues It''s up to you!'


  s.module_name = 'ResourceManager'

  s.default_subspec = 'All'

  s.frameworks =  'Security', 'QuartzCore'

  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '/usr/include/libxml2', 'OTHER_LDFLAGS' => '-ObjC -all_load -weak_library /usr/lib/libstdc++.dylib' } 

  s.dependency 'Dropbox-iOS-SDK'
  s.dependency 'AppPeerIOS-smorel'

  s.requires_arc = false

  s.subspec 'All' do |al|    
    al.source_files = 'ResourceManager/Classes/**/*.{h,m,mm}', 'ResourceManager/Classes/ResourceManager.h'
    al.private_header_files = 'ResourceManager/Classes/Private/**/*.{h}'
  end

end
