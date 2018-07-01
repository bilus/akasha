# rubocop:disable Style/ExpandPathArguments
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'akasha/version'

Gem::Specification.new do |spec|
  spec.name          = 'akasha'
  # rubocop:disable Gemspec/DuplicatedAssignment
  spec.version       = Akasha::VERSION
  spec.version       = "#{spec.version}-edge-#{ENV['TRAVIS_BUILD_NUMBER']}"
  # rubocop:enable Gemspec/DuplicatedAssignment
  spec.authors       = ['Marcin Bilski']
  spec.email         = ['marcin@tooploox.com']

  spec.summary       = 'CQRS library for Ruby'
  spec.description   = 'A simple CQRS library for Ruby.'
  spec.homepage      = 'https://github.com/bilus/akasha'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'corefines', '~>1.11'
  spec.add_dependency 'faraday', '~> 0.15'
  spec.add_dependency 'faraday_middleware'
  spec.add_dependency 'rack', '~> 2.0'
  spec.add_dependency 'retries', '~> 0.0'
  spec.add_dependency 'typhoeus', '~> 1.3'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'rspec-wait', '~> 0.0.9'
  spec.add_development_dependency 'rubocop', '~> 0.50'
  spec.add_development_dependency 'timecop', '~> 0.9'
end
# rubocop:enable Style/ExpandPathArguments
