require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'RNVideoFeed'
  s.version      = package['version']
  s.summary      = package['description']
  s.homepage     = 'https://github.com/venky145/RN-VideoFeed'
  s.license      = { :type => 'MIT', :file => '../LICENSE' }
  s.author       = package['author']
  s.source       = { :git => 'https://github.com/venky145/RN-VideoFeed.git', :tag => "v#{s.version}" }

  s.platforms    = { :ios => '16.0' }
  s.source_files = 'ios/**/*.{h,m,mm,swift}'
  s.swift_version = '5.0'

  s.dependency 'SDWebImage', '~> 5.19'

  if respond_to?(:install_modules_dependencies, true)
    install_modules_dependencies(s)
  else
    s.dependency 'React-Core'
  end
end
