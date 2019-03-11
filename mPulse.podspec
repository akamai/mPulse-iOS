Pod::Spec.new do |s|

  s.name           = "mPulse"
  s.version        = "2.6.0"
  s.license        = { :type => 'Apache License, Version 2.0', :file => 'LICENSE'}
  s.summary        = "iOS library for mPulse Analytics"
  s.homepage       = "https://github.com/akamai/mPulse-iOS"
  s.social_media_url = 'https://twitter.com/akamai'
  s.source         = { :git => "https://github.com/akamai/mPulse-iOS.git", :tag => s.version }
  s.author         = { "Akamai" => "support@akamai.com" }
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
