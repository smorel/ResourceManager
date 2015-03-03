Pod::Spec.new do |s|

  s.name         = "ResourceManager-smorel"
  s.version      = "1.2.0"
  s.summary      = "Synchronize your application resources from dropbox to the app and experience dynamic reload on simulator and devices."
  s.homepage     = "https://github.com/smorel/ResourceManager"
  s.license      = { :type => 'Apache Licence 2.0', :file => 'LICENSE.txt' }
  s.author       = { 'Sebastien Morel' => 'morel.sebastien@gmail.com' }
  s.source       = { :git => 'https://github.com/smorel/ResourceManager.git', :tag => 'v1.2.0' }
  s.platform     = :ios, '7.0'

  s.description = 'Are you tired of waiting for your app to compile and sync to your device when you just want to update an image or some text? Wouldn’t it be wonderful if you could distribute your application over the air and the copywriter could edit the localization files directly? Imagine if you could give your app to a designer who could tweak the layouts, fonts, margins and colours, without needing an Xcode installation or any knowledge of Objective-C? With the ResourceManager framework, combined with AppCoreKit and a few lines of code, all this is possible.'


  s.default_subspec = 'All'

  s.frameworks =  'Security', 'QuartzCore'

  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '/usr/include/libxml2', 'OTHER_LDFLAGS' => '-ObjC -all_load -weak_library /usr/lib/libstdc++.dylib' } 

  s.dependency 'Dropbox-iOS-SDK'
  
  s.requires_arc = false

  s.subspec 'All' do |al|    
    al.source_files = 'ResourceManager/Classes/**/*.{h,m,mm}', 'ResourceManager/Classes/ResourceManager.h'
    al.private_header_files = 'ResourceManager/Classes/Private/**/*.{h}'
  end

end
