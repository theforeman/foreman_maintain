source 'https://rubygems.org'

gemspec

# rubocop:disable  Security/Eval
if File.exist? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), nil, "#{__FILE__}.local")
end
# rubocop:enable  Security/Eval

if RUBY_VERSION >= '2.0'
  gem 'rubocop', '0.50.0'
end
