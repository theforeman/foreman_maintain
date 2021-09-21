source 'https://rubygems.org'

gemspec

# rubocop:disable  Security/Eval
if File.exist? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), nil, "#{__FILE__}.local")
end
# rubocop:enable  Security/Eval

if RUBY_VERSION >= '3.0'
  gem 'rexml' # rexml was a default gem in ruby < 3.0, and is a bundled gem in >= 3.0
end
