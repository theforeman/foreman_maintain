source 'https://rubygems.org'

gemspec

# rubocop:disable  Security/Eval
if File.exist? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), nil, "#{__FILE__}.local")
end
# rubocop:enable  Security/Eval

if RUBY_VERSION <= '1.8.7'
  gem 'json'
end

if RUBY_VERSION >= '2.0'
  gem 'rubocop', '0.50.0'
else
  gem 'clamp', '~> 0.6.2'
  gem 'highline', '~> 1.6.21'
end
