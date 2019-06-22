# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fusuma/version'

Gem::Specification.new do |spec|
  spec.name          = 'fusuma'
  spec.version       = Fusuma::VERSION
  spec.authors       = ['iberianpig']
  spec.email         = ['yhkyky@gmail.com']

  spec.summary       = 'Multitouch gestures with libinput dirver on X11, Linux'
  spec.description   = 'Fusuma is multitouch gesture recognizer. This gem makes your touchpad on Linux able to recognize swipes or pinchs and assign command to them. Read installation on Github(https://github.com/iberianpig/fusuma#installation).'
  spec.homepage      = 'https://github.com/iberianpig/fusuma'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'github_changelog_generator', '~> 1.14'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug', '~> 3.4'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'pry-inline'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'reek'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
end
