Pod::Spec.new do |s|

  s.name           = "mPulse"
  s.version        = "0.0.7"
  s.license        = { :type => 'Apache License, Version 2.0', :file => 'LICENSE'}
  s.summary        = "iOS library for mPulse Analytics"
  s.homepage       = "https://github.com/SOASTA/mPulse-iOS"
  s.social_media_url = 'https://twitter.com/cloudtest'
  s.source         = { :git => "https://github.com/SOASTA/mPulse-iOS.git", :tag => s.version }
  s.author         = { "SOASTA" => "support@soasta.com" }

  s.platform       = :ios
  s.ios.deployment_target = "6.0"

  s.source_files   = 'include/*.h'
  s.public_header_files = 'include/*.h'
  s.preserve_paths = 'libMPulse.a'
  s.ios.vendored_library = 'libMPulse.a'
  s.libraries      = 'z', 'stdc++', 'MPulse'
  s.frameworks     = 'CoreLocation', 'CoreTelephony', 'SystemConfiguration'
  s.requires_arc   = true

end
