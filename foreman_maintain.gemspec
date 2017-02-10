$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'foreman_maintain/version'

Gem::Specification.new do |s|
  s.name = 'foreman_maintain'
  s.authors = ['Ivan Nečas']
  s.email = 'inecas@redhat.com'
  s.licenses = ['GPL-3']
  s.homepage = 'https://github.com/theforeman/foreman_maintain'
  s.version = ForemanMaintain::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = 'Foreman maintenance tool belt'
  s.description = <<DESC
Provides various features that helps keeping the Foreman/Satellite up and
running.
DESC

  s.files = Dir['{config,lib,definitions}/**/*']
  s.extra_rdoc_files = [
    'LICENSE',
    'README.md'
  ]
  s.require_paths = ['lib']

  s.add_dependency 'clamp'

  s.add_development_dependency 'rubocop'
end
