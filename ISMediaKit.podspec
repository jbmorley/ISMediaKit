Pod::Spec.new do |s|

  s.name         = "ISMediaKit"
  s.version      = "1.0.0"
  s.summary      = "Utilities for managing media"
  s.homepage     = "https://github.com/jbmorley/ISMediaKit"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Jason Barrie Morley" => "jason.morley@inseven.co.uk" }
  s.source       = { :git => "https://github.com/jbmorley/ISMediaKit.git", :tag => "1.0.0" }

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'ISMediaKit/*.{h,m}'

  s.requires_arc = true

  s.dependency 'iTVDb', "~> 0.0.5"
  s.dependency 'ILMovieDB', "~> 0.0.2"
  s.dependency 'ISUtilities', "~> 1.1"

end
