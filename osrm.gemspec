require_relative 'lib/osrm/version'

Gem::Specification.new do |s|
  s.name        = 'osrm'
  s.version     = OSRM::VERSION
  s.summary     = 'OSRM API for Ruby'
  s.description = 'Ruby API to request Open Source Routing Machine servers'

  s.license     = 'MIT'
  s.author      = 'Freayd'
  s.homepage    = 'https://github.com/freayd/osrm'

  s.files       = Dir['README.md', 'LICENSE', 'CHANGELOG.md' 'lib/**/*']

  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.3.0'

  s.add_development_dependency 'bundler',       '~> 1', '>= 1.7.0'
  s.add_development_dependency 'minitest',      '~> 5'
  s.add_development_dependency 'rake',         '~> 11', '>= 11.2.2'
  s.add_runtime_dependency 'encoded_polyline',  '~> 0', '>= 0.0.2'
end
