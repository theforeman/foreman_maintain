$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'foreman_maintain/version'

Gem::Specification.new do |s|
  s.name = 'foreman_maintain'
  s.authors = ['Ivan Nečas']
  s.email = 'inecas@redhat.com'
  s.licenses = ['GPL-3.0-only']
  s.homepage = 'https://github.com/theforeman/foreman_maintain'
  s.version = ForemanMaintain::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = 'Foreman maintenance tool belt'
  s.description = "Provides various features that helps keeping \
the Foreman/Satellite up and running."

  s.files = Dir['{bin,lib,definitions}/**/*']
  s.files += `git ls-files config`.split("\n")
  s.files += `git ls-files extras`.split("\n")
  s.extra_rdoc_files = ['LICENSE', 'README.md']
  s.require_paths = ['lib']
  s.executables = ['foreman-maintain', 'foreman-maintain-complete']
  s.required_ruby_version = ">= 2.7", "< 4"

  s.add_dependency 'clamp', '~> 1.0'
  s.add_dependency 'highline', '>= 2.0', '< 4'

  s.add_development_dependency 'bundler', '>= 1.17', '< 5'
  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'minitest-reporters', '~> 1.0'
  s.add_development_dependency 'minitest-stub-const', '~> 0.6'
  s.add_development_dependency 'mocha', '~> 3.0'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'theforeman-rubocop', '~> 0.1'
end
