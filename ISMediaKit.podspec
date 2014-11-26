Pod::Spec.new do |s|

  s.name         = "ISMediaKit"
  s.version      = "0.0.1"
  s.summary      = "Utilities for managing media"
  s.homepage     = "https://github.com/jbmorley/ISMediaKit"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Jason Barrie Morley" => "jason.morley@inseven.co.uk" }
  s.source       = { :git => "https://github.com/jbmorley/ISMediaKit.git", :tag => "0.0.1" }

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'ISMediaKit/*.{h,m}'

  s.requires_arc = true

  s.dependency 'iTVDb', "~> 0.0.4"
  s.dependency 'ILMovieDB'
  s.dependency 'ISUtilities', "~> 1.1"

end
