Pod::Spec.new do |s|

  s.name         = "ISMediaKit"
  s.version      = "0.0.1"
  s.summary      = "Utilities for managing media"
  s.homepage     = "https://github.com/jbmorley/ISMediaKit"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Jason Barrie Morley" => "jason.morley@inseven.co.uk" }
  s.source       = { :git => "https://github.com/jbmorley/ISMediaKit.git", :commit => "3fd72a470679b90584492c7d7cc72a43e6feb313" }

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'ISMediaKit/*.{h,m}'

  s.requires_arc = true

  s.dependency 'iTVDb', "~> 0.0.4"
  s.dependency 'ILMovieDB'

end
