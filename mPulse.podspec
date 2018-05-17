Pod::Spec.new do |s|

  s.name           = "mPulse"
  s.version        = "2.3.4"
  s.license        = { :type => 'Apache License, Version 2.0', :file => 'LICENSE'}
  s.summary        = "iOS library for mPulse Analytics"
  s.homepage       = "https://github.com/SOASTA/mPulse-iOS"
  s.social_media_url = 'https://twitter.com/soastainc'
  s.source         = { :git => "https://github.com/SOASTA/mPulse-iOS.git", :tag => s.version }
  s.author         = { "SOASTA" => "support@soasta.com" }
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-ObjC' }

  s.platform       = :ios
  s.ios.deployment_target = "6.0"

  s.source_files   = 'include/*.h', 'Empty.m'
  s.public_header_files = 'include/*.h'
  s.preserve_paths = 'libmPulseDevice.a', 'libmPulseSim.a'
  s.ios.vendored_library = 'libmPulseDevice.a', 'libmPulseSim.a'
  s.libraries      = 'z', 'c++', 'mPulseDevice', 'mPulseSim'
  s.frameworks     = 'CoreLocation', 'CoreTelephony', 'SystemConfiguration'
  s.requires_arc   = true

end
