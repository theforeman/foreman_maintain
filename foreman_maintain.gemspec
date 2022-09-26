$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'foreman_maintain/version'

Gem::Specification.new do |s|
  s.name = 'foreman_maintain'
  s.authors = ['Ivan Nečas']
  s.email = 'inecas@redhat.com'
  s.licenses = ['GPL-3.0']
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
  s.executables = ['foreman-maintain', 'passenger-recycler',
                   'foreman-maintain-complete', 'foreman-maintain-rotate-tar']

  s.add_dependency 'clamp'
  s.add_dependency 'highline'

  s.add_development_dependency 'bundler', '>= 1.17'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubocop', '0.50.0' # rubocop >= 0.51.0 drops support for ruby 2.0
  s.add_development_dependency 'minitest-stub-const'
end
