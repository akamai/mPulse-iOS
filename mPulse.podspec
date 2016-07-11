Pod::Spec.new do |s|

  s.name           = "mPulse"
  s.version        = "2.0.0"
  s.license        = { :type => 'Apache License, Version 2.0', :file => 'LICENSE'}
  s.summary        = "iOS library for mPulse Analytics"
  s.homepage       = "https://github.com/SOASTA/mPulse-iOS"
  s.social_media_url = 'https://twitter.com/cloudtest'
  s.source         = { :git => "https://github.com/SOASTA/mPulse-iOS.git", :tag => s.version }
  s.author         = { "SOASTA" => "support@soasta.com" }

  s.platform       = :ios
  s.ios.deployment_target = "6.0"

  s.source_files   = 'include/*.h', 'Empty.m'
  s.public_header_files = 'include/*.h'
  s.preserve_paths = 'libMPulse.a', 'libMPulseSim.a'
  s.ios.vendored_library = 'libMPulse.a', 'libMPulseSim.a'
  s.libraries      = 'z', 'c++', 'MPulse', 'MPulseSim'
  s.frameworks     = 'CoreLocation', 'CoreTelephony', 'SystemConfiguration'
  s.requires_arc   = true

end
